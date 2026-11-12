//! As notas de voz (docs/PLANO.md, 6.6): gravar do microfone, codificar em Opus num
//! Ogg (o formato que qualquer tocador abre) e tocar. A nota vai como um arquivo
//! qualquer, com o tipo `audio/ogg; codecs=opus`, e passa pelas mesmas fatias
//! cifradas: o áudio nunca fica em claro no disco, só na memória enquanto toca.
//!
//! O som do sistema é pelo `cpal` (ALSA no Linux, WASAPI no Windows, Core Audio no
//! macOS e no iOS, AAudio no Android), sempre no aparelho padrão. Gravar e tocar
//! rodam cada um na própria thread, que é dona do fluxo de áudio.

use std::io::Cursor;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::mpsc;
use std::sync::{Arc, Mutex};
use std::thread::JoinHandle;
use std::time::Duration;

use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use ogg::writing::PacketWriteEndInfo;

use crate::error::{CoreError, CoreResult};

/// O tipo de uma nota de voz, na oferta do arquivo.
pub const VOICE_MIME: &str = "audio/ogg; codecs=opus";
/// O Opus trabalha em 48 kHz; a nota é mono.
pub const RATE: u32 = 48_000;
/// 20 ms por pacote.
const FRAME: usize = 960;
const BITRATE: i32 = 24_000;
/// A nota mais longa, e a mais curta que vale mandar.
pub const MAX_MS: u64 = 5 * 60 * 1000;
pub const MIN_MS: u64 = 500;
const MAX_SAMPLES: usize = (MAX_MS as usize / 1000 + 1) * RATE as usize;

/// Codifica o áudio (mono, 48 kHz) num Ogg Opus.
pub fn encode(pcm: &[i16]) -> CoreResult<Vec<u8>> {
    let mut encoder = opus::Encoder::new(RATE, opus::Channels::Mono, opus::Application::Voip)
        .map_err(|_| CoreError::NoAudio)?;
    encoder
        .set_bitrate(opus::Bitrate::Bits(BITRATE))
        .map_err(|_| CoreError::NoAudio)?;
    let pre_skip = encoder.get_lookahead().map_err(|_| CoreError::NoAudio)? as u16;

    let mut out = Vec::new();
    {
        let mut writer = ogg::PacketWriter::new(Cursor::new(&mut out));
        let serial = 0x4348_5250; // "CHRP"
        let mut head = Vec::with_capacity(19);
        head.extend_from_slice(b"OpusHead");
        head.push(1);
        head.push(1);
        head.extend_from_slice(&pre_skip.to_le_bytes());
        head.extend_from_slice(&RATE.to_le_bytes());
        head.extend_from_slice(&0i16.to_le_bytes());
        head.push(0);
        writer
            .write_packet(head, serial, PacketWriteEndInfo::EndPage, 0)
            .map_err(|_| CoreError::Storage)?;
        let mut tags = Vec::new();
        tags.extend_from_slice(b"OpusTags");
        let vendor = b"Psito Chirp";
        tags.extend_from_slice(&(vendor.len() as u32).to_le_bytes());
        tags.extend_from_slice(vendor);
        tags.extend_from_slice(&0u32.to_le_bytes());
        writer
            .write_packet(tags, serial, PacketWriteEndInfo::EndPage, 0)
            .map_err(|_| CoreError::Storage)?;

        // O codificador atrasa o som em `pre_skip` amostras: os quadros cobrem isso
        // também, para o fim do que foi gravado sair inteiro.
        let frames = (pcm.len() + pre_skip as usize).div_ceil(FRAME).max(1);
        let mut buffer = [0u8; 4000];
        for index in 0..frames {
            let start = index * FRAME;
            let mut frame = [0i16; FRAME];
            let end = (start + FRAME).min(pcm.len());
            if start < end {
                frame[..end - start].copy_from_slice(&pcm[start..end]);
            }
            let len = encoder
                .encode(&frame, &mut buffer)
                .map_err(|_| CoreError::NoAudio)?;
            let last = index + 1 == frames;
            // A posição é a do fim do pacote, contando o pre-skip; no último, só o
            // que foi gravado (o resto do quadro é silêncio de enchimento).
            let granule = pre_skip as u64
                + if last {
                    pcm.len() as u64
                } else {
                    ((index + 1) * FRAME) as u64
                };
            writer
                .write_packet(
                    buffer[..len].to_vec(),
                    serial,
                    if last {
                        PacketWriteEndInfo::EndStream
                    } else {
                        PacketWriteEndInfo::NormalPacket
                    },
                    granule,
                )
                .map_err(|_| CoreError::Storage)?;
        }
    }
    Ok(out)
}

/// O cabeçalho de um Ogg Opus: os canais e o pre-skip.
fn read_head(packet: &[u8]) -> CoreResult<(opus::Channels, usize)> {
    if packet.len() < 19 || &packet[..8] != b"OpusHead" || packet[8] != 1 {
        return Err(CoreError::InvalidFile);
    }
    let channels = match packet[9] {
        1 => opus::Channels::Mono,
        2 => opus::Channels::Stereo,
        _ => return Err(CoreError::InvalidFile),
    };
    Ok((
        channels,
        u16::from_le_bytes([packet[10], packet[11]]) as usize,
    ))
}

/// Decodifica um Ogg Opus para mono, 48 kHz. Recusa o que passa do tamanho de uma
/// nota, para um arquivo estranho não tomar a memória.
pub fn decode(bytes: &[u8]) -> CoreResult<Vec<i16>> {
    let mut reader = ogg::PacketReader::new(Cursor::new(bytes));
    let head = reader
        .read_packet()
        .map_err(|_| CoreError::InvalidFile)?
        .ok_or(CoreError::InvalidFile)?;
    let (channels, pre_skip) = read_head(&head.data)?;
    let stereo = channels == opus::Channels::Stereo;
    let mut decoder = opus::Decoder::new(RATE, channels).map_err(|_| CoreError::InvalidFile)?;
    // As tags.
    reader
        .read_packet()
        .map_err(|_| CoreError::InvalidFile)?
        .ok_or(CoreError::InvalidFile)?;
    let mut pcm = Vec::new();
    let mut end = None;
    let mut buffer = vec![0i16; 5760 * 2];
    while let Some(packet) = reader.read_packet().map_err(|_| CoreError::InvalidFile)? {
        let samples = decoder
            .decode(&packet.data, &mut buffer, false)
            .map_err(|_| CoreError::InvalidFile)?;
        if stereo {
            pcm.extend(
                buffer[..samples * 2]
                    .as_chunks::<2>()
                    .0
                    .iter()
                    .map(|[l, r]| ((*l as i32 + *r as i32) / 2) as i16),
            );
        } else {
            pcm.extend_from_slice(&buffer[..samples]);
        }
        if pcm.len() > MAX_SAMPLES + pre_skip {
            return Err(CoreError::InvalidFile);
        }
        if packet.last_in_stream() {
            end = Some(packet.absgp_page() as usize);
            break;
        }
    }
    let end = end.unwrap_or(pcm.len()).min(pcm.len());
    let start = pre_skip.min(end);
    Ok(pcm[start..end].to_vec())
}

/// Quanto dura, em milissegundos, pelo fim do último pacote (sem decodificar).
pub fn duration_ms(bytes: &[u8]) -> CoreResult<u64> {
    let mut reader = ogg::PacketReader::new(Cursor::new(bytes));
    let head = reader
        .read_packet()
        .map_err(|_| CoreError::InvalidFile)?
        .ok_or(CoreError::InvalidFile)?;
    let (_, pre_skip) = read_head(&head.data)?;
    let mut last = 0u64;
    while let Some(packet) = reader.read_packet().map_err(|_| CoreError::InvalidFile)? {
        last = packet.absgp_page();
    }
    Ok(last.saturating_sub(pre_skip as u64) * 1000 / RATE as u64)
}

/// Muda a taxa por interpolação linear: basta para voz.
pub fn resample(input: &[f32], from: u32, to: u32) -> Vec<f32> {
    if from == to || input.is_empty() {
        return input.to_vec();
    }
    let len = (input.len() as u64 * to as u64 / from as u64) as usize;
    let step = from as f64 / to as f64;
    (0..len)
        .map(|i| {
            let pos = i as f64 * step;
            let index = pos as usize;
            let frac = (pos - index as f64) as f32;
            let a = input[index.min(input.len() - 1)];
            let b = input[(index + 1).min(input.len() - 1)];
            a + (b - a) * frac
        })
        .collect()
}

fn to_i16(sample: f32) -> i16 {
    (sample.clamp(-1.0, 1.0) * i16::MAX as f32) as i16
}

/// Uma gravação em andamento. Parar devolve o áudio (mono, 48 kHz).
pub struct Recording {
    stop: mpsc::Sender<()>,
    thread: Option<JoinHandle<CoreResult<Vec<i16>>>>,
}

impl Recording {
    /// Liga o microfone padrão.
    pub fn start() -> CoreResult<Recording> {
        let (stop, stopped) = mpsc::channel::<()>();
        let (ready, started) = mpsc::sync_channel::<CoreResult<()>>(1);
        let thread = std::thread::spawn(move || -> CoreResult<Vec<i16>> {
            let samples = Arc::new(Mutex::new(Vec::<f32>::new()));
            let failed = Arc::new(AtomicBool::new(false));
            let opened = (|| -> CoreResult<(cpal::Stream, u32)> {
                let device = cpal::default_host()
                    .default_input_device()
                    .ok_or(CoreError::NoAudio)?;
                let config = device
                    .default_input_config()
                    .map_err(|_| CoreError::NoAudio)?;
                let rate = config.sample_rate();
                let channels = config.channels().max(1) as usize;
                let limit = (MAX_MS as usize / 1000 + 1) * rate as usize;
                let stream_config = config.config();
                let on_error = {
                    let failed = failed.clone();
                    move |_| failed.store(true, Ordering::Relaxed)
                };
                macro_rules! input {
                    ($t:ty, $to_f32:expr) => {{
                        let samples = samples.clone();
                        device.build_input_stream::<$t, _, _>(
                            stream_config,
                            move |data: &[$t], _| {
                                let Ok(mut out) = samples.lock() else { return };
                                for frame in data.chunks(channels) {
                                    if out.len() >= limit {
                                        return;
                                    }
                                    let sum: f32 = frame.iter().map(|s| $to_f32(*s)).sum();
                                    out.push(sum / frame.len() as f32);
                                }
                            },
                            on_error,
                            None,
                        )
                    }};
                }
                let stream = match config.sample_format() {
                    cpal::SampleFormat::F32 => input!(f32, |s: f32| s),
                    cpal::SampleFormat::I16 => input!(i16, |s: i16| s as f32 / 32768.0),
                    cpal::SampleFormat::I32 => input!(i32, |s: i32| s as f32 / 2_147_483_648.0),
                    cpal::SampleFormat::U16 => {
                        input!(u16, |s: u16| (s as f32 - 32768.0) / 32768.0)
                    }
                    _ => return Err(CoreError::NoAudio),
                }
                .map_err(|_| CoreError::NoAudio)?;
                stream.play().map_err(|_| CoreError::NoAudio)?;
                Ok((stream, rate))
            })();
            let (stream, rate) = match opened {
                Ok(opened) => {
                    let _ = ready.send(Ok(()));
                    opened
                }
                Err(error) => {
                    let _ = ready.send(Err(error));
                    return Err(error);
                }
            };
            // Para quando pedirem, ou no tempo máximo.
            let _ = stopped.recv_timeout(Duration::from_millis(MAX_MS));
            drop(stream);
            if failed.load(Ordering::Relaxed) {
                return Err(CoreError::NoAudio);
            }
            let samples = std::mem::take(&mut *samples.lock().map_err(|_| CoreError::NoAudio)?);
            Ok(resample(&samples, rate, RATE)
                .into_iter()
                .map(to_i16)
                .collect())
        });
        started.recv().map_err(|_| CoreError::NoAudio)??;
        Ok(Recording {
            stop,
            thread: Some(thread),
        })
    }

    pub fn finish(mut self) -> CoreResult<Vec<i16>> {
        let _ = self.stop.send(());
        self.thread
            .take()
            .ok_or(CoreError::NoAudio)?
            .join()
            .map_err(|_| CoreError::NoAudio)?
    }
}

impl Drop for Recording {
    fn drop(&mut self) {
        let _ = self.stop.send(());
    }
}

/// Uma nota tocando. Soltar (ou `stop`) para o som.
pub struct Playing {
    stop: mpsc::Sender<()>,
}

impl Playing {
    /// Toca no alto-falante padrão. `progress` recebe a posição e se acabou, a cada
    /// décimo de segundo e no fim.
    pub fn start(
        pcm: Vec<i16>,
        progress: impl Fn(u64, bool) + Send + 'static,
    ) -> CoreResult<Playing> {
        let (stop, stopped) = mpsc::channel::<()>();
        let (ready, started) = mpsc::sync_channel::<CoreResult<()>>(1);
        std::thread::spawn(move || {
            let position = Arc::new(AtomicUsize::new(0));
            let opened = (|| -> CoreResult<(cpal::Stream, u32, usize)> {
                let device = cpal::default_host()
                    .default_output_device()
                    .ok_or(CoreError::NoAudio)?;
                let config = device
                    .default_output_config()
                    .map_err(|_| CoreError::NoAudio)?;
                let rate = config.sample_rate();
                let channels = config.channels().max(1) as usize;
                let samples: Arc<Vec<f32>> = Arc::new(resample(
                    &pcm.iter().map(|s| *s as f32 / 32768.0).collect::<Vec<_>>(),
                    RATE,
                    rate,
                ));
                let total = samples.len();
                let stream_config = config.config();
                macro_rules! output {
                    ($t:ty, $from_f32:expr) => {{
                        let samples = samples.clone();
                        let position = position.clone();
                        device.build_output_stream::<$t, _, _>(
                            stream_config,
                            move |data: &mut [$t], _| {
                                let mut at = position.load(Ordering::Relaxed);
                                for frame in data.chunks_mut(channels) {
                                    let value = samples.get(at).copied().unwrap_or(0.0);
                                    at += 1;
                                    for out in frame.iter_mut() {
                                        *out = $from_f32(value);
                                    }
                                }
                                position.store(at.min(samples.len()), Ordering::Relaxed);
                            },
                            |_| {},
                            None,
                        )
                    }};
                }
                let stream = match config.sample_format() {
                    cpal::SampleFormat::F32 => output!(f32, |v: f32| v),
                    cpal::SampleFormat::I16 => output!(i16, to_i16),
                    cpal::SampleFormat::I32 => {
                        output!(i32, |v: f32| (v.clamp(-1.0, 1.0) * i32::MAX as f32) as i32)
                    }
                    cpal::SampleFormat::U16 => {
                        output!(u16, |v: f32| (v.clamp(-1.0, 1.0) * 32767.0 + 32768.0)
                            as u16)
                    }
                    _ => return Err(CoreError::NoAudio),
                }
                .map_err(|_| CoreError::NoAudio)?;
                stream.play().map_err(|_| CoreError::NoAudio)?;
                Ok((stream, rate, total))
            })();
            let (stream, rate, total) = match opened {
                Ok(opened) => {
                    let _ = ready.send(Ok(()));
                    opened
                }
                Err(error) => {
                    let _ = ready.send(Err(error));
                    return;
                }
            };
            let ms = |at: usize| at as u64 * 1000 / rate as u64;
            loop {
                let at = position.load(Ordering::Relaxed);
                if at >= total {
                    // O que ainda está no buffer do sistema sai antes de parar.
                    std::thread::sleep(Duration::from_millis(150));
                    break;
                }
                progress(ms(at), false);
                match stopped.recv_timeout(Duration::from_millis(100)) {
                    Err(mpsc::RecvTimeoutError::Timeout) => {}
                    // Pediram para parar, ou quem tocava se foi.
                    _ => {
                        drop(stream);
                        progress(ms(position.load(Ordering::Relaxed)), true);
                        return;
                    }
                }
            }
            drop(stream);
            progress(ms(total), true);
        });
        started.recv().map_err(|_| CoreError::NoAudio)??;
        Ok(Playing { stop })
    }

    pub fn stop(&self) {
        let _ = self.stop.send(());
    }
}

impl Drop for Playing {
    fn drop(&mut self) {
        self.stop();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Um tom de 440 Hz, que o Opus guarda bem.
    fn tone(ms: usize) -> Vec<i16> {
        (0..ms * RATE as usize / 1000)
            .map(|i| {
                let t = i as f32 / RATE as f32;
                (f32::sin(t * 440.0 * std::f32::consts::TAU) * 12_000.0) as i16
            })
            .collect()
    }

    #[test]
    fn encoding_and_decoding_keep_the_length_and_the_sound() {
        for ms in [20, 1000, 1234] {
            let pcm = tone(ms);
            let ogg = encode(&pcm).unwrap();
            assert_eq!(&ogg[..4], b"OggS");
            assert_eq!(duration_ms(&ogg).unwrap(), ms as u64);
            let back = decode(&ogg).unwrap();
            assert_eq!(back.len(), pcm.len());
            // O codec perde detalhe, mas a energia do tom fica parecida.
            let energy = |p: &[i16]| p.iter().map(|s| (*s as f64).powi(2)).sum::<f64>();
            let ratio = energy(&back) / energy(&pcm);
            assert!((0.5..2.0).contains(&ratio), "{ms} ms: {ratio}");
        }
    }

    #[test]
    fn a_minute_is_small() {
        let ogg = encode(&tone(60_000)).unwrap();
        // 24 kbit/s: uns 180 KB por minuto.
        assert!(ogg.len() < 250_000, "{}", ogg.len());
    }

    #[test]
    fn garbage_is_refused() {
        assert!(decode(b"not an ogg").is_err());
        assert!(duration_ms(b"").is_err());
        let mut ogg = encode(&tone(100)).unwrap();
        // Outro cabeçalho no lugar do OpusHead.
        let at = ogg.windows(8).position(|w| w == b"OpusHead").unwrap();
        ogg[at..at + 8].copy_from_slice(b"Vorbis!!");
        assert!(decode(&ogg).is_err());
    }

    #[test]
    fn resampling_changes_the_length_in_proportion() {
        let input: Vec<f32> = (0..441).map(|i| i as f32 / 441.0).collect();
        let out = resample(&input, 44_100, 48_000);
        assert_eq!(out.len(), 480);
        assert!((out[240] - 0.5).abs() < 0.01);
        assert_eq!(resample(&input, 48_000, 48_000), input);
        assert!(resample(&[], 44_100, 48_000).is_empty());
    }
}

/// Com o som de verdade: abre o microfone por meio segundo (e joga fora) e toca um
/// tom baixo de meio segundo. Fora do CI, que não tem som:
/// `cargo test -p chirp_core --lib voice::live -- --ignored`.
#[cfg(test)]
mod live {
    use super::*;

    #[test]
    #[ignore]
    fn records_and_plays_on_the_default_devices() {
        let recording = Recording::start().expect("microfone");
        std::thread::sleep(Duration::from_millis(500));
        let pcm = recording.finish().unwrap();
        assert!(pcm.len() > RATE as usize / 4, "{}", pcm.len());

        let tone: Vec<i16> = (0..RATE as usize / 2)
            .map(|i| {
                (f32::sin(i as f32 / RATE as f32 * 440.0 * std::f32::consts::TAU) * 2000.0) as i16
            })
            .collect();
        let (done, finished) = mpsc::channel();
        let _playing = Playing::start(tone, move |ms, end| {
            if end {
                let _ = done.send(ms);
            }
        })
        .expect("alto-falante");
        let ms = finished.recv_timeout(Duration::from_secs(5)).unwrap();
        assert!((450..=550).contains(&ms), "{ms}");
    }
}

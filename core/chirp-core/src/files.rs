//! Os arquivos (docs/PLANO.md, 6.7).
//!
//! Cada arquivo tem uma chave e um id aleatórios. O conteúdo vai em fatias de `CHUNK`
//! bytes, cada uma cifrada com AES-256-GCM: o nonce é o índice da fatia (a chave é só
//! deste arquivo, então não se repete) e o AAD amarra o id do arquivo, o índice e se é
//! a última, para nenhuma fatia trocar de lugar, de arquivo nem cortar o fim. O
//! BLAKE3 é do arquivo inteiro, em claro.
//!
//! Os dois aparelhos guardam o mesmo blob cifrado em `files/` (ao lado do banco): quem
//! manda cifra uma vez, e quem recebe copia as fatias como vieram. A chave fica no
//! banco, que também é cifrado; o arquivo nunca fica em claro no disco, só quando quem
//! usa salva uma cópia fora.
//!
//! A oferta (`FileOffer`) vai pela sessão, com o nome, o tamanho, o tipo, a miniatura
//! (feita aqui), o hash e a chave. As fotos perdem os metadados (o EXIF, com a
//! localização) antes de sair: são decodificadas e codificadas de novo.

use std::fs::{File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};

use aes_gcm::aead::{Aead, KeyInit, Payload};
use aes_gcm::{Aes256Gcm, Nonce};
use rusqlite::{Connection, OptionalExtension};
use zeroize::Zeroizing;

use crate::error::{CoreError, CoreResult};
use crate::random::secret_bytes;

/// O tamanho de uma fatia em claro: cifrada (com a etiqueta de 16 bytes) e num frame,
/// cabe no limite de 64 KiB do `wire`.
pub const CHUNK: usize = 60 * 1024;
const TAG: usize = 16;
/// O maior arquivo.
pub const MAX_FILE: u64 = 1 << 30;
/// Até esse tamanho, o arquivo de um contato baixa sozinho; acima, quem usa pede.
pub const AUTO_DOWNLOAD: u64 = 32 << 20;
/// A maior miniatura que viaja na oferta.
pub const MAX_THUMBNAIL: usize = 24 * 1024;
/// Uma foto maior que isso não é processada (e não sai: os metadados ficariam).
const MAX_IMAGE: usize = 64 << 20;
const MAX_NAME: usize = 255;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum State {
    /// Oferecido, esperando quem usa pedir (grande demais para baixar sozinho).
    Waiting = 0,
    /// Baixando (ou esperando o contato aparecer para baixar).
    Downloading = 1,
    /// Inteiro e conferido.
    Done = 2,
    /// O conteúdo não bateu com o hash da oferta.
    Failed = 3,
}

impl State {
    fn from_code(code: i64) -> Self {
        match code {
            1 => State::Downloading,
            2 => State::Done,
            3 => State::Failed,
            _ => State::Waiting,
        }
    }
}

/// Um arquivo como o banco guarda.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FileRow {
    /// A mensagem do arquivo (o id da linha em `messages`).
    pub message: i64,
    pub file_id: Vec<u8>,
    pub name: String,
    pub size: u64,
    pub mime: String,
    pub hash: Vec<u8>,
    pub key: Zeroizing<Vec<u8>>,
    pub thumbnail: Option<Vec<u8>>,
    pub chunks: u32,
    pub received: u32,
    pub state: State,
}

/// Quantas fatias tem um arquivo desse tamanho (um vazio tem uma, vazia).
pub fn chunks_for(size: u64) -> u32 {
    size.div_ceil(CHUNK as u64).max(1) as u32
}

fn cipher(key: &[u8]) -> CoreResult<Aes256Gcm> {
    Aes256Gcm::new_from_slice(key).map_err(|_| CoreError::Protocol)
}

fn nonce(index: u32) -> [u8; 12] {
    let mut nonce = [0u8; 12];
    nonce[4..].copy_from_slice(&u64::from(index).to_be_bytes());
    nonce
}

fn aad(file_id: &[u8], index: u32, last: bool) -> Vec<u8> {
    let mut aad = Vec::with_capacity(file_id.len() + 9);
    aad.extend_from_slice(file_id);
    aad.extend_from_slice(&u64::from(index).to_be_bytes());
    aad.push(u8::from(last));
    aad
}

pub fn seal_chunk(
    key: &[u8],
    file_id: &[u8],
    index: u32,
    last: bool,
    plain: &[u8],
) -> CoreResult<Vec<u8>> {
    let aad = aad(file_id, index, last);
    cipher(key)?
        .encrypt(
            Nonce::from_slice(&nonce(index)),
            Payload {
                msg: plain,
                aad: &aad,
            },
        )
        .map_err(|_| CoreError::Protocol)
}

pub fn open_chunk(
    key: &[u8],
    file_id: &[u8],
    index: u32,
    last: bool,
    sealed: &[u8],
) -> CoreResult<Zeroizing<Vec<u8>>> {
    let aad = aad(file_id, index, last);
    cipher(key)?
        .decrypt(
            Nonce::from_slice(&nonce(index)),
            Payload {
                msg: sealed,
                aad: &aad,
            },
        )
        .map(Zeroizing::new)
        .map_err(|_| CoreError::Protocol)
}

/// O tamanho cifrado da fatia `index` de um arquivo de `size` bytes.
pub fn sealed_len(size: u64, index: u32) -> usize {
    let start = u64::from(index) * CHUNK as u64;
    (size.saturating_sub(start).min(CHUNK as u64)) as usize + TAG
}

fn offset(index: u32) -> u64 {
    u64::from(index) * (CHUNK + TAG) as u64
}

/// Lê até encher o buffer (ou o arquivo acabar). Devolve quantos bytes vieram.
fn read_full(reader: &mut impl Read, buf: &mut [u8]) -> CoreResult<usize> {
    let mut filled = 0;
    while filled < buf.len() {
        match reader.read(&mut buf[filled..])? {
            0 => break,
            n => filled += n,
        }
    }
    Ok(filled)
}

/// Cifra o que vem de `reader` em `dst`, fatia por fatia. Devolve o tamanho e o hash.
pub fn seal(
    mut reader: impl Read,
    dst: &Path,
    key: &[u8],
    file_id: &[u8],
) -> CoreResult<(u64, [u8; 32])> {
    let mut out = File::create(dst)?;
    let mut hasher = blake3::Hasher::new();
    let mut current = Zeroizing::new(vec![0u8; CHUNK]);
    let mut next = Zeroizing::new(vec![0u8; CHUNK]);
    let mut len = read_full(&mut reader, &mut current)?;
    let (mut index, mut size) = (0u32, 0u64);
    loop {
        // Lê a próxima antes, para saber se esta é a última.
        let next_len = if len == CHUNK {
            read_full(&mut reader, &mut next)?
        } else {
            0
        };
        let last = next_len == 0;
        size += len as u64;
        if size > MAX_FILE {
            drop(out);
            let _ = std::fs::remove_file(dst);
            return Err(CoreError::InvalidFile);
        }
        hasher.update(&current[..len]);
        out.write_all(&seal_chunk(key, file_id, index, last, &current[..len])?)?;
        if last {
            break;
        }
        std::mem::swap(&mut current, &mut next);
        len = next_len;
        index += 1;
    }
    out.sync_all()?;
    Ok((size, *hasher.finalize().as_bytes()))
}

/// A fatia cifrada `index` do blob, como guardada.
pub fn read_chunk(path: &Path, size: u64, index: u32) -> CoreResult<Vec<u8>> {
    let mut file = File::open(path)?;
    file.seek(SeekFrom::Start(offset(index)))?;
    let mut buf = vec![0u8; sealed_len(size, index)];
    file.read_exact(&mut buf)?;
    Ok(buf)
}

/// Grava a fatia cifrada `index` que chegou, no lugar dela.
pub fn write_chunk(path: &Path, index: u32, sealed: &[u8]) -> CoreResult<()> {
    let mut file = OpenOptions::new()
        .create(true)
        .truncate(false)
        .write(true)
        .open(path)?;
    file.seek(SeekFrom::Start(offset(index)))?;
    file.write_all(sealed)?;
    file.set_len(offset(index) + sealed.len() as u64)?;
    Ok(())
}

/// Decifra o blob inteiro em `out`, conferindo cada fatia e, no fim, o hash.
pub fn export(path: &Path, row: &FileRow, out: &mut impl Write) -> CoreResult<()> {
    let mut hasher = blake3::Hasher::new();
    for index in 0..row.chunks {
        let sealed = read_chunk(path, row.size, index)?;
        let last = index + 1 == row.chunks;
        let plain = open_chunk(&row.key, &row.file_id, index, last, &sealed)?;
        hasher.update(&plain);
        out.write_all(&plain)?;
    }
    if hasher.finalize().as_bytes() != row.hash.as_slice() {
        return Err(CoreError::Protocol);
    }
    Ok(())
}

/// O blob bate com a oferta (todas as fatias abrem e o hash confere).
pub fn verify(path: &Path, row: &FileRow) -> bool {
    export(path, row, &mut std::io::sink()).is_ok()
}

/// Onde fica o blob de um arquivo.
pub fn blob_path(dir: &Path, file_id: &[u8]) -> PathBuf {
    let hex: String = file_id.iter().map(|b| format!("{b:02x}")).collect();
    dir.join(format!("{hex}.blob"))
}

// ---------------------------------------------------------------- nome, tipo e fotos

/// Um nome de arquivo que veio de fora: só a última parte do caminho, sem caracteres
/// de controle, com no máximo `MAX_NAME` bytes. Vazio vira "file".
pub fn clean_name(name: &str) -> String {
    let base = name.rsplit(['/', '\\']).next().unwrap_or_default();
    let mut clean: String = base.chars().filter(|c| !c.is_control()).collect();
    clean = clean.trim().to_owned();
    while clean.len() > MAX_NAME {
        clean.pop();
    }
    if clean.is_empty() || clean == "." || clean == ".." {
        "file".to_owned()
    } else {
        clean
    }
}

/// O tipo pelo nome (o que importa aqui é saber se é foto, áudio ou outro).
pub fn mime_for(name: &str) -> &'static str {
    let ext = name
        .rsplit_once('.')
        .map(|(_, e)| e.to_ascii_lowercase())
        .unwrap_or_default();
    match ext.as_str() {
        "jpg" | "jpeg" => "image/jpeg",
        "png" => "image/png",
        "gif" => "image/gif",
        "webp" => "image/webp",
        "heic" => "image/heic",
        "pdf" => "application/pdf",
        "txt" | "md" => "text/plain",
        "opus" | "ogg" | "oga" => "audio/ogg",
        "mp3" => "audio/mpeg",
        "m4a" | "aac" => "audio/mp4",
        "wav" => "audio/wav",
        "mp4" | "m4v" => "video/mp4",
        "webm" => "video/webm",
        "zip" => "application/zip",
        _ => "application/octet-stream",
    }
}

/// Uma foto que o Chirp sabe limpar (decodificar e codificar de novo).
pub fn is_clean_image(mime: &str) -> bool {
    matches!(mime, "image/jpeg" | "image/png")
}

fn decode(bytes: &[u8]) -> CoreResult<image::DynamicImage> {
    use image::ImageDecoder;
    let mut reader = image::ImageReader::new(std::io::Cursor::new(bytes))
        .with_guessed_format()
        .map_err(|_| CoreError::InvalidFile)?;
    let mut limits = image::Limits::default();
    limits.max_image_width = Some(16_384);
    limits.max_image_height = Some(16_384);
    limits.max_alloc = Some(512 << 20);
    reader.limits(limits);
    let mut decoder = reader.into_decoder().map_err(|_| CoreError::InvalidFile)?;
    // A rotação vem do EXIF, que vai sair: aplica antes, para a foto não deitar.
    let orientation = decoder
        .orientation()
        .unwrap_or(image::metadata::Orientation::NoTransforms);
    let mut image =
        image::DynamicImage::from_decoder(decoder).map_err(|_| CoreError::InvalidFile)?;
    image.apply_orientation(orientation);
    Ok(image)
}

fn jpeg(image: &image::DynamicImage, quality: u8) -> CoreResult<Vec<u8>> {
    let mut out = Vec::new();
    let rgb = image.to_rgb8();
    image::codecs::jpeg::JpegEncoder::new_with_quality(&mut out, quality)
        .encode_image(&rgb)
        .map_err(|_| CoreError::InvalidFile)?;
    Ok(out)
}

/// Uma foto pronta para sair: codificada de novo, sem metadados, e a miniatura.
pub fn clean_image(bytes: &[u8], mime: &str) -> CoreResult<(Vec<u8>, Vec<u8>)> {
    if bytes.len() > MAX_IMAGE {
        return Err(CoreError::InvalidFile);
    }
    let image = decode(bytes)?;
    let cleaned = if mime == "image/png" {
        let mut out = Vec::new();
        image
            .write_to(&mut std::io::Cursor::new(&mut out), image::ImageFormat::Png)
            .map_err(|_| CoreError::InvalidFile)?;
        out
    } else {
        jpeg(&image, 88)?
    };
    Ok((cleaned, thumbnail(&image)?))
}

/// Uma miniatura em JPEG que cabe na oferta.
fn thumbnail(image: &image::DynamicImage) -> CoreResult<Vec<u8>> {
    for (side, quality) in [(320, 70), (240, 60), (160, 50), (96, 40)] {
        let small = jpeg(&image.thumbnail(side, side), quality)?;
        if small.len() <= MAX_THUMBNAIL {
            return Ok(small);
        }
    }
    Err(CoreError::InvalidFile)
}

// ---------------------------------------------------------------- o banco

const COLUMNS: &str =
    "message, file_id, name, size, mime, hash, key, thumbnail, chunks, received, state";

fn from_row(row: &rusqlite::Row) -> rusqlite::Result<FileRow> {
    Ok(FileRow {
        message: row.get(0)?,
        file_id: row.get(1)?,
        name: row.get(2)?,
        size: row.get::<_, i64>(3)? as u64,
        mime: row.get(4)?,
        hash: row.get(5)?,
        key: Zeroizing::new(row.get(6)?),
        thumbnail: row.get(7)?,
        chunks: row.get(8)?,
        received: row.get(9)?,
        state: State::from_code(row.get(10)?),
    })
}

pub fn insert(conn: &Connection, row: &FileRow) -> CoreResult<()> {
    conn.execute(
        &format!(
            "INSERT INTO files ({COLUMNS}) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)"
        ),
        rusqlite::params![
            row.message,
            row.file_id,
            row.name,
            row.size as i64,
            row.mime,
            row.hash,
            row.key.as_slice(),
            row.thumbnail,
            row.chunks,
            row.received,
            row.state as i64,
        ],
    )?;
    Ok(())
}

pub fn by_message(conn: &Connection, message: i64) -> CoreResult<Option<FileRow>> {
    Ok(conn
        .query_row(
            &format!("SELECT {COLUMNS} FROM files WHERE message = ?1"),
            [message],
            from_row,
        )
        .optional()?)
}

/// O arquivo com esse id que eu mandei a esse contato (só ele pode pedir as fatias).
pub fn offered_to(
    conn: &Connection,
    file_id: &[u8],
    contact_id: i64,
) -> CoreResult<Option<FileRow>> {
    Ok(conn
        .query_row(
            &format!(
                "SELECT {} FROM files f JOIN messages m ON m.id = f.message
                  WHERE f.file_id = ?1 AND m.contact_id = ?2 AND m.outgoing = 1
                    AND m.deleted = 0",
                COLUMNS
                    .split(", ")
                    .map(|c| format!("f.{c}"))
                    .collect::<Vec<_>>()
                    .join(", ")
            ),
            rusqlite::params![file_id, contact_id],
            from_row,
        )
        .optional()?)
}

/// Os arquivos para baixar agora, com o contato de cada um.
pub fn wanted(conn: &Connection) -> CoreResult<Vec<(i64, FileRow)>> {
    let columns = COLUMNS
        .split(", ")
        .map(|c| format!("f.{c}"))
        .collect::<Vec<_>>()
        .join(", ");
    let mut statement = conn.prepare(&format!(
        "SELECT m.contact_id, {columns} FROM files f JOIN messages m ON m.id = f.message
          WHERE f.state = 1 AND m.outgoing = 0 AND m.deleted = 0 ORDER BY f.message"
    ))?;
    let rows = statement.query_map([], |r| {
        let contact: i64 = r.get(0)?;
        // As colunas do arquivo vêm depois do contato.
        Ok((
            contact,
            FileRow {
                message: r.get(1)?,
                file_id: r.get(2)?,
                name: r.get(3)?,
                size: r.get::<_, i64>(4)? as u64,
                mime: r.get(5)?,
                hash: r.get(6)?,
                key: Zeroizing::new(r.get(7)?),
                thumbnail: r.get(8)?,
                chunks: r.get(9)?,
                received: r.get(10)?,
                state: State::from_code(r.get(11)?),
            },
        ))
    })?;
    Ok(rows.collect::<Result<_, _>>()?)
}

pub fn set_received(conn: &Connection, message: i64, received: u32) -> CoreResult<()> {
    conn.execute(
        "UPDATE files SET received = ?2 WHERE message = ?1",
        rusqlite::params![message, received],
    )?;
    Ok(())
}

pub fn set_state(conn: &Connection, message: i64, state: State) -> CoreResult<()> {
    conn.execute(
        "UPDATE files SET state = ?2 WHERE message = ?1",
        rusqlite::params![message, state as i64],
    )?;
    Ok(())
}

/// Tira de `dir` os blobs sem arquivo no banco (apagados, ou de um envio que caiu no
/// meio).
pub fn sweep(conn: &Connection, dir: &Path) -> CoreResult<()> {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return Ok(());
    };
    let mut statement = conn.prepare("SELECT file_id FROM files")?;
    let known: std::collections::HashSet<PathBuf> = statement
        .query_map([], |r| r.get::<_, Vec<u8>>(0))?
        .filter_map(Result::ok)
        .map(|id| blob_path(dir, &id))
        .collect();
    for entry in entries.flatten() {
        let path = entry.path();
        if path.extension().is_some_and(|e| e == "blob" || e == "part") && !known.contains(&path) {
            let _ = std::fs::remove_file(&path);
        }
    }
    Ok(())
}

/// Um arquivo pronto para oferecer: cifrado em `dir`, ainda sem mensagem.
pub struct Prepared {
    pub file_id: Vec<u8>,
    pub key: Zeroizing<Vec<u8>>,
    pub name: String,
    pub size: u64,
    pub mime: String,
    pub hash: Vec<u8>,
    pub thumbnail: Option<Vec<u8>>,
    pub chunks: u32,
}

/// Lê o arquivo de `src`, limpa se for foto e cifra em `dir`. Fora do banco: um
/// arquivo grande leva tempo, e o banco não fica preso esperando.
pub fn prepare(dir: &Path, src: &Path) -> CoreResult<Prepared> {
    std::fs::create_dir_all(dir)?;
    let name = clean_name(
        &src.file_name()
            .map(|n| n.to_string_lossy())
            .unwrap_or_default(),
    );
    let mime = mime_for(&name).to_owned();
    let meta = std::fs::metadata(src).map_err(|_| CoreError::InvalidFile)?;
    if !meta.is_file() || meta.len() > MAX_FILE {
        return Err(CoreError::InvalidFile);
    }
    let file_id = secret_bytes::<16>()?.to_vec();
    let key = Zeroizing::new(secret_bytes::<32>()?.to_vec());
    let blob = blob_path(dir, &file_id);
    let (size, hash, thumbnail) = if is_clean_image(&mime) {
        let mut bytes = Zeroizing::new(Vec::new());
        File::open(src)?
            .take(MAX_IMAGE as u64 + 1)
            .read_to_end(&mut bytes)?;
        let (cleaned, thumbnail) = clean_image(&bytes, &mime)?;
        let (size, hash) = seal(cleaned.as_slice(), &blob, &key, &file_id)?;
        (size, hash, Some(thumbnail))
    } else {
        let (size, hash) = seal(File::open(src)?, &blob, &key, &file_id)?;
        (size, hash, None)
    };
    Ok(Prepared {
        chunks: chunks_for(size),
        file_id,
        key,
        name,
        size,
        mime,
        hash: hash.to_vec(),
        thumbnail,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn row(file_id: &[u8], key: &[u8], size: u64, hash: [u8; 32]) -> FileRow {
        FileRow {
            message: 1,
            file_id: file_id.to_vec(),
            name: "x".into(),
            size,
            mime: "application/octet-stream".into(),
            hash: hash.to_vec(),
            key: Zeroizing::new(key.to_vec()),
            thumbnail: None,
            chunks: chunks_for(size),
            received: 0,
            state: State::Done,
        }
    }

    fn bytes(len: usize) -> Vec<u8> {
        (0..len).map(|i| (i * 31 % 251) as u8).collect()
    }

    #[test]
    fn sealing_and_exporting_round_trips_at_every_edge() {
        let dir = tempfile::tempdir().unwrap();
        for len in [0, 1, CHUNK - 1, CHUNK, CHUNK + 1, 3 * CHUNK + 17] {
            let plain = bytes(len);
            let (key, id) = ([1u8; 32], [2u8; 16]);
            let blob = dir.path().join(format!("{len}.blob"));
            let (size, hash) = seal(plain.as_slice(), &blob, &key, &id).unwrap();
            assert_eq!(size, len as u64);
            assert_eq!(hash, *blake3::hash(&plain).as_bytes());
            let row = row(&id, &key, size, hash);
            let mut out = Vec::new();
            export(&blob, &row, &mut out).unwrap();
            assert_eq!(out, plain, "{len}");
            // O blob não leva o texto em claro.
            if len > 64 {
                let stored = std::fs::read(&blob).unwrap();
                assert!(!stored.windows(64).any(|w| w == &plain[..64]));
            }
        }
    }

    #[test]
    fn copying_chunk_by_chunk_gives_the_same_file() {
        let dir = tempfile::tempdir().unwrap();
        let plain = bytes(2 * CHUNK + 5);
        let (key, id) = ([3u8; 32], [4u8; 16]);
        let from = dir.path().join("a.blob");
        let to = dir.path().join("b.blob");
        let (size, hash) = seal(plain.as_slice(), &from, &key, &id).unwrap();
        let row = row(&id, &key, size, hash);
        for index in 0..row.chunks {
            write_chunk(&to, index, &read_chunk(&from, size, index).unwrap()).unwrap();
        }
        assert!(verify(&to, &row));
    }

    #[test]
    fn a_moved_cut_or_foreign_chunk_does_not_open() {
        let (key, id) = ([5u8; 32], [6u8; 16]);
        let sealed = seal_chunk(&key, &id, 2, false, b"fatia").unwrap();
        assert!(open_chunk(&key, &id, 2, false, &sealed).is_ok());
        assert!(open_chunk(&key, &id, 3, false, &sealed).is_err());
        assert!(open_chunk(&key, &id, 2, true, &sealed).is_err());
        assert!(open_chunk(&key, &[7u8; 16], 2, false, &sealed).is_err());
        assert!(open_chunk(&[9u8; 32], &id, 2, false, &sealed).is_err());
    }

    #[test]
    fn a_tampered_blob_fails_the_check() {
        let dir = tempfile::tempdir().unwrap();
        let (key, id) = ([1u8; 32], [2u8; 16]);
        let blob = dir.path().join("t.blob");
        let (size, hash) = seal(bytes(CHUNK + 10).as_slice(), &blob, &key, &id).unwrap();
        let good = row(&id, &key, size, hash);
        assert!(verify(&blob, &good));
        let mut wrong_hash = good.clone();
        wrong_hash.hash = vec![0; 32];
        assert!(!verify(&blob, &wrong_hash));
        let mut stored = std::fs::read(&blob).unwrap();
        stored[100] ^= 1;
        std::fs::write(&blob, stored).unwrap();
        assert!(!verify(&blob, &good));
    }

    #[test]
    fn names_from_outside_are_cleaned() {
        assert_eq!(clean_name("../../etc/passwd"), "passwd");
        assert_eq!(clean_name("C:\\Users\\x\\foto.jpg"), "foto.jpg");
        assert_eq!(clean_name("a\u{7}b\n.txt"), "ab.txt");
        assert_eq!(clean_name(".."), "file");
        assert_eq!(clean_name("   "), "file");
        assert!(clean_name(&"é".repeat(300)).len() <= MAX_NAME);
        assert_eq!(mime_for("Foto.JPG"), "image/jpeg");
        assert_eq!(mime_for("sem extensão"), "application/octet-stream");
    }

    /// Um JPEG com um EXIF de mentira (com "GPS" dentro), feito aqui.
    fn jpeg_with_exif() -> Vec<u8> {
        let image = image::DynamicImage::new_rgb8(400, 300);
        let plain = jpeg(&image, 90).unwrap();
        let mut exif = b"Exif\0\0MM\0*\0\0\0\x08\0\0GPSLatitude-23.5505".to_vec();
        let len = (exif.len() + 2) as u16;
        let mut out = plain[..2].to_vec(); // SOI
        out.extend_from_slice(&[0xFF, 0xE1]);
        out.extend_from_slice(&len.to_be_bytes());
        out.append(&mut exif);
        out.extend_from_slice(&plain[2..]);
        out
    }

    #[test]
    fn photos_lose_their_metadata_and_get_a_thumbnail() {
        let photo = jpeg_with_exif();
        assert!(photo.windows(3).any(|w| w == b"GPS"));
        let (cleaned, thumb) = clean_image(&photo, "image/jpeg").unwrap();
        assert!(!cleaned.windows(3).any(|w| w == b"GPS"));
        assert!(!cleaned.windows(4).any(|w| w == b"Exif"));
        assert!(thumb.len() <= MAX_THUMBNAIL);
        let small = image::load_from_memory(&thumb).unwrap();
        assert!(small.width() <= 320 && small.height() <= 320);
        assert!(clean_image(b"isto nao e foto", "image/jpeg").is_err());
    }

    #[test]
    fn preparing_a_photo_seals_the_cleaned_one() {
        let dir = tempfile::tempdir().unwrap();
        let src = dir.path().join("praia.JPG");
        std::fs::write(&src, jpeg_with_exif()).unwrap();
        let files = dir.path().join("files");
        let prepared = prepare(&files, &src).unwrap();
        assert_eq!(prepared.name, "praia.JPG");
        assert_eq!(prepared.mime, "image/jpeg");
        assert!(prepared.thumbnail.is_some());
        let blob = blob_path(&files, &prepared.file_id);
        let row = FileRow {
            message: 1,
            file_id: prepared.file_id.clone(),
            name: prepared.name.clone(),
            size: prepared.size,
            mime: prepared.mime.clone(),
            hash: prepared.hash.clone(),
            key: prepared.key.clone(),
            thumbnail: None,
            chunks: prepared.chunks,
            received: 0,
            state: State::Done,
        };
        let mut out = Vec::new();
        export(&blob, &row, &mut out).unwrap();
        assert!(!out.windows(3).any(|w| w == b"GPS"));
        assert!(image::load_from_memory(&out).is_ok());
    }
}

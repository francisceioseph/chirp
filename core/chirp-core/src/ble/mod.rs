//! O Bluetooth LE (fase 8, docs/PLANO.md 7.4): mensagens entre dois aparelhos perto,
//! sem rede nenhuma.
//!
//! - **O anúncio** leva só os dados de serviço do Chirp (o [`SERVICE_UUID`]): um token
//!   de época de 8 bytes, `HMAC-SHA256(chave de descoberta, "chirp-ble-v1", época)`, e
//!   a porta (PSM) do canal L2CAP. Sem nome nem id fixo: um contato reconhece o token,
//!   e quem não é vê um número que muda a cada 15 minutos. O UUID, esse, é fixo: quem
//!   procura sabe que há um Chirp por perto. Por isso o Bluetooth começa desligado.
//! - **O canal** é um L2CAP CoC (o fluxo que o rádio de cada sistema dá), e por cima
//!   dele o Noise ([`secure`]); por cima do Noise, os mesmos frames do iroh.
//! - **O rádio** é a [`Radio`]: no Linux, o BlueZ ([`bluez`]); nos outros sistemas,
//!   o código nativo do app (fase 8, parte 2). Os testes usam um rádio na memória.

use std::collections::BTreeMap;

use async_trait::async_trait;
use hmac::{Hmac, KeyInit, Mac};
use sha2::Sha256;
use tokio::io::{AsyncRead, AsyncWrite};
use tokio::sync::mpsc;

use crate::discovery;
use crate::error::CoreResult;

#[cfg(target_os = "linux")]
pub mod bluez;
#[cfg(test)]
pub mod memory;
pub mod secure;

/// O serviço do Chirp no Bluetooth.
pub const SERVICE_UUID: u128 = 0x3200ffb9_0d62_480b_bc00_63ec5fe3365c;
/// O token no anúncio.
pub const TOKEN_LEN: usize = 8;
/// Os dados de serviço: o token e o PSM (2 bytes, little-endian como o resto do BLE).
/// Cabem no anúncio legado de 31 bytes com o UUID de 128 bits e as flags.
pub const ADVERT_LEN: usize = TOKEN_LEN + 2;

pub type Token = [u8; TOKEN_LEN];

/// O token de uma chave de descoberta numa época (a mesma época do mDNS, outro rótulo,
/// para os dois anúncios não se ligarem).
pub fn token(discovery_key: &[u8], epoch: u64) -> Token {
    let mut mac =
        Hmac::<Sha256>::new_from_slice(discovery_key).expect("HMAC takes keys of any size");
    mac.update(b"chirp-ble-v1");
    mac.update(&epoch.to_be_bytes());
    let bytes = mac.finalize().into_bytes();
    let mut out = [0u8; TOKEN_LEN];
    out.copy_from_slice(&bytes[..TOKEN_LEN]);
    out
}

/// Os dados de serviço do anúncio.
pub fn advert(token: &Token, psm: u16) -> Vec<u8> {
    let mut out = Vec::with_capacity(ADVERT_LEN);
    out.extend_from_slice(token);
    out.extend_from_slice(&psm.to_le_bytes());
    out
}

/// O token e o PSM de um anúncio; o que não tem o tamanho certo não é do Chirp.
pub fn parse_advert(data: &[u8]) -> Option<(Token, u16)> {
    if data.len() != ADVERT_LEN {
        return None;
    }
    let mut token = [0u8; TOKEN_LEN];
    token.copy_from_slice(&data[..TOKEN_LEN]);
    let psm = u16::from_le_bytes([data[TOKEN_LEN], data[TOKEN_LEN + 1]]);
    (psm != 0).then_some((token, psm))
}

/// O contato dono do token, na época de agora ou nas vizinhas.
pub fn owner<'a>(
    contacts: impl IntoIterator<Item = (i64, &'a [u8])>,
    found: &Token,
    now_secs: u64,
) -> Option<i64> {
    let now = discovery::epoch(now_secs);
    contacts.into_iter().find_map(|(id, key)| {
        (key.len() == 32
            && [now.saturating_sub(1), now, now + 1]
                .iter()
                .any(|e| token(key, *e) == *found))
        .then_some(id)
    })
}

/// Um fluxo de bytes nos dois sentidos (o canal L2CAP, ou o já cifrado).
pub trait Duplex: AsyncRead + AsyncWrite + Send + Unpin {}
impl<T: AsyncRead + AsyncWrite + Send + Unpin> Duplex for T {}

pub type Link = Box<dyn Duplex>;

/// Um anúncio do Chirp visto pelo rádio: o aparelho (um endereço que só o rádio
/// entende) e os dados de serviço.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Sighting {
    pub peer: String,
    pub data: Vec<u8>,
}

/// O rádio Bluetooth de um sistema.
#[async_trait]
pub trait Radio: Send + Sync + 'static {
    /// Abre o canal L2CAP de entrada: o PSM e as conexões que chegam.
    async fn listen(&self) -> CoreResult<(u16, mpsc::Receiver<Link>)>;
    /// Anuncia estes dados de serviço, no lugar dos de antes.
    async fn advertise(&self, data: Vec<u8>) -> CoreResult<()>;
    /// Procura os anúncios do Chirp; cada um que aparece (ou muda) vem pelo canal.
    async fn scan(&self) -> CoreResult<mpsc::Receiver<Sighting>>;
    /// Conecta ao canal L2CAP de um aparelho visto.
    async fn connect(&self, peer: &str, psm: u16) -> CoreResult<Link>;
    /// Para de anunciar (a rede foi desligada).
    async fn stop(&self);
}

/// Os aparelhos vistos há pouco: só o último de cada contato.
#[derive(Default)]
pub struct Nearby {
    seen: BTreeMap<i64, (String, u16, std::time::Instant)>,
}

/// Quanto tempo um anúncio visto vale para tentar.
pub const NEARBY_FOR: std::time::Duration = std::time::Duration::from_secs(120);

impl Nearby {
    pub fn saw(&mut self, contact_id: i64, peer: String, psm: u16) {
        self.seen
            .insert(contact_id, (peer, psm, std::time::Instant::now()));
    }

    /// Onde o contato estava, se foi visto há pouco.
    pub fn get(&self, contact_id: i64) -> Option<(String, u16)> {
        self.seen
            .get(&contact_id)
            .filter(|(_, _, at)| at.elapsed() < NEARBY_FOR)
            .map(|(peer, psm, _)| (peer.clone(), *psm))
    }

    pub fn forget(&mut self, contact_id: i64) {
        self.seen.remove(&contact_id);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_advert_carries_a_token_and_a_port() {
        let key = [7u8; 32];
        let t = token(&key, 100);
        assert_ne!(t, token(&key, 101), "muda a cada época");
        assert_ne!(
            t[..],
            hex(&crate::discovery::token(&key, 100))[..TOKEN_LEN],
            "não é o token do mDNS"
        );
        let data = advert(&t, 0x0081);
        assert_eq!(data.len(), ADVERT_LEN);
        assert_eq!(parse_advert(&data), Some((t, 0x0081)));
        assert_eq!(parse_advert(&data[1..]), None);
        assert_eq!(parse_advert(&advert(&t, 0)), None);
    }

    fn hex(text: &str) -> Vec<u8> {
        (0..text.len())
            .step_by(2)
            .map(|i| u8::from_str_radix(&text[i..i + 2], 16).unwrap())
            .collect()
    }

    #[test]
    fn a_contact_is_found_by_its_token_around_now() {
        let (a, b) = ([1u8; 32], [2u8; 32]);
        let now = 1_000_000;
        let epoch = discovery::epoch(now);
        let keys = [(10, &a[..]), (20, &b[..])];
        assert_eq!(owner(keys, &token(&b, epoch), now), Some(20));
        assert_eq!(owner(keys, &token(&a, epoch + 1), now), Some(10));
        assert_eq!(owner(keys, &token(&a, epoch + 2), now), None);
        assert_eq!(
            owner([(30, &[3u8; 8][..])], &token(&[3u8; 8], epoch), now),
            None
        );
    }
}

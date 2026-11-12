//! O protocolo da caixa postal (docs/PROTOCOLO.md, "A caixa postal"), no ALPN
//! `chirp-mailbox/1`: uma conexão QUIC do iroh e um stream bidirecional, com frames
//! `tamanho (u32, big-endian) || Frame (Protobuf)`.
//!
//! A caixa não tem chave de nada. O que entra (`Deposit`) é um envelope que já saiu
//! cifrado da sessão do Signal, e quem deposita só mostra uma ficha (`drop`) que o
//! dono da caixa deu a ele. A caixa guarda o SHA-256 das fichas, não as fichas.

use prost::Message;
use sha2::{Digest, Sha256};
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};

pub const ALPN: &[u8] = b"chirp-mailbox/1";
pub const VERSION: u32 = 1;

/// O maior envelope guardado: um frame inteiro do Chirp (64 KiB).
pub const MAX_ENVELOPE: usize = 64 * 1024;
/// O maior frame da caixa: um envelope e o que vai em volta.
pub const MAX_FRAME: usize = MAX_ENVELOPE + 1024;
/// Quantas fichas um dono registra (uma por contato).
pub const MAX_DROPS: usize = 4096;
/// Quantos itens vão numa resposta ao `Fetch`; o resto vem no próximo.
pub const FETCH_BATCH: usize = 256;

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum ProtoError {
    #[error("a conexão caiu")]
    Closed,
    #[error("fora do protocolo")]
    Invalid,
}

#[derive(Clone, PartialEq, Message)]
pub struct Frame {
    #[prost(uint32, tag = "1")]
    pub version: u32,
    #[prost(oneof = "Body", tags = "2, 3, 4, 5, 6, 7, 8, 9, 10")]
    pub body: Option<Body>,
}

#[derive(Clone, PartialEq, prost::Oneof)]
pub enum Body {
    /// Quem vai ser dono mostra o código de ligação (uso único, 24 horas). O dono é o
    /// nó da conexão, autenticado pelo TLS do QUIC.
    #[prost(message, tag = "2")]
    Pair(Pair),
    /// Feito.
    #[prost(message, tag = "3")]
    Done(Done),
    /// Recusado, sem motivo.
    #[prost(message, tag = "4")]
    Refused(Refused),
    /// Só o dono: as fichas que valem agora (o SHA-256 de cada uma). Troca todas.
    #[prost(message, tag = "5")]
    SetDrops(SetDrops),
    /// Qualquer um com uma ficha: guarda o envelope para o dono dela.
    #[prost(message, tag = "6")]
    Deposit(Deposit),
    /// Só o dono: manda o que chegou depois de `after`, até `FETCH_BATCH` itens, e
    /// um `Done` no fim.
    #[prost(message, tag = "7")]
    Fetch(Fetch),
    /// Um envelope guardado.
    #[prost(message, tag = "8")]
    Item(Item),
    /// Só o dono: apaga até o `seq` (inclusive), já lido.
    #[prost(message, tag = "9")]
    Remove(Remove),
    /// Só o dono: desliga a caixa dele, com tudo o que estava guardado.
    #[prost(message, tag = "10")]
    Unpair(Unpair),
}

#[derive(Clone, PartialEq, Message)]
pub struct Pair {
    #[prost(bytes = "vec", tag = "1")]
    pub token: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Done {}

#[derive(Clone, PartialEq, Message)]
pub struct Refused {}

#[derive(Clone, PartialEq, Message)]
pub struct SetDrops {
    #[prost(bytes = "vec", repeated, tag = "1")]
    pub hashes: Vec<Vec<u8>>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Deposit {
    #[prost(bytes = "vec", tag = "1")]
    pub drop: Vec<u8>,
    #[prost(bytes = "vec", tag = "2")]
    pub envelope: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Fetch {
    #[prost(uint64, tag = "1")]
    pub after: u64,
}

#[derive(Clone, PartialEq, Message)]
pub struct Item {
    #[prost(uint64, tag = "1")]
    pub seq: u64,
    /// O SHA-256 da ficha com que foi depositado: o dono sabe de que contato veio.
    #[prost(bytes = "vec", tag = "2")]
    pub drop: Vec<u8>,
    #[prost(bytes = "vec", tag = "3")]
    pub envelope: Vec<u8>,
    /// Quando a caixa guardou, em segundos desde 1970.
    #[prost(uint64, tag = "4")]
    pub stored_at: u64,
}

#[derive(Clone, PartialEq, Message)]
pub struct Remove {
    #[prost(uint64, tag = "1")]
    pub up_to: u64,
}

#[derive(Clone, PartialEq, Message)]
pub struct Unpair {}

/// O SHA-256 de uma ficha (ou de um código de ligação): é o que a caixa guarda.
pub fn hash(token: &[u8]) -> [u8; 32] {
    Sha256::digest(token).into()
}

pub fn frame(body: Body) -> Frame {
    Frame {
        version: VERSION,
        body: Some(body),
    }
}

pub async fn write<W: AsyncWrite + Unpin>(out: &mut W, body: Body) -> Result<(), ProtoError> {
    let bytes = frame(body).encode_to_vec();
    if bytes.len() > MAX_FRAME {
        return Err(ProtoError::Invalid);
    }
    out.write_u32(bytes.len() as u32)
        .await
        .map_err(|_| ProtoError::Closed)?;
    out.write_all(&bytes).await.map_err(|_| ProtoError::Closed)
}

/// Lê um frame: o tamanho é conferido antes de alocar, e uma versão diferente é
/// recusada.
pub async fn read<R: AsyncRead + Unpin>(input: &mut R) -> Result<Body, ProtoError> {
    let len = input.read_u32().await.map_err(|_| ProtoError::Closed)? as usize;
    if len > MAX_FRAME {
        return Err(ProtoError::Invalid);
    }
    let mut bytes = vec![0u8; len];
    input
        .read_exact(&mut bytes)
        .await
        .map_err(|_| ProtoError::Closed)?;
    decode(&bytes)
}

pub fn decode(bytes: &[u8]) -> Result<Body, ProtoError> {
    let frame = Frame::decode(bytes).map_err(|_| ProtoError::Invalid)?;
    if frame.version != VERSION {
        return Err(ProtoError::Invalid);
    }
    frame.body.ok_or(ProtoError::Invalid)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn a_frame_goes_and_comes_back() {
        let (mut a, mut b) = tokio::io::duplex(MAX_FRAME * 2);
        let body = Body::Deposit(Deposit {
            drop: vec![7; 32],
            envelope: vec![1; MAX_ENVELOPE],
        });
        write(&mut a, body.clone()).await.unwrap();
        assert_eq!(read(&mut b).await.unwrap(), body);
    }

    #[tokio::test]
    async fn big_frames_and_other_versions_are_refused() {
        let (mut a, mut b) = tokio::io::duplex(64);
        a.write_u32((MAX_FRAME + 1) as u32).await.unwrap();
        assert_eq!(read(&mut b).await, Err(ProtoError::Invalid));
        let other = Frame {
            version: 2,
            body: Some(Body::Done(Done {})),
        }
        .encode_to_vec();
        assert_eq!(decode(&other), Err(ProtoError::Invalid));
        assert_eq!(decode(&[0xff, 0xff, 0xff]), Err(ProtoError::Invalid));
    }

    #[test]
    fn the_hash_is_sha256() {
        assert_eq!(
            hash(b"abc")[..4],
            [0xba, 0x78, 0x16, 0xbf],
            "o vetor do SHA-256 de \"abc\""
        );
    }
}

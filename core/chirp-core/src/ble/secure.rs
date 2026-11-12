//! O canal cifrado sobre o Bluetooth: o Noise (`Noise_NN_25519_ChaChaPoly_BLAKE2s`,
//! pelo `snow`) e, logo depois do aperto de mão, cada lado prova quem é assinando o
//! hash do aperto de mão com a chave do nó (a mesma que o iroh usa, e que os contatos
//! já conhecem). A assinatura vai cifrada, então quem escuta o rádio não vê de quem é.
//!
//! O hash do aperto de mão amarra a assinatura a esta conexão (as chaves efêmeras dos
//! dois lados), e o papel (quem chamou, quem atendeu) vai junto, para uma assinatura
//! não servir de volta. Cada mensagem do Noise vai com o tamanho na frente (2 bytes).

use std::sync::{Arc, Mutex};
use std::time::Duration;

use iroh::{PublicKey, SecretKey, Signature};
use snow::{HandshakeState, TransportState};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

use super::{Duplex, Link};
use crate::error::{CoreError, CoreResult};

const PATTERN: &str = "Noise_NN_25519_ChaChaPoly_BLAKE2s";
const PROLOGUE: &[u8] = b"chirp-ble/1";
const AUTH: &[u8] = b"chirp-ble-auth-v1";
/// A maior mensagem do Noise.
const MAX_NOISE: usize = 65535;
/// O maior pedaço em claro numa mensagem (o resto é a etiqueta do AEAD).
const CHUNK: usize = 16 * 1024;
/// Quanto o aperto de mão pode demorar.
pub const HANDSHAKE_TIMEOUT: Duration = Duration::from_secs(20);

fn builder() -> snow::Builder<'static> {
    snow::Builder::new(PATTERN.parse().expect("valid noise pattern"))
}

async fn write_msg<W: tokio::io::AsyncWrite + Unpin>(out: &mut W, msg: &[u8]) -> CoreResult<()> {
    let len = u16::try_from(msg.len()).map_err(|_| CoreError::Protocol)?;
    out.write_u16(len)
        .await
        .map_err(|_| CoreError::Unreachable)?;
    out.write_all(msg)
        .await
        .map_err(|_| CoreError::Unreachable)?;
    out.flush().await.map_err(|_| CoreError::Unreachable)
}

async fn read_msg<R: tokio::io::AsyncRead + Unpin>(input: &mut R) -> CoreResult<Vec<u8>> {
    let len = input.read_u16().await.map_err(|_| CoreError::Unreachable)? as usize;
    let mut msg = vec![0u8; len];
    input
        .read_exact(&mut msg)
        .await
        .map_err(|_| CoreError::Unreachable)?;
    Ok(msg)
}

fn signed(role: u8, hash: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(AUTH.len() + 1 + hash.len());
    out.extend_from_slice(AUTH);
    out.push(role);
    out.extend_from_slice(hash);
    out
}

/// Conecta como quem chamou. Devolve o canal em claro e a chave do nó do outro lado.
pub async fn initiate(link: Link, key: &SecretKey) -> CoreResult<(Link, [u8; 32])> {
    tokio::time::timeout(HANDSHAKE_TIMEOUT, handshake(link, key, true))
        .await
        .map_err(|_| CoreError::Unreachable)?
}

/// Atende quem chamou. Devolve o canal em claro e a chave do nó do outro lado.
pub async fn respond(link: Link, key: &SecretKey) -> CoreResult<(Link, [u8; 32])> {
    tokio::time::timeout(HANDSHAKE_TIMEOUT, handshake(link, key, false))
        .await
        .map_err(|_| CoreError::Unreachable)?
}

async fn handshake(
    mut link: Link,
    key: &SecretKey,
    initiator: bool,
) -> CoreResult<(Link, [u8; 32])> {
    let b = builder()
        .prologue(PROLOGUE)
        .map_err(|_| CoreError::Protocol)?;
    let mut hs: HandshakeState = if initiator {
        b.build_initiator()
    } else {
        b.build_responder()
    }
    .map_err(|_| CoreError::Protocol)?;
    let mut buf = vec![0u8; MAX_NOISE];
    // NN: -> e; <- e, ee.
    if initiator {
        let n = hs
            .write_message(&[], &mut buf)
            .map_err(|_| CoreError::Protocol)?;
        write_msg(&mut link, &buf[..n]).await?;
        let msg = read_msg(&mut link).await?;
        hs.read_message(&msg, &mut buf)
            .map_err(|_| CoreError::Protocol)?;
    } else {
        let msg = read_msg(&mut link).await?;
        hs.read_message(&msg, &mut buf)
            .map_err(|_| CoreError::Protocol)?;
        let n = hs
            .write_message(&[], &mut buf)
            .map_err(|_| CoreError::Protocol)?;
        write_msg(&mut link, &buf[..n]).await?;
    }
    let hash = hs.get_handshake_hash().to_vec();
    let mut transport = hs.into_transport_mode().map_err(|_| CoreError::Protocol)?;
    // Quem sou: a chave do nó e a assinatura do hash, no meu papel.
    let (mine, theirs) = if initiator { (0u8, 1u8) } else { (1u8, 0u8) };
    let mut auth = key.public().as_bytes().to_vec();
    auth.extend_from_slice(&key.sign(&signed(mine, &hash)).to_bytes());
    let n = transport
        .write_message(&auth, &mut buf)
        .map_err(|_| CoreError::Protocol)?;
    write_msg(&mut link, &buf[..n]).await?;
    let msg = read_msg(&mut link).await?;
    let n = transport
        .read_message(&msg, &mut buf)
        .map_err(|_| CoreError::Protocol)?;
    if n != 32 + Signature::LENGTH {
        return Err(CoreError::Protocol);
    }
    let remote: [u8; 32] = buf[..32].try_into().map_err(|_| CoreError::Protocol)?;
    let signature = Signature::from_bytes(buf[32..n].try_into().map_err(|_| CoreError::Protocol)?);
    PublicKey::from_bytes(&remote)
        .map_err(|_| CoreError::Protocol)?
        .verify(&signed(theirs, &hash), &signature)
        .map_err(|_| CoreError::Protocol)?;
    Ok((pump(link, transport), remote))
}

/// O canal em claro: o que se escreve nele sai cifrado pelo rádio, e o que chega
/// decifrado sai dele. Uma mensagem que não decifra fecha tudo.
fn pump(link: Link, transport: TransportState) -> Link {
    let (app, inner) = tokio::io::duplex(4 * CHUNK);
    let (mut inner_r, mut inner_w) = tokio::io::split(inner);
    let (mut link_r, mut link_w) = tokio::io::split(link);
    let transport = Arc::new(Mutex::new(transport));
    let out = transport.clone();
    tokio::spawn(async move {
        let mut plain = vec![0u8; CHUNK];
        let mut sealed = vec![0u8; MAX_NOISE];
        loop {
            let n = match inner_r.read(&mut plain).await {
                Ok(0) | Err(_) => break,
                Ok(n) => n,
            };
            let len = {
                let Ok(mut t) = out.lock() else { break };
                match t.write_message(&plain[..n], &mut sealed) {
                    Ok(len) => len,
                    Err(_) => break,
                }
            };
            if write_msg(&mut link_w, &sealed[..len]).await.is_err() {
                break;
            }
        }
        let _ = link_w.shutdown().await;
    });
    tokio::spawn(async move {
        let mut plain = vec![0u8; MAX_NOISE];
        loop {
            let Ok(msg) = read_msg(&mut link_r).await else {
                break;
            };
            let n = {
                let Ok(mut t) = transport.lock() else { break };
                match t.read_message(&msg, &mut plain) {
                    Ok(n) => n,
                    Err(_) => break,
                }
            };
            if inner_w.write_all(&plain[..n]).await.is_err() {
                break;
            }
        }
        let _ = inner_w.shutdown().await;
    });
    Box::new(app) as Box<dyn Duplex>
}

#[cfg(test)]
mod tests {
    use super::*;

    fn key() -> SecretKey {
        let mut bytes = [0u8; 32];
        getrandom::fill(&mut bytes).unwrap();
        SecretKey::from_bytes(&bytes)
    }

    #[tokio::test]
    async fn both_sides_learn_who_the_other_is_and_talk() {
        let (a, b) = tokio::io::duplex(1024);
        let (ka, kb) = (key(), key());
        let kb2 = kb.clone();
        let responder = tokio::spawn(async move { respond(Box::new(b), &kb2).await });
        let (mut ca, remote_b) = initiate(Box::new(a), &ka).await.unwrap();
        let (mut cb, remote_a) = responder.await.unwrap().unwrap();
        assert_eq!(remote_b, *kb.public().as_bytes());
        assert_eq!(remote_a, *ka.public().as_bytes());
        // Mais que um pedaço, nos dois sentidos.
        let big: Vec<u8> = (0..100_000u32).map(|i| i as u8).collect();
        let sent = big.clone();
        let writer = tokio::spawn(async move {
            ca.write_all(&sent).await.unwrap();
            ca.write_all(b"!").await.unwrap();
            let mut back = [0u8; 2];
            ca.read_exact(&mut back).await.unwrap();
            back
        });
        let mut got = vec![0u8; big.len() + 1];
        cb.read_exact(&mut got).await.unwrap();
        assert_eq!(&got[..big.len()], &big[..]);
        cb.write_all(b"ok").await.unwrap();
        assert_eq!(&writer.await.unwrap(), b"ok");
    }

    /// Um intruso no meio só repassa bytes: não lê nada e o que muda quebra o canal.
    #[tokio::test]
    async fn a_changed_byte_breaks_the_link() {
        let (a, mid_a) = tokio::io::duplex(1024);
        let (mid_b, b) = tokio::io::duplex(1024);
        tokio::spawn(async move {
            let (mut a_r, mut a_w) = tokio::io::split(mid_a);
            let (mut b_r, mut b_w) = tokio::io::split(mid_b);
            // De quem atende para quem chama, sem mudar nada.
            tokio::spawn(async move {
                let _ = tokio::io::copy(&mut b_r, &mut a_w).await;
            });
            // De quem chama: a primeira mensagem (2 + 32 bytes) passa, e um byte da
            // seguinte, já cifrada, muda.
            let mut buf = vec![0u8; 4096];
            let mut offset = 0usize;
            while let Ok(n @ 1..) = a_r.read(&mut buf).await {
                if (offset..offset + n).contains(&40) {
                    buf[40 - offset] ^= 1;
                }
                offset += n;
                if b_w.write_all(&buf[..n]).await.is_err() {
                    break;
                }
            }
        });
        let kb = key();
        let responder = tokio::spawn(async move { respond(Box::new(b), &kb).await });
        let initiated = initiate(Box::new(a), &key()).await;
        let responded = responder.await.unwrap();
        assert!(initiated.is_err() || responded.is_err());
    }

    #[tokio::test]
    async fn a_forged_identity_is_refused() {
        // Quem atende diz uma chave e assina com outra.
        let (a, b) = tokio::io::duplex(1024);
        let responder = tokio::spawn(async move {
            let mut link: Link = Box::new(b);
            let mut hs = builder()
                .prologue(PROLOGUE)
                .unwrap()
                .build_responder()
                .unwrap();
            let mut buf = vec![0u8; MAX_NOISE];
            let msg = read_msg(&mut link).await.unwrap();
            hs.read_message(&msg, &mut buf).unwrap();
            let n = hs.write_message(&[], &mut buf).unwrap();
            write_msg(&mut link, &buf[..n]).await.unwrap();
            let hash = hs.get_handshake_hash().to_vec();
            let mut t = hs.into_transport_mode().unwrap();
            let mut auth = key().public().as_bytes().to_vec();
            auth.extend_from_slice(&key().sign(&signed(1, &hash)).to_bytes());
            let n = t.write_message(&auth, &mut buf).unwrap();
            write_msg(&mut link, &buf[..n]).await.unwrap();
            let _ = read_msg(&mut link).await;
        });
        assert!(initiate(Box::new(a), &key()).await.is_err());
        responder.abort();
    }
}

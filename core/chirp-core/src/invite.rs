//! O convite: o que vai no QR e no link (docs/PLANO.md, 6.2).
//!
//! Leva a chave de identidade de quem convida (quem lê já sabe com quem fala), o nó do
//! transporte, os endereços de agora na rede local e um token de uso único. As prekeys
//! não vão aqui (a Kyber sozinha tem 1568 bytes, e o QR ficaria ilegível): quem lê pede
//! pela rede, mostrando o token, e confere a assinatura delas com a identidade do
//! convite.
//!
//! Formato v1, em bytes: `versão (1) || identidade (33) || nó (32) || token (32) ||
//! n (1) || n × [4 || IPv4 (4) || porta (2) | 6 || IPv6 (16) || porta (2)]`. O link é
//! `chirp://invite#` e os bytes em base64url sem preenchimento; o que vem depois do
//! `#` não vai a servidor nenhum se alguém abrir o link num navegador.

use std::net::{IpAddr, Ipv4Addr, Ipv6Addr, SocketAddr};

use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use base64::Engine;

use crate::error::{CoreError, CoreResult};

pub const LINK_PREFIX: &str = "chirp://invite#";
const VERSION: u8 = 1;
const MAX_ADDRS: usize = 8;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Invite {
    pub identity_key: [u8; 33],
    pub endpoint_id: [u8; 32],
    pub token: [u8; 32],
    pub addrs: Vec<SocketAddr>,
}

impl Invite {
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(1 + 33 + 32 + 32 + 1 + self.addrs.len() * 19);
        out.push(VERSION);
        out.extend_from_slice(&self.identity_key);
        out.extend_from_slice(&self.endpoint_id);
        out.extend_from_slice(&self.token);
        let addrs = &self.addrs[..self.addrs.len().min(MAX_ADDRS)];
        out.push(addrs.len() as u8);
        for addr in addrs {
            match addr.ip() {
                IpAddr::V4(ip) => {
                    out.push(4);
                    out.extend_from_slice(&ip.octets());
                }
                IpAddr::V6(ip) => {
                    out.push(6);
                    out.extend_from_slice(&ip.octets());
                }
            }
            out.extend_from_slice(&addr.port().to_be_bytes());
        }
        out
    }

    pub fn from_bytes(bytes: &[u8]) -> CoreResult<Self> {
        let mut r = Reader(bytes);
        if r.take(1)?[0] != VERSION {
            return Err(CoreError::InvalidInvite);
        }
        let identity_key: [u8; 33] = r.array()?;
        if identity_key[0] != 0x05 {
            return Err(CoreError::InvalidInvite);
        }
        let endpoint_id = r.array()?;
        let token = r.array()?;
        let count = usize::from(r.take(1)?[0]);
        if count > MAX_ADDRS {
            return Err(CoreError::InvalidInvite);
        }
        let mut addrs = Vec::with_capacity(count);
        for _ in 0..count {
            let ip = match r.take(1)?[0] {
                4 => IpAddr::V4(Ipv4Addr::from(r.array::<4>()?)),
                6 => IpAddr::V6(Ipv6Addr::from(r.array::<16>()?)),
                _ => return Err(CoreError::InvalidInvite),
            };
            let port = u16::from_be_bytes(r.array()?);
            addrs.push(SocketAddr::new(ip, port));
        }
        if !r.0.is_empty() {
            return Err(CoreError::InvalidInvite);
        }
        Ok(Self {
            identity_key,
            endpoint_id,
            token,
            addrs,
        })
    }

    pub fn to_link(&self) -> String {
        format!("{LINK_PREFIX}{}", URL_SAFE_NO_PAD.encode(self.to_bytes()))
    }

    /// Lê um link, tolerando espaços e quebras de linha de quem copiou de outro app.
    pub fn from_link(link: &str) -> CoreResult<Self> {
        let link: String = link.chars().filter(|c| !c.is_whitespace()).collect();
        let payload = link
            .strip_prefix(LINK_PREFIX)
            .ok_or(CoreError::InvalidInvite)?;
        if payload.len() > 512 {
            return Err(CoreError::InvalidInvite);
        }
        let bytes = URL_SAFE_NO_PAD
            .decode(payload)
            .map_err(|_| CoreError::InvalidInvite)?;
        Self::from_bytes(&bytes)
    }
}

struct Reader<'a>(&'a [u8]);

impl Reader<'_> {
    fn take(&mut self, n: usize) -> CoreResult<&[u8]> {
        if self.0.len() < n {
            return Err(CoreError::InvalidInvite);
        }
        let (head, tail) = self.0.split_at(n);
        self.0 = tail;
        Ok(head)
    }

    fn array<const N: usize>(&mut self) -> CoreResult<[u8; N]> {
        Ok(self.take(N)?.try_into().expect("exact length"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> Invite {
        let mut identity_key = [3u8; 33];
        identity_key[0] = 0x05;
        Invite {
            identity_key,
            endpoint_id: [4; 32],
            token: [5; 32],
            addrs: vec![
                "192.168.0.12:41641".parse().unwrap(),
                "[fe80::1]:41641".parse().unwrap(),
            ],
        }
    }

    #[test]
    fn links_round_trip() {
        let invite = sample();
        let link = invite.to_link();
        assert!(link.starts_with(LINK_PREFIX));
        assert_eq!(Invite::from_link(&link).unwrap(), invite);
        // Colado com quebra de linha e espaço.
        let (a, b) = link.split_at(30);
        assert_eq!(Invite::from_link(&format!(" {a}\n{b} ")).unwrap(), invite);
    }

    #[test]
    fn the_link_is_short_enough_for_a_qr() {
        assert!(sample().to_link().len() < 300);
    }

    #[test]
    fn every_truncation_is_refused() {
        let bytes = sample().to_bytes();
        for cut in 0..bytes.len() {
            assert_eq!(
                Invite::from_bytes(&bytes[..cut]),
                Err(CoreError::InvalidInvite),
                "{cut}"
            );
        }
    }

    #[test]
    fn junk_is_refused() {
        let mut bytes = sample().to_bytes();
        bytes.push(0);
        assert_eq!(Invite::from_bytes(&bytes), Err(CoreError::InvalidInvite));
        let mut other_version = sample().to_bytes();
        other_version[0] = 2;
        assert_eq!(
            Invite::from_bytes(&other_version),
            Err(CoreError::InvalidInvite)
        );
        for bad in [
            "",
            "chirp://invite#",
            "https://example.org/#abc",
            "chirp://invite#!!!",
        ] {
            assert!(Invite::from_link(bad).is_err(), "{bad}");
        }
    }

    #[test]
    fn random_bytes_never_panic() {
        // Um fuzz pobre, até o cargo-fuzz entrar no CI.
        let mut state = 0x2545F491u32;
        for _ in 0..20_000 {
            let len = (state % 300) as usize;
            let bytes: Vec<u8> = (0..len)
                .map(|_| {
                    state ^= state << 13;
                    state ^= state >> 17;
                    state ^= state << 5;
                    state as u8
                })
                .collect();
            let _ = Invite::from_bytes(&bytes);
        }
    }
}

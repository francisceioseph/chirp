//! O código de ligação da caixa postal: o que o dono lê no app (QR ou link).
//!
//! ```text
//! versão (1, = 1) || nó (32) || código (32) ||
//! n (1, até 8) || n × [ 4 || IPv4 (4) || porta (2)  |  6 || IPv6 (16) || porta (2) ]
//! [ || m (1, de 1 a 200) || retransmissor (m, URL em UTF-8) ]
//! ```
//!
//! O link é `chirp://mailbox#` e os bytes em base64url sem preenchimento. O mesmo
//! formato dos endereços do convite. Qualquer byte fora do lugar recusa tudo.

use std::net::{IpAddr, Ipv4Addr, Ipv6Addr, SocketAddr};

use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use base64::Engine;

pub const LINK_PREFIX: &str = "chirp://mailbox#";
const VERSION: u8 = 1;
pub const MAX_ADDRS: usize = 8;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PairLink {
    pub endpoint_id: [u8; 32],
    pub token: [u8; 32],
    pub addrs: Vec<SocketAddr>,
    /// O retransmissor da caixa, se houver (quem lê confere a URL).
    pub relay: Option<String>,
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
#[error("código da caixa postal inválido")]
pub struct InvalidLink;

/// Os endereços no formato do convite.
pub fn write_addrs(out: &mut Vec<u8>, addrs: &[SocketAddr]) {
    let addrs = &addrs[..addrs.len().min(MAX_ADDRS)];
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
}

impl PairLink {
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(1 + 64 + 1 + self.addrs.len() * 19);
        out.push(VERSION);
        out.extend_from_slice(&self.endpoint_id);
        out.extend_from_slice(&self.token);
        write_addrs(&mut out, &self.addrs);
        if let Some(relay) = self
            .relay
            .as_deref()
            .filter(|r| (1..=200).contains(&r.len()))
        {
            out.push(relay.len() as u8);
            out.extend_from_slice(relay.as_bytes());
        }
        out
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, InvalidLink> {
        let mut r = Reader(bytes);
        if r.take(1)?[0] != VERSION {
            return Err(InvalidLink);
        }
        let endpoint_id = r.array()?;
        let token = r.array()?;
        let count = usize::from(r.take(1)?[0]);
        if count > MAX_ADDRS {
            return Err(InvalidLink);
        }
        let mut addrs = Vec::with_capacity(count);
        for _ in 0..count {
            let ip = match r.take(1)?[0] {
                4 => IpAddr::V4(Ipv4Addr::from(r.array::<4>()?)),
                6 => IpAddr::V6(Ipv6Addr::from(r.array::<16>()?)),
                _ => return Err(InvalidLink),
            };
            let port = u16::from_be_bytes(r.array()?);
            addrs.push(SocketAddr::new(ip, port));
        }
        let relay = if r.0.is_empty() {
            None
        } else {
            let len = usize::from(r.take(1)?[0]);
            let text = std::str::from_utf8(r.take(len)?)
                .map_err(|_| InvalidLink)?
                .to_owned();
            if len == 0 || !r.0.is_empty() {
                return Err(InvalidLink);
            }
            Some(text)
        };
        Ok(Self {
            endpoint_id,
            token,
            addrs,
            relay,
        })
    }

    pub fn to_link(&self) -> String {
        format!("{LINK_PREFIX}{}", URL_SAFE_NO_PAD.encode(self.to_bytes()))
    }

    /// Lê um link, tolerando espaços e quebras de linha de quem copiou de outro app.
    pub fn from_link(link: &str) -> Result<Self, InvalidLink> {
        let link: String = link.chars().filter(|c| !c.is_whitespace()).collect();
        let payload = link.strip_prefix(LINK_PREFIX).ok_or(InvalidLink)?;
        if payload.len() > 512 {
            return Err(InvalidLink);
        }
        let bytes = URL_SAFE_NO_PAD.decode(payload).map_err(|_| InvalidLink)?;
        Self::from_bytes(&bytes)
    }
}

struct Reader<'a>(&'a [u8]);

impl Reader<'_> {
    fn take(&mut self, n: usize) -> Result<&[u8], InvalidLink> {
        if self.0.len() < n {
            return Err(InvalidLink);
        }
        let (head, tail) = self.0.split_at(n);
        self.0 = tail;
        Ok(head)
    }

    fn array<const N: usize>(&mut self) -> Result<[u8; N], InvalidLink> {
        self.take(N)?.try_into().map_err(|_| InvalidLink)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> PairLink {
        PairLink {
            endpoint_id: [3; 32],
            token: [9; 32],
            addrs: vec![
                "192.168.0.10:47474".parse().unwrap(),
                "[2001:db8::1]:47474".parse().unwrap(),
            ],
            relay: Some("https://relay.example.org/".into()),
        }
    }

    #[test]
    fn the_link_goes_and_comes_back() {
        let link = sample();
        assert_eq!(PairLink::from_link(&link.to_link()), Ok(link.clone()));
        let spaced = link.to_link().replace('A', " A\n");
        assert_eq!(PairLink::from_link(&spaced), Ok(link));
        let bare = PairLink {
            relay: None,
            addrs: vec![],
            ..sample()
        };
        assert_eq!(PairLink::from_link(&bare.to_link()), Ok(bare));
    }

    #[test]
    fn every_truncation_and_extra_byte_is_refused() {
        let bytes = sample().to_bytes();
        for cut in 0..bytes.len() {
            // Cortar bem no fim dos endereços deixa um link válido sem o retransmissor.
            let short = PairLink::from_bytes(&bytes[..cut]);
            if let Ok(link) = short {
                assert_eq!(link.relay, None);
            }
        }
        let mut longer = bytes.clone();
        longer.push(0);
        assert_eq!(PairLink::from_bytes(&longer), Err(InvalidLink));
        let mut other = bytes;
        other[0] = 2;
        assert_eq!(PairLink::from_bytes(&other), Err(InvalidLink));
        assert_eq!(PairLink::from_link("chirp://invite#AAAA"), Err(InvalidLink));
    }
}

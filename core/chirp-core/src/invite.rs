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
//!
//! Com um retransmissor (fase 5), vem depois dos endereços `m (1) || URL (m)`, com
//! 1 ≤ m ≤ 200. Sem ele, o convite é o mesmo de antes.
//!
//! Com uma caixa postal que publicou as prekeys do convite (fase 7), vem por último
//! `0xFF || nó da caixa (32) || n (1) || n × endereço || r (1, até 200) ||
//! retransmissor da caixa (r)`. O 0xFF não confunde com o tamanho de um retransmissor
//! (até 200). Quem lê e não acha quem convidou busca as prekeys na caixa.

use std::net::{IpAddr, Ipv4Addr, Ipv6Addr, SocketAddr};

use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use base64::Engine;

use crate::error::{CoreError, CoreResult};

pub const LINK_PREFIX: &str = "chirp://invite#";
const VERSION: u8 = 1;
const MAX_ADDRS: usize = 8;
/// O começo da parte da caixa postal.
const MAILBOX_MARK: u8 = 0xFF;

/// A caixa postal de quem convida, onde as prekeys do convite estão publicadas.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InviteMailbox {
    pub endpoint_id: [u8; 32],
    pub addrs: Vec<SocketAddr>,
    pub relay: Option<String>,
}

impl InviteMailbox {
    /// Os endereços como o nó usa: os IPs e o retransmissor.
    pub fn addr_strings(&self) -> Vec<String> {
        let mut out: Vec<String> = self.addrs.iter().map(|a| a.to_string()).collect();
        out.extend(self.relay.clone());
        out
    }
}

fn write_addrs(out: &mut Vec<u8>, addrs: &[SocketAddr]) {
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

fn read_addrs(r: &mut Reader) -> CoreResult<Vec<SocketAddr>> {
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
    Ok(addrs)
}

fn read_relay(r: &mut Reader, len: usize) -> CoreResult<String> {
    let text = std::str::from_utf8(r.take(len)?)
        .map_err(|_| CoreError::InvalidInvite)?
        .to_owned();
    crate::network::relay_url(&text).map_err(|_| CoreError::InvalidInvite)
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Invite {
    pub identity_key: [u8; 33],
    pub endpoint_id: [u8; 32],
    pub token: [u8; 32],
    pub addrs: Vec<SocketAddr>,
    /// O retransmissor de quem convida, se houver.
    pub relay: Option<String>,
    /// A caixa postal com as prekeys deste convite, se houver.
    pub mailbox: Option<InviteMailbox>,
}

impl Invite {
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut out = Vec::with_capacity(1 + 33 + 32 + 32 + 1 + self.addrs.len() * 19);
        out.push(VERSION);
        out.extend_from_slice(&self.identity_key);
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
        if let Some(mailbox) = &self.mailbox {
            out.push(MAILBOX_MARK);
            out.extend_from_slice(&mailbox.endpoint_id);
            write_addrs(&mut out, &mailbox.addrs);
            let relay = mailbox
                .relay
                .as_deref()
                .filter(|r| r.len() <= 200)
                .unwrap_or_default();
            out.push(relay.len() as u8);
            out.extend_from_slice(relay.as_bytes());
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
        let addrs = read_addrs(&mut r)?;
        let relay = match r.0.first() {
            None | Some(&MAILBOX_MARK) => None,
            Some(_) => {
                let len = usize::from(r.take(1)?[0]);
                if len == 0 {
                    return Err(CoreError::InvalidInvite);
                }
                Some(read_relay(&mut r, len)?)
            }
        };
        let mailbox = if r.0.is_empty() {
            None
        } else {
            if r.take(1)?[0] != MAILBOX_MARK {
                return Err(CoreError::InvalidInvite);
            }
            let endpoint_id = r.array()?;
            let addrs = read_addrs(&mut r)?;
            let len = usize::from(r.take(1)?[0]);
            let relay = match len {
                0 => None,
                201.. => return Err(CoreError::InvalidInvite),
                len => Some(read_relay(&mut r, len)?),
            };
            Some(InviteMailbox {
                endpoint_id,
                addrs,
                relay,
            })
        };
        if !r.0.is_empty() {
            return Err(CoreError::InvalidInvite);
        }
        Ok(Self {
            identity_key,
            endpoint_id,
            token,
            addrs,
            relay,
            mailbox,
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
        if payload.len() > 1024 {
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
            relay: None,
            mailbox: None,
        }
    }

    fn with_mailbox() -> Invite {
        Invite {
            mailbox: Some(InviteMailbox {
                endpoint_id: [6; 32],
                addrs: vec!["203.0.113.7:47474".parse().unwrap()],
                relay: Some("https://relay.example.org/".into()),
            }),
            ..with_relay()
        }
    }

    #[test]
    fn the_mailbox_rides_last_with_or_without_a_relay() {
        let invite = with_mailbox();
        assert_eq!(Invite::from_link(&invite.to_link()).unwrap(), invite);
        assert!(invite.to_link().len() < 500);
        let bare = Invite {
            relay: None,
            mailbox: Some(InviteMailbox {
                relay: None,
                addrs: vec![],
                ..with_mailbox().mailbox.unwrap()
            }),
            ..sample()
        };
        assert_eq!(Invite::from_bytes(&bare.to_bytes()).unwrap(), bare);
        let plain = with_relay().to_bytes();
        let bytes = invite.to_bytes();
        assert_eq!(&bytes[..plain.len()], plain.as_slice());
        for cut in plain.len() + 1..bytes.len() {
            assert_eq!(
                Invite::from_bytes(&bytes[..cut]),
                Err(CoreError::InvalidInvite),
                "{cut}"
            );
        }
        let mut longer = bytes.clone();
        longer.push(0);
        assert_eq!(Invite::from_bytes(&longer), Err(CoreError::InvalidInvite));
    }

    fn with_relay() -> Invite {
        Invite {
            relay: Some("https://relay.example.org/".into()),
            ..sample()
        }
    }

    #[test]
    fn the_relay_rides_at_the_end() {
        let invite = with_relay();
        assert_eq!(Invite::from_link(&invite.to_link()).unwrap(), invite);
        assert!(invite.to_link().len() < 300);
        // Sem retransmissor, os bytes são os de sempre.
        let plain = sample().to_bytes();
        assert_eq!(&invite.to_bytes()[..plain.len()], plain.as_slice());
    }

    #[test]
    fn a_bad_relay_spoils_the_invite() {
        let mut bytes = sample().to_bytes();
        bytes.push(3);
        bytes.extend_from_slice(b"ftp");
        assert_eq!(Invite::from_bytes(&bytes), Err(CoreError::InvalidInvite));
        let bytes = with_relay().to_bytes();
        for cut in sample().to_bytes().len() + 1..bytes.len() {
            assert_eq!(
                Invite::from_bytes(&bytes[..cut]),
                Err(CoreError::InvalidInvite),
                "{cut}"
            );
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

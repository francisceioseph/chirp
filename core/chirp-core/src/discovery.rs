//! A descoberta na rede local por mDNS/DNS-SD (docs/PLANO.md, 7.2): reencontrar um
//! contato quando o IP dele muda.
//!
//! O anúncio (`_chirp._udp.local.`) **não leva id fixo nem nome**: o nome da instância
//! (e o do host) é um token de época, `HMAC-SHA256(chave de descoberta, época)`
//! truncado, que muda a cada 15 minutos. Cada contato recebeu a chave de descoberta
//! pelo canal cifrado e calcula o token esperado; quem não é contato vê um número
//! aleatório que muda. Os endereços anunciados são só os da rede local.
//!
//! O anúncio não é autenticado: qualquer um na rede pode repetir um token visto. Ele
//! só diz "tente este endereço"; a conexão confere a chave do nó, e um endereço falso
//! dá numa conexão que falha.

use std::net::{IpAddr, SocketAddr};

use hmac::{Hmac, KeyInit, Mac};
use sha2::Sha256;

/// O tipo do serviço.
pub const SERVICE: &str = "_chirp._udp.local.";
/// Quanto dura uma época.
pub const EPOCH_SECS: u64 = 15 * 60;
/// Quantos bytes do HMAC vão no token (em hex, o dobro de caracteres).
const TOKEN_BYTES: usize = 10;

pub fn epoch(now_secs: u64) -> u64 {
    now_secs / EPOCH_SECS
}

/// O token de uma chave de descoberta numa época.
pub fn token(discovery_key: &[u8], epoch: u64) -> String {
    let mut mac =
        Hmac::<Sha256>::new_from_slice(discovery_key).expect("HMAC takes keys of any size");
    mac.update(b"chirp-discovery-v1");
    mac.update(&epoch.to_be_bytes());
    let bytes = mac.finalize().into_bytes();
    bytes[..TOKEN_BYTES]
        .iter()
        .map(|b| format!("{b:02x}"))
        .collect()
}

/// O nome da instância de um nome completo do mDNS (`<token>._chirp._udp.local.`).
pub fn instance(fullname: &str) -> Option<&str> {
    let name = fullname.strip_suffix(SERVICE)?.strip_suffix('.')?;
    (name.len() == TOKEN_BYTES * 2 && name.bytes().all(|b| b.is_ascii_hexdigit())).then_some(name)
}

/// O contato dono do token, entre os que têm a chave de descoberta conhecida. Vale a
/// época de agora e as vizinhas, pela diferença dos relógios.
pub fn owner<'a>(
    contacts: impl IntoIterator<Item = (i64, &'a [u8])>,
    found: &str,
    now_secs: u64,
) -> Option<i64> {
    let now = epoch(now_secs);
    contacts.into_iter().find_map(|(id, key)| {
        (key.len() == 32
            && [now.saturating_sub(1), now, now + 1]
                .iter()
                .any(|e| token(key, *e) == found))
        .then_some(id)
    })
}

/// Os endereços anunciados que servem: os da rede local, com a porta do anúncio. O
/// loopback de outro aparelho apontaria para este. No máximo 8.
pub fn usable(ips: impl IntoIterator<Item = IpAddr>, port: u16) -> Vec<SocketAddr> {
    let mut addrs: Vec<SocketAddr> = ips
        .into_iter()
        .map(|ip| SocketAddr::new(ip, port))
        .filter(|a| port != 0 && crate::node::is_local(a))
        .collect();
    addrs.sort();
    addrs.dedup();
    addrs.truncate(8);
    addrs
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_token_changes_every_epoch_and_with_the_key() {
        let key = [7u8; 32];
        let now = 1_700_000_000;
        let a = token(&key, epoch(now));
        assert_eq!(a.len(), TOKEN_BYTES * 2);
        assert_eq!(a, token(&key, epoch(now + 1)));
        assert_ne!(a, token(&key, epoch(now + EPOCH_SECS)));
        assert_ne!(a, token(&[8u8; 32], epoch(now)));
        // Vetores fixos (calculados à parte), para outra implementação conferir.
        assert_eq!(token(&[0u8; 32], 0), "a9b1226a9e540fb5b7bb");
        assert_eq!(token(&[7u8; 32], 1_888_888), "1583b99009cc653054cc");
    }

    #[test]
    fn a_contact_is_found_by_its_token_in_nearby_epochs() {
        let (alice, bob) = ([1u8; 32], [2u8; 32]);
        let contacts = [(10, &alice[..]), (20, &bob[..])];
        let now = 1_700_000_000;
        assert_eq!(owner(contacts, &token(&bob, epoch(now)), now), Some(20));
        // O relógio do outro aparelho está uma época atrás ou à frente.
        assert_eq!(
            owner(contacts, &token(&alice, epoch(now) - 1), now),
            Some(10)
        );
        assert_eq!(
            owner(contacts, &token(&alice, epoch(now) + 1), now),
            Some(10)
        );
        // Duas épocas longe já não vale, e um estranho não é ninguém.
        assert_eq!(owner(contacts, &token(&alice, epoch(now) + 2), now), None);
        assert_eq!(owner(contacts, &token(&[3u8; 32], epoch(now)), now), None);
        // Um contato pendente (sem chave ainda) não casa com nada.
        assert_eq!(owner([(30, &[][..])], &token(&[], epoch(now)), now), None);
    }

    #[test]
    fn only_well_formed_instances_are_read() {
        let t = token(&[1u8; 32], 5);
        assert_eq!(instance(&format!("{t}.{SERVICE}")), Some(t.as_str()));
        assert_eq!(instance(&format!("printer.{SERVICE}")), None);
        assert_eq!(instance(&format!("{t}._http._tcp.local.")), None);
        assert_eq!(instance(SERVICE), None);
    }

    #[test]
    fn only_local_addresses_are_kept() {
        let ips: Vec<IpAddr> = ["192.168.0.5", "8.8.8.8", "127.0.0.1", "fd00::1", "2804::1"]
            .iter()
            .map(|s| s.parse().unwrap())
            .collect();
        let kept: Vec<String> = usable(ips.clone(), 4000)
            .iter()
            .map(|a| a.to_string())
            .collect();
        assert_eq!(kept, ["192.168.0.5:4000", "[fd00::1]:4000"]);
        assert!(usable(ips, 0).is_empty());
    }
}

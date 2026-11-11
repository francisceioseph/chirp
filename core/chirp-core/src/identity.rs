//! A identidade do aparelho: um par Curve25519, gerado na primeira abertura e guardado
//! só no banco cifrado (docs/PLANO.md, 6.1).
//!
//! É o mesmo formato da `IdentityKeyPair` do libsignal (32 bytes de segredo; a chave
//! pública com o byte de tipo `0x05` na frente), para a sessão da fase 2 usar esta
//! chave sem trocar a identidade de ninguém, seja qual for a biblioteca escolhida.

use sha2::{Digest, Sha512};
use x25519_dalek::{PublicKey, StaticSecret};
use zeroize::Zeroizing;

use crate::error::{CoreError, CoreResult};
use crate::random::secret_bytes;

/// O byte de tipo das chaves Curve25519 no libsignal.
const DJB_TYPE: u8 = 0x05;

/// Quantas vezes o hash da impressão digital é repetido (o mesmo do Signal).
const FINGERPRINT_ITERATIONS: usize = 5200;

pub struct Identity {
    secret: Zeroizing<[u8; 32]>,
}

impl Identity {
    pub fn generate() -> CoreResult<Self> {
        Ok(Self {
            secret: secret_bytes::<32>()?,
        })
    }

    #[cfg_attr(not(test), allow(dead_code))]
    pub fn from_secret(bytes: &[u8]) -> CoreResult<Self> {
        let secret: [u8; 32] = bytes.try_into().map_err(|_| CoreError::Storage)?;
        Ok(Self {
            secret: Zeroizing::new(secret),
        })
    }

    pub fn secret(&self) -> &[u8; 32] {
        &self.secret
    }

    /// A chave pública no formato do libsignal: `0x05` e os 32 bytes.
    pub fn public_key(&self) -> [u8; 33] {
        let secret = StaticSecret::from(*self.secret);
        let public = PublicKey::from(&secret);
        let mut out = [0u8; 33];
        out[0] = DJB_TYPE;
        out[1..].copy_from_slice(public.as_bytes());
        out
    }
}

/// A impressão digital de uma chave pública: 30 dígitos em 6 grupos de 5, como a
/// metade de um número de segurança do Signal. O número de segurança de uma conversa
/// (fase 2) junta a de cada lado.
pub fn fingerprint(public_key: &[u8]) -> String {
    let digest = fingerprint_digest(public_key);
    digest[..30]
        .chunks(5)
        .map(|chunk| {
            let value = chunk.iter().fold(0u64, |acc, &b| (acc << 8) | u64::from(b));
            format!("{:05}", value % 100_000)
        })
        .collect::<Vec<_>>()
        .join(" ")
}

/// Uma semente para o avatar gerado: a mesma chave dá sempre o mesmo desenho.
pub fn avatar_seed(public_key: &[u8]) -> u32 {
    let digest = fingerprint_digest(public_key);
    u32::from_be_bytes([digest[30], digest[31], digest[32], digest[33]])
}

fn fingerprint_digest(public_key: &[u8]) -> [u8; 64] {
    // Versão 0 do formato, a chave e o identificador estável (aqui, a própria chave);
    // depois, `hash || chave` repetido.
    let mut hasher = Sha512::new();
    hasher.update([0u8, 0u8]);
    hasher.update(public_key);
    hasher.update(public_key);
    let mut hash: [u8; 64] = hasher.finalize().into();
    for _ in 1..FINGERPRINT_ITERATIONS {
        let mut hasher = Sha512::new();
        hasher.update(hash);
        hasher.update(public_key);
        hash = hasher.finalize().into();
    }
    hash
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_new_identity_is_random_and_typed() {
        let a = Identity::generate().unwrap();
        let b = Identity::generate().unwrap();
        assert_ne!(a.secret(), b.secret());
        assert_eq!(a.public_key()[0], DJB_TYPE);
    }

    #[test]
    fn the_public_key_comes_back_from_the_secret() {
        let a = Identity::generate().unwrap();
        let again = Identity::from_secret(a.secret()).unwrap();
        assert_eq!(a.public_key(), again.public_key());
    }

    #[test]
    fn a_secret_of_the_wrong_size_is_refused() {
        assert!(Identity::from_secret(&[1, 2, 3]).is_err());
    }

    #[test]
    fn the_fingerprint_is_thirty_digits_and_stable() {
        let key = Identity::generate().unwrap().public_key();
        let print = fingerprint(&key);
        assert_eq!(print.len(), 35);
        assert_eq!(print.split(' ').count(), 6);
        assert!(print.chars().all(|c| c.is_ascii_digit() || c == ' '));
        assert_eq!(print, fingerprint(&key));
        let other = Identity::generate().unwrap().public_key();
        assert_ne!(print, fingerprint(&other));
    }

    #[test]
    fn the_fingerprint_matches_the_vector() {
        // Vetor fixo, calculado à parte (Python e hashlib), para o formato não mudar
        // sem querer.
        let mut key = [0u8; 33];
        key[0] = DJB_TYPE;
        assert_eq!(fingerprint(&key), "31018 24249 17437 12865 63541 81219");
        assert_eq!(avatar_seed(&key), 2_035_543_011);
    }
}

//! A chave do banco a partir de uma senha, para quando o sistema não tem cofre (um
//! Linux sem Secret Service, por exemplo): Argon2id, e o sal num arquivo ao lado do
//! banco (docs/PLANO.md, 8). O sal não é segredo; a senha e a chave nunca vão ao disco.

use std::fs;
use std::path::Path;

use argon2::{Algorithm, Argon2, Params, Version};
use zeroize::Zeroizing;

use crate::error::{CoreError, CoreResult};
use crate::random::secret_bytes;

/// O mínimo de caracteres de uma senha.
pub const MIN_PASSPHRASE_CHARS: usize = 8;

/// A marca do arquivo do sal, com a versão dos parâmetros abaixo.
const MAGIC: &[u8; 8] = b"CHIRPKD1";
const SALT_LEN: usize = 16;

/// 64 MiB, 3 passadas, 1 faixa: acima do mínimo do OWASP, e ainda menos de um segundo
/// num celular comum. Mudar aqui pede outra versão do `MAGIC`.
fn kdf() -> Argon2<'static> {
    let params = Params::new(64 * 1024, 3, 1, Some(32)).expect("valid Argon2 parameters");
    Argon2::new(Algorithm::Argon2id, Version::V0x13, params)
}

pub fn check_strength(passphrase: &str) -> CoreResult<()> {
    if passphrase.chars().count() < MIN_PASSPHRASE_CHARS {
        return Err(CoreError::WeakPassphrase);
    }
    Ok(())
}

/// Cria um sal novo no arquivo e deriva a chave.
pub fn create(salt_path: &Path, passphrase: &str) -> CoreResult<Zeroizing<[u8; 32]>> {
    check_strength(passphrase)?;
    if salt_path.exists() {
        return Err(CoreError::AlreadyExists);
    }
    let salt = secret_bytes::<SALT_LEN>()?;
    let key = derive(passphrase, salt.as_ref())?;
    let mut file = Vec::with_capacity(MAGIC.len() + SALT_LEN);
    file.extend_from_slice(MAGIC);
    file.extend_from_slice(salt.as_ref());
    fs::write(salt_path, file)?;
    Ok(key)
}

/// Lê o sal do arquivo e deriva a chave. Uma senha errada dá uma chave errada, que o
/// banco recusa com `WrongKey`.
pub fn unlock(salt_path: &Path, passphrase: &str) -> CoreResult<Zeroizing<[u8; 32]>> {
    let file = fs::read(salt_path)?;
    if file.len() != MAGIC.len() + SALT_LEN || &file[..MAGIC.len()] != MAGIC {
        return Err(CoreError::Storage);
    }
    derive(passphrase, &file[MAGIC.len()..])
}

fn derive(passphrase: &str, salt: &[u8]) -> CoreResult<Zeroizing<[u8; 32]>> {
    let mut key = Zeroizing::new([0u8; 32]);
    kdf()
        .hash_password_into(passphrase.as_bytes(), salt, key.as_mut())
        .map_err(|_| CoreError::Storage)?;
    Ok(key)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_same_passphrase_gives_the_same_key() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("salt");
        let created = create(&path, "calopsita lutino").unwrap();
        let unlocked = unlock(&path, "calopsita lutino").unwrap();
        assert_eq!(*created, *unlocked);
        let wrong = unlock(&path, "calopsita arlequim").unwrap();
        assert_ne!(*created, *wrong);
    }

    #[test]
    fn a_short_passphrase_is_refused() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("salt");
        assert_eq!(create(&path, "curta"), Err(CoreError::WeakPassphrase));
        assert!(!path.exists());
    }

    #[test]
    fn the_salt_file_holds_no_key() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("salt");
        let key = create(&path, "calopsita lutino").unwrap();
        let file = fs::read(&path).unwrap();
        assert_eq!(file.len(), MAGIC.len() + SALT_LEN);
        assert!(!file.windows(4).any(|w| key.windows(4).any(|k| k == w)));
    }

    #[test]
    fn creating_twice_is_refused() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("salt");
        create(&path, "calopsita lutino").unwrap();
        assert_eq!(
            create(&path, "calopsita lutino"),
            Err(CoreError::AlreadyExists)
        );
    }
}

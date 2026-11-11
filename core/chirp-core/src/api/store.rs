//! O banco e o perfil, pela ponte. O Dart guarda a chave no cofre do sistema e a
//! entrega aqui; sem cofre, entrega a senha, e a chave é derivada aqui dentro.
//!
//! Os arquivos ficam na pasta que o Dart passa (a pasta de suporte do app):
//! `chirp.db`, o banco cifrado, e `chirp.salt`, só quando a chave vem de uma senha.

use std::path::{Path, PathBuf};
use std::sync::Mutex;

use flutter_rust_bridge::frb;
use zeroize::Zeroizing;

pub use crate::error::CoreError;
use crate::error::CoreResult;
use crate::identity::{avatar_seed, fingerprint};
use crate::passphrase;
use crate::profile::StoredProfile;
use crate::random::secret_bytes;
use crate::store::Store;

const DB_FILE: &str = "chirp.db";
const SALT_FILE: &str = "chirp.salt";
/// O que o SQLite pode deixar ao lado do banco.
const DB_SIDE_FILES: &[&str] = &["chirp.db-journal", "chirp.db-wal", "chirp.db-shm"];

/// Como abrir o banco desta pasta.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StoreState {
    /// Ainda não existe: é a primeira abertura.
    Missing,
    /// A chave está no cofre do sistema.
    KeyInVault,
    /// A chave vem de uma senha.
    Passphrase,
}

/// O perfil como a UI mostra.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Profile {
    pub display_name: String,
    pub version: u32,
    /// A impressão digital da identidade: 30 dígitos em 6 grupos de 5.
    pub fingerprint: String,
    /// A semente do avatar gerado.
    pub avatar_seed: u32,
}

impl From<StoredProfile> for Profile {
    fn from(stored: StoredProfile) -> Self {
        Self {
            fingerprint: fingerprint(&stored.public_key),
            avatar_seed: avatar_seed(&stored.public_key),
            display_name: stored.display_name,
            version: stored.version,
        }
    }
}

#[frb(sync)]
pub fn store_state(dir: String) -> StoreState {
    let dir = PathBuf::from(dir);
    if !dir.join(DB_FILE).exists() {
        StoreState::Missing
    } else if dir.join(SALT_FILE).exists() {
        StoreState::Passphrase
    } else {
        StoreState::KeyInVault
    }
}

/// Uma chave nova para o banco, para o Dart guardar no cofre.
#[frb(sync)]
pub fn new_store_key() -> Result<Vec<u8>, CoreError> {
    Ok(secret_bytes::<32>()?.to_vec())
}

#[frb(sync)]
pub fn min_passphrase_chars() -> u32 {
    passphrase::MIN_PASSPHRASE_CHARS as u32
}

/// Apaga o banco e o sal. Sem a chave (que o Dart tira do cofre), o que sobrar no
/// disco não se lê.
pub fn wipe_store(dir: String) -> Result<(), CoreError> {
    let dir = PathBuf::from(dir);
    for name in [DB_FILE, SALT_FILE].iter().chain(DB_SIDE_FILES) {
        match std::fs::remove_file(dir.join(name)) {
            Ok(()) => {}
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
            Err(e) => return Err(e.into()),
        }
    }
    Ok(())
}

/// O banco aberto. Um de cada vez: a trava serializa quem chama.
#[frb(opaque)]
pub struct ChirpStore {
    inner: Mutex<Store>,
}

impl ChirpStore {
    /// Abre (ou cria) com a chave do cofre.
    pub fn open_with_key(dir: String, key: Vec<u8>) -> Result<ChirpStore, CoreError> {
        let key = Zeroizing::new(key);
        let key: &[u8; 32] = key.as_slice().try_into().map_err(|_| CoreError::BadKey)?;
        Self::open(&PathBuf::from(dir), key)
    }

    /// Cria o banco protegido por uma senha, na primeira abertura sem cofre.
    pub fn create_with_passphrase(
        dir: String,
        passphrase: String,
    ) -> Result<ChirpStore, CoreError> {
        let passphrase = Zeroizing::new(passphrase);
        let dir = PathBuf::from(dir);
        if dir.join(DB_FILE).exists() {
            return Err(CoreError::AlreadyExists);
        }
        std::fs::create_dir_all(&dir)?;
        let salt = dir.join(SALT_FILE);
        let key = passphrase::create(&salt, &passphrase)?;
        Self::open(&dir, &key).inspect_err(|_| {
            let _ = std::fs::remove_file(&salt);
        })
    }

    /// Abre o banco protegido por senha. A senha errada dá `WrongKey`.
    pub fn open_with_passphrase(dir: String, passphrase: String) -> Result<ChirpStore, CoreError> {
        let passphrase = Zeroizing::new(passphrase);
        let dir = PathBuf::from(dir);
        if !dir.join(DB_FILE).exists() {
            return Err(CoreError::Storage);
        }
        let key = passphrase::unlock(&dir.join(SALT_FILE), &passphrase)?;
        Self::open(&dir, &key)
    }

    fn open(dir: &Path, key: &[u8; 32]) -> CoreResult<ChirpStore> {
        std::fs::create_dir_all(dir)?;
        Ok(ChirpStore {
            inner: Mutex::new(Store::open(&dir.join(DB_FILE), key)?),
        })
    }

    pub fn profile(&self) -> Result<Option<Profile>, CoreError> {
        Ok(self.lock()?.profile()?.map(Profile::from))
    }

    pub fn create_profile(&self, name: String) -> Result<Profile, CoreError> {
        Ok(self.lock()?.create_profile(&name)?.into())
    }

    pub fn rename(&self, name: String) -> Result<Profile, CoreError> {
        Ok(self.lock()?.rename(&name)?.into())
    }

    fn lock(&self) -> CoreResult<std::sync::MutexGuard<'_, Store>> {
        self.inner.lock().map_err(|_| CoreError::Storage)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn dir() -> (tempfile::TempDir, String) {
        let tmp = tempfile::tempdir().unwrap();
        let path = tmp.path().join("data").to_string_lossy().into_owned();
        (tmp, path)
    }

    #[test]
    fn the_vault_path_creates_and_reopens() {
        let (_tmp, dir) = dir();
        assert_eq!(store_state(dir.clone()), StoreState::Missing);
        let key = new_store_key().unwrap();
        let store = ChirpStore::open_with_key(dir.clone(), key.clone()).unwrap();
        let profile = store.create_profile("Lutino".into()).unwrap();
        drop(store);
        assert_eq!(store_state(dir.clone()), StoreState::KeyInVault);
        let store = ChirpStore::open_with_key(dir.clone(), key).unwrap();
        assert_eq!(store.profile().unwrap(), Some(profile));
        let other = new_store_key().unwrap();
        assert!(matches!(
            ChirpStore::open_with_key(dir, other),
            Err(CoreError::WrongKey)
        ));
    }

    #[test]
    fn a_short_key_is_refused() {
        let (_tmp, dir) = dir();
        assert!(matches!(
            ChirpStore::open_with_key(dir, vec![1; 16]),
            Err(CoreError::BadKey)
        ));
    }

    #[test]
    fn the_passphrase_path_creates_and_reopens() {
        let (_tmp, dir) = dir();
        let store =
            ChirpStore::create_with_passphrase(dir.clone(), "calopsita lutino".into()).unwrap();
        store.create_profile("Lutino".into()).unwrap();
        drop(store);
        assert_eq!(store_state(dir.clone()), StoreState::Passphrase);
        assert!(matches!(
            ChirpStore::open_with_passphrase(dir.clone(), "outra senha".into()),
            Err(CoreError::WrongKey)
        ));
        let store =
            ChirpStore::open_with_passphrase(dir.clone(), "calopsita lutino".into()).unwrap();
        assert_eq!(store.profile().unwrap().unwrap().display_name, "Lutino");
        assert!(matches!(
            ChirpStore::create_with_passphrase(dir, "calopsita lutino".into()),
            Err(CoreError::AlreadyExists)
        ));
    }

    #[test]
    fn a_weak_passphrase_leaves_nothing_behind() {
        let (_tmp, dir) = dir();
        std::fs::create_dir_all(&dir).unwrap();
        assert!(matches!(
            ChirpStore::create_with_passphrase(dir.clone(), "curta".into()),
            Err(CoreError::WeakPassphrase)
        ));
        assert_eq!(store_state(dir), StoreState::Missing);
    }

    #[test]
    fn wiping_removes_everything() {
        let (_tmp, dir) = dir();
        ChirpStore::create_with_passphrase(dir.clone(), "calopsita lutino".into())
            .unwrap()
            .create_profile("Lutino".into())
            .unwrap();
        wipe_store(dir.clone()).unwrap();
        assert_eq!(store_state(dir.clone()), StoreState::Missing);
        assert_eq!(std::fs::read_dir(&dir).unwrap().count(), 0);
        wipe_store(dir).unwrap();
    }
}

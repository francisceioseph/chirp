//! O banco e o perfil, pela ponte. O Dart guarda a chave no cofre do sistema e a
//! entrega aqui; sem cofre, entrega a senha, e a chave é derivada aqui dentro.
//!
//! Os arquivos ficam na pasta que o Dart passa (a pasta de suporte do app):
//! `chirp.db`, o banco cifrado, e `chirp.salt`, só quando a chave vem de uma senha.

use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock};

use flutter_rust_bridge::frb;
use zeroize::Zeroizing;

use crate::contacts::{Contact, ContactState};
pub use crate::error::CoreError;
use crate::error::CoreResult;
use crate::frb_generated::StreamSink;
use crate::identity::{avatar_seed, fingerprint};
use crate::invite::Invite;
use crate::node::{Node, NodeEvent};
use crate::passphrase;
use crate::profile::StoredProfile;
use crate::random::secret_bytes;
use crate::session::{self, InviteKind};
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

/// Um contato como a UI mostra.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ContactView {
    pub id: i64,
    pub display_name: String,
    pub avatar_seed: u32,
    /// O número de segurança foi conferido (QR frente a frente, ou marcado à mão).
    pub verified: bool,
    /// O aperto de mão fechou dos dois lados.
    pub established: bool,
}

impl From<Contact> for ContactView {
    fn from(contact: Contact) -> Self {
        Self {
            id: contact.id,
            avatar_seed: avatar_seed(&contact.identity_key),
            display_name: contact.display_name,
            verified: contact.verified,
            established: contact.state == ContactState::Established,
        }
    }
}

/// O runtime do tokio da rede, um por processo.
fn runtime() -> &'static tokio::runtime::Runtime {
    static RUNTIME: OnceLock<tokio::runtime::Runtime> = OnceLock::new();
    RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .build()
            .expect("the network runtime starts")
    })
}

/// O banco aberto, e o nó da rede depois do `start_network`. A trava serializa quem
/// chama.
#[frb(opaque)]
pub struct ChirpStore {
    inner: Arc<Mutex<Store>>,
    node: Mutex<Option<Arc<Node>>>,
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
            inner: Arc::new(Mutex::new(Store::open(&dir.join(DB_FILE), key)?)),
            node: Mutex::new(None),
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

    /// Liga o nó da rede local. Pede o perfil (a identidade); chamar de novo não faz
    /// nada.
    pub fn start_network(&self) -> Result<(), CoreError> {
        self.started().map(|_| ())
    }

    /// Desliga o nó (antes de apagar tudo, por exemplo).
    pub fn stop_network(&self) -> Result<(), CoreError> {
        let node = self.node.lock().map_err(|_| CoreError::Storage)?.take();
        if let Some(node) = node {
            runtime().block_on(node.close());
        }
        Ok(())
    }

    fn started(&self) -> CoreResult<Arc<Node>> {
        let mut slot = self.node.lock().map_err(|_| CoreError::Storage)?;
        if let Some(node) = slot.as_ref() {
            return Ok(node.clone());
        }
        if self.lock()?.profile()?.is_none() {
            return Err(CoreError::NoProfile);
        }
        let node = runtime().block_on(Node::start(self.inner.clone()))?;
        *slot = Some(node.clone());
        Ok(node)
    }

    /// Um convite novo, como link. [qr] diz se vai ser mostrado como QR (frente a
    /// frente: o contato nasce verificado) ou mandado como link.
    pub fn create_invite(&self, qr: bool) -> Result<String, CoreError> {
        let node = self.started()?;
        let kind = if qr { InviteKind::Qr } else { InviteKind::Link };
        Ok(runtime().block_on(node.create_invite(kind))?.to_link())
    }

    /// Lê um convite e faz o aperto de mão. [scanned]: veio de um QR lido frente a
    /// frente.
    pub fn add_contact(&self, link: String, scanned: bool) -> Result<ContactView, CoreError> {
        let invite = Invite::from_link(&link)?;
        let node = self.started()?;
        Ok(runtime().block_on(node.join(invite, scanned))?.into())
    }

    pub fn contacts(&self) -> Result<Vec<ContactView>, CoreError> {
        Ok(crate::contacts::list(self.lock()?.conn())?
            .into_iter()
            .map(ContactView::from)
            .collect())
    }

    /// O número de segurança com um contato: 60 dígitos, igual nos dois aparelhos.
    pub fn safety_number(&self, contact_id: i64) -> Result<String, CoreError> {
        let store = self.lock()?;
        let contact = crate::contacts::by_id(store.conn(), contact_id)?;
        let own = session::identity_pair(&store)?;
        session::safety_number(&own.identity_key().serialize(), &contact.identity_key)
    }

    pub fn set_verified(&self, contact_id: i64, verified: bool) -> Result<ContactView, CoreError> {
        Ok(crate::contacts::set_verified(self.lock()?.conn(), contact_id, verified)?.into())
    }

    /// Avisa a UI (com o id) quando um contato muda sem ela pedir: alguém leu um
    /// convite nosso, por exemplo.
    pub fn watch_contacts(&self, sink: StreamSink<i64>) -> Result<(), CoreError> {
        let mut events = self.started()?.subscribe();
        runtime().spawn(async move {
            loop {
                match events.recv().await {
                    Ok(NodeEvent::ContactChanged(id)) => {
                        if sink.add(id).is_err() {
                            break;
                        }
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {
                        // Perdeu eventos: um id inválido faz a UI reler a lista toda.
                        if sink.add(0).is_err() {
                            break;
                        }
                    }
                    Err(_) => break,
                }
            }
        });
        Ok(())
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

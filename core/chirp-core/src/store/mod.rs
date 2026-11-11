//! O ninho: o banco SQLCipher com tudo do aparelho (docs/PLANO.md, 8). Cifrado
//! inteiro, cabeçalho e índices inclusive; a chave de 32 bytes vem do cofre do sistema
//! ou de uma senha (`passphrase`), e nunca fica no disco.

pub(crate) mod migrations;

use std::path::Path;

use rusqlite::{Connection, OptionalExtension};
use zeroize::Zeroizing;

use crate::error::{CoreError, CoreResult};
use crate::identity::Identity;
use crate::profile::{validate_name, StoredProfile};

pub struct Store {
    conn: Connection,
}

impl Store {
    /// Abre o banco, ou cria se ainda não existe. Uma chave errada dá `WrongKey`.
    pub fn open(path: &Path, key: &[u8; 32]) -> CoreResult<Self> {
        let conn = Connection::open(path)?;
        let hex = Zeroizing::new(to_hex(key));
        let statement = Zeroizing::new(format!("PRAGMA key = \"x'{}'\";", hex.as_str()));
        conn.execute_batch(&statement)?;
        // A chave errada só aparece na primeira leitura.
        conn.query_row("SELECT count(*) FROM sqlite_master", [], |_| Ok(()))?;
        conn.execute_batch(
            "PRAGMA cipher_memory_security = ON;
             PRAGMA secure_delete = ON;
             PRAGMA foreign_keys = ON;
             PRAGMA temp_store = MEMORY;",
        )?;
        let mut store = Self { conn };
        migrations::run(&mut store.conn)?;
        Ok(store)
    }

    /// O perfil deste aparelho, se já foi criado.
    pub fn profile(&self) -> CoreResult<Option<StoredProfile>> {
        let row = self
            .conn
            .query_row(
                "SELECT p.display_name, p.version, i.public_key
                   FROM profile p, identity i
                  WHERE p.id = 1 AND i.id = 1",
                [],
                |row| {
                    Ok(StoredProfile {
                        display_name: row.get(0)?,
                        version: row.get(1)?,
                        public_key: row.get(2)?,
                    })
                },
            )
            .optional()?;
        Ok(row)
    }

    /// Cria a identidade e o perfil, juntos numa transação.
    pub fn create_profile(&mut self, name: &str) -> CoreResult<StoredProfile> {
        let name = validate_name(name)?;
        let identity = Identity::generate()?;
        let public_key = identity.public_key().to_vec();
        let tx = self.conn.transaction()?;
        let exists: bool = tx.query_row("SELECT EXISTS(SELECT 1 FROM identity)", [], |row| {
            row.get(0)
        })?;
        if exists {
            return Err(CoreError::AlreadyExists);
        }
        tx.execute(
            "INSERT INTO identity (id, secret, public_key) VALUES (1, ?1, ?2)",
            (identity.secret().as_slice(), &public_key),
        )?;
        tx.execute(
            "INSERT INTO profile (id, display_name, version) VALUES (1, ?1, 1)",
            [&name],
        )?;
        tx.commit()?;
        Ok(StoredProfile {
            display_name: name,
            version: 1,
            public_key,
        })
    }

    /// Troca o nome. A versão sobe, para os contatos saberem que mudou (fase 3).
    pub fn rename(&mut self, name: &str) -> CoreResult<StoredProfile> {
        let name = validate_name(name)?;
        let changed = self.conn.execute(
            "UPDATE profile SET display_name = ?1, version = version + 1 WHERE id = 1",
            [&name],
        )?;
        if changed == 0 {
            return Err(CoreError::Storage);
        }
        self.profile()?.ok_or(CoreError::Storage)
    }

    pub(crate) fn conn(&self) -> &Connection {
        &self.conn
    }

    pub(crate) fn conn_mut(&mut self) -> &mut Connection {
        &mut self.conn
    }

    /// Um banco na memória, cifrado do mesmo jeito, para os testes.
    #[cfg(test)]
    pub(crate) fn memory() -> Self {
        Self::open(Path::new(":memory:"), &[9; 32]).unwrap()
    }

    /// A identidade guardada.
    pub fn identity(&self) -> CoreResult<Option<Identity>> {
        let secret: Option<Zeroizing<Vec<u8>>> = self
            .conn
            .query_row("SELECT secret FROM identity WHERE id = 1", [], |row| {
                row.get::<_, Vec<u8>>(0).map(Zeroizing::new)
            })
            .optional()?;
        secret.map(|s| Identity::from_secret(&s)).transpose()
    }
}

fn to_hex(bytes: &[u8]) -> String {
    const DIGITS: &[u8; 16] = b"0123456789abcdef";
    let mut out = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        out.push(DIGITS[usize::from(b >> 4)] as char);
        out.push(DIGITS[usize::from(b & 0x0f)] as char);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn key(byte: u8) -> [u8; 32] {
        [byte; 32]
    }

    #[test]
    fn the_profile_survives_closing_and_opening() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("chirp.db");
        let created = {
            let mut store = Store::open(&path, &key(7)).unwrap();
            assert!(store.profile().unwrap().is_none());
            store.create_profile("  Lutino  ").unwrap()
        };
        assert_eq!(created.display_name, "Lutino");
        let store = Store::open(&path, &key(7)).unwrap();
        assert_eq!(store.profile().unwrap(), Some(created.clone()));
        let identity = store.identity().unwrap().unwrap();
        assert_eq!(identity.public_key().to_vec(), created.public_key);
    }

    #[test]
    fn a_wrong_key_does_not_open() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("chirp.db");
        Store::open(&path, &key(7))
            .unwrap()
            .create_profile("Lutino")
            .unwrap();
        assert!(matches!(
            Store::open(&path, &key(8)),
            Err(CoreError::WrongKey)
        ));
    }

    #[test]
    fn a_second_profile_is_refused() {
        let dir = tempfile::tempdir().unwrap();
        let mut store = Store::open(&dir.path().join("chirp.db"), &key(1)).unwrap();
        store.create_profile("Lutino").unwrap();
        assert_eq!(
            store.create_profile("Arlequim"),
            Err(CoreError::AlreadyExists)
        );
    }

    #[test]
    fn renaming_bumps_the_version() {
        let dir = tempfile::tempdir().unwrap();
        let mut store = Store::open(&dir.path().join("chirp.db"), &key(1)).unwrap();
        let first = store.create_profile("Lutino").unwrap();
        let renamed = store.rename("Arlequim").unwrap();
        assert_eq!(renamed.display_name, "Arlequim");
        assert_eq!(renamed.version, 2);
        assert_eq!(renamed.public_key, first.public_key);
        assert_eq!(store.rename(""), Err(CoreError::InvalidName));
    }

    #[test]
    fn the_file_has_no_plain_text() {
        // A saída da fase 1: abrir o arquivo do banco e não achar nada legível.
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("chirp.db");
        let name = "Calopsita Lutino de Teste";
        let public_key = {
            let mut store = Store::open(&path, &key(42)).unwrap();
            let profile = store.create_profile(name).unwrap();
            store.rename(name).unwrap();
            profile.public_key
        };
        let mut bytes = Vec::new();
        for entry in std::fs::read_dir(dir.path()).unwrap() {
            bytes.extend(std::fs::read(entry.unwrap().path()).unwrap());
        }
        assert!(!bytes.is_empty());
        let contains = |needle: &[u8]| bytes.windows(needle.len()).any(|w| w == needle);
        assert!(!contains(name.as_bytes()));
        assert!(!contains(b"Calopsita"));
        assert!(!contains(b"SQLite format 3"));
        assert!(!contains(b"CREATE TABLE"));
        assert!(!contains(b"display_name"));
        assert!(!contains(&public_key[1..9]));
        assert!(!contains(&key(42)[..8]));
    }

    #[test]
    fn hex_is_lowercase_and_complete() {
        assert_eq!(to_hex(&[0x00, 0xab, 0x0f, 0xf0]), "00ab0ff0");
    }
}

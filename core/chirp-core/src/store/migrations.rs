//! As migrações do banco, pela `user_version` do SQLite. Cada entrada é uma versão, e
//! nunca muda depois de publicada: o que mudar vira a próxima.

use rusqlite::Connection;

use crate::error::{CoreError, CoreResult};

const MIGRATIONS: &[&str] = &[
    // 1: a identidade do aparelho e o perfil (fase 1).
    "CREATE TABLE identity (
         id         INTEGER PRIMARY KEY CHECK (id = 1),
         secret     BLOB NOT NULL,
         public_key BLOB NOT NULL
     );
     CREATE TABLE profile (
         id           INTEGER PRIMARY KEY CHECK (id = 1) REFERENCES identity (id),
         display_name TEXT NOT NULL,
         version      INTEGER NOT NULL
     );",
    // 2: as chaves do Signal, os contatos e os convites (fase 2).
    "CREATE TABLE local_keys (
         id              INTEGER PRIMARY KEY CHECK (id = 1),
         registration_id INTEGER NOT NULL,
         endpoint_secret BLOB NOT NULL,
         discovery_key   BLOB NOT NULL
     );
     CREATE TABLE prekeys (
         id     INTEGER PRIMARY KEY,
         record BLOB NOT NULL
     );
     CREATE TABLE signed_prekeys (
         id     INTEGER PRIMARY KEY,
         record BLOB NOT NULL
     );
     CREATE TABLE kyber_prekeys (
         id     INTEGER PRIMARY KEY,
         record BLOB NOT NULL
     );
     CREATE TABLE identities (
         address      TEXT PRIMARY KEY,
         identity_key BLOB NOT NULL
     );
     CREATE TABLE sessions (
         address TEXT PRIMARY KEY,
         record  BLOB NOT NULL
     );
     CREATE TABLE invites (
         token_hash      BLOB PRIMARY KEY,
         kind            INTEGER NOT NULL,
         expires_at      INTEGER NOT NULL,
         prekey_id       INTEGER NOT NULL,
         signed_prekey_id INTEGER NOT NULL,
         kyber_prekey_id INTEGER NOT NULL,
         used            INTEGER NOT NULL DEFAULT 0
     );
     CREATE TABLE contacts (
         id              INTEGER PRIMARY KEY,
         identity_key    BLOB NOT NULL UNIQUE,
         endpoint_id     BLOB NOT NULL,
         addrs           TEXT NOT NULL,
         discovery_key   BLOB NOT NULL,
         display_name    TEXT NOT NULL,
         profile_version INTEGER NOT NULL,
         verified        INTEGER NOT NULL,
         state           INTEGER NOT NULL,
         created_at      INTEGER NOT NULL
     );",
];

pub fn run(conn: &mut Connection) -> CoreResult<()> {
    let current: i64 = conn.query_row("PRAGMA user_version", [], |row| row.get(0))?;
    if current < 0 || current as usize > MIGRATIONS.len() {
        return Err(CoreError::NewerStore);
    }
    for (index, sql) in MIGRATIONS.iter().enumerate().skip(current as usize) {
        let tx = conn.transaction()?;
        tx.execute_batch(sql)?;
        tx.pragma_update(None, "user_version", (index + 1) as i64)?;
        tx.commit()?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn running_twice_changes_nothing() {
        let mut conn = Connection::open_in_memory().unwrap();
        run(&mut conn).unwrap();
        run(&mut conn).unwrap();
        let version: i64 = conn
            .query_row("PRAGMA user_version", [], |row| row.get(0))
            .unwrap();
        assert_eq!(version as usize, MIGRATIONS.len());
    }

    #[test]
    fn a_newer_store_is_refused() {
        let mut conn = Connection::open_in_memory().unwrap();
        conn.pragma_update(None, "user_version", MIGRATIONS.len() as i64 + 1)
            .unwrap();
        assert_eq!(run(&mut conn), Err(CoreError::NewerStore));
    }
}

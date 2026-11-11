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

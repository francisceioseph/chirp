//! Os contatos (docs/PLANO.md, 6.1 e 11.1). Um contato nasce só de um aperto de mão:
//! sem pedido aceito não existe contato.
//!
//! Estados: `Pending` (lemos o convite e mandamos o Hello; falta o Welcome) e
//! `Established` (a sessão fechou nos dois lados). "Verificado" é à parte: nasce
//! verdadeiro quando o convite veio por QR, frente a frente, e a pessoa pode marcar
//! depois de comparar o número de segurança.

use rusqlite::{Connection, OptionalExtension, Row};

use crate::error::{CoreError, CoreResult};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ContactState {
    Pending = 0,
    Established = 1,
}

impl ContactState {
    fn from_i64(value: i64) -> CoreResult<Self> {
        match value {
            0 => Ok(Self::Pending),
            1 => Ok(Self::Established),
            _ => Err(CoreError::Storage),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Contact {
    pub id: i64,
    pub identity_key: Vec<u8>,
    pub endpoint_id: Vec<u8>,
    pub addrs: Vec<String>,
    pub discovery_key: Vec<u8>,
    pub display_name: String,
    pub profile_version: u32,
    pub verified: bool,
    pub state: ContactState,
}

/// O que se grava de um contato novo.
pub struct NewContact<'a> {
    pub identity_key: &'a [u8],
    pub endpoint_id: &'a [u8],
    pub addrs: &'a [String],
    pub discovery_key: &'a [u8],
    pub display_name: &'a str,
    pub profile_version: u32,
    pub verified: bool,
    pub state: ContactState,
}

const COLUMNS: &str = "id, identity_key, endpoint_id, addrs, discovery_key, display_name, \
                       profile_version, verified, state";

fn from_row(row: &Row) -> rusqlite::Result<(Contact, i64)> {
    let addrs: String = row.get(3)?;
    Ok((
        Contact {
            id: row.get(0)?,
            identity_key: row.get(1)?,
            endpoint_id: row.get(2)?,
            addrs: addrs
                .split('\n')
                .filter(|a| !a.is_empty())
                .map(str::to_owned)
                .collect(),
            discovery_key: row.get(4)?,
            display_name: row.get(5)?,
            profile_version: row.get(6)?,
            verified: row.get(7)?,
            state: ContactState::Pending,
        },
        row.get(8)?,
    ))
}

fn finish(pair: (Contact, i64)) -> CoreResult<Contact> {
    let (mut contact, state) = pair;
    contact.state = ContactState::from_i64(state)?;
    Ok(contact)
}

pub fn insert(conn: &Connection, new: &NewContact, now: u64) -> CoreResult<Contact> {
    conn.execute(
        "INSERT INTO contacts (identity_key, endpoint_id, addrs, discovery_key, display_name,
                               profile_version, verified, state, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
        (
            new.identity_key,
            new.endpoint_id,
            new.addrs.join("\n"),
            new.discovery_key,
            new.display_name,
            new.profile_version,
            new.verified,
            new.state as i64,
            now as i64,
        ),
    )
    .map_err(|e| match e.sqlite_error_code() {
        Some(rusqlite::ErrorCode::ConstraintViolation) => CoreError::AlreadyExists,
        _ => CoreError::Storage,
    })?;
    by_id(conn, conn.last_insert_rowid())
}

pub fn by_id(conn: &Connection, id: i64) -> CoreResult<Contact> {
    let row = conn
        .query_row(
            &format!("SELECT {COLUMNS} FROM contacts WHERE id = ?1"),
            [id],
            from_row,
        )
        .optional()?;
    finish(row.ok_or(CoreError::UnknownContact)?)
}

pub fn by_identity(conn: &Connection, identity_key: &[u8]) -> CoreResult<Option<Contact>> {
    conn.query_row(
        &format!("SELECT {COLUMNS} FROM contacts WHERE identity_key = ?1"),
        [identity_key],
        from_row,
    )
    .optional()?
    .map(finish)
    .transpose()
}

pub fn list(conn: &Connection) -> CoreResult<Vec<Contact>> {
    let mut stmt = conn.prepare(&format!(
        "SELECT {COLUMNS} FROM contacts ORDER BY display_name COLLATE NOCASE, id"
    ))?;
    let rows = stmt.query_map([], from_row)?;
    rows.map(|r| finish(r?)).collect()
}

/// O Welcome chegou: o contato fica estabelecido, com o perfil e o endereço dele.
pub fn establish(
    conn: &Connection,
    id: i64,
    display_name: &str,
    profile_version: u32,
    addrs: &[String],
    discovery_key: &[u8],
) -> CoreResult<Contact> {
    conn.execute(
        "UPDATE contacts SET state = ?2, display_name = ?3, profile_version = ?4, addrs = ?5,
                             discovery_key = ?6
         WHERE id = ?1",
        (
            id,
            ContactState::Established as i64,
            display_name,
            profile_version,
            addrs.join("\n"),
            discovery_key,
        ),
    )?;
    by_id(conn, id)
}

pub fn set_verified(conn: &Connection, id: i64, verified: bool) -> CoreResult<Contact> {
    let changed = conn.execute(
        "UPDATE contacts SET verified = ?2 WHERE id = ?1",
        (id, verified),
    )?;
    if changed == 0 {
        return Err(CoreError::UnknownContact);
    }
    by_id(conn, id)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::store::Store;

    fn new<'a>(key: &'a [u8], addrs: &'a [String]) -> NewContact<'a> {
        NewContact {
            identity_key: key,
            endpoint_id: &[2; 32],
            addrs,
            discovery_key: &[3; 32],
            display_name: "Arlequim",
            profile_version: 1,
            verified: true,
            state: ContactState::Pending,
        }
    }

    #[test]
    fn contacts_round_trip() {
        let store = Store::memory();
        let addrs = vec!["192.168.0.2:1".to_owned(), "[fe80::1]:2".to_owned()];
        let a = insert(store.conn(), &new(&[1; 33], &addrs), 10).unwrap();
        assert_eq!(a.addrs, addrs);
        assert_eq!(a.state, ContactState::Pending);
        assert_eq!(
            by_identity(store.conn(), &[1; 33]).unwrap(),
            Some(a.clone())
        );
        assert_eq!(by_identity(store.conn(), &[9; 33]).unwrap(), None);
        let b = establish(store.conn(), a.id, "Pérola", 2, &[], &[4; 32]).unwrap();
        assert_eq!(b.state, ContactState::Established);
        assert_eq!(b.display_name, "Pérola");
        assert!(b.addrs.is_empty());
        let c = set_verified(store.conn(), a.id, false).unwrap();
        assert!(!c.verified);
        assert_eq!(list(store.conn()).unwrap(), vec![c]);
    }

    #[test]
    fn the_same_identity_twice_is_refused() {
        let store = Store::memory();
        insert(store.conn(), &new(&[1; 33], &[]), 10).unwrap();
        assert_eq!(
            insert(store.conn(), &new(&[1; 33], &[]), 11),
            Err(CoreError::AlreadyExists)
        );
        assert_eq!(
            set_verified(store.conn(), 99, true),
            Err(CoreError::UnknownContact)
        );
    }
}

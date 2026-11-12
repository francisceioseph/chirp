//! A caixa postal (fase 7, docs/PROTOCOLO.md, "A caixa postal"): um servidor de quem
//! usa (o `chirp-mailbox`), ligado a este aparelho por um código de uso único, que
//! guarda o que os contatos não conseguiram entregar direto.
//!
//! Cada contato recebe, pela sessão, onde fica a caixa e uma ficha só dele. A caixa
//! guarda só o SHA-256 das fichas, e o envelope que ela guarda é o mesmo frame que iria
//! direto, já cifrado pela sessão do Signal: ela não lê nada, e não tem como fingir ser
//! um contato (o que não decifra com a sessão dele é jogado fora).
//!
//! Aqui fica o lado do banco; a rede é do `node`.

use rusqlite::{Connection, OptionalExtension};
use sha2::{Digest, Sha256};

use crate::contacts::{self, Contact};
use crate::error::{CoreError, CoreResult};
use crate::random::secret_bytes;

pub use chirp_mailbox::link::PairLink;
pub use chirp_mailbox::proto;

/// A caixa deste aparelho.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Paired {
    pub endpoint_id: [u8; 32],
    /// Os IPs e, por último, o retransmissor dela.
    pub addrs: Vec<String>,
    /// Em segundos desde 1970.
    pub paired_at: i64,
    pub last_fetch: i64,
    /// O resumo das fichas que a caixa tem (o `digest`), ou nada.
    pub synced: Option<Vec<u8>>,
}

/// A caixa de um contato, com a ficha que ele nos deu.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Theirs {
    pub endpoint_id: [u8; 32],
    pub addrs: Vec<String>,
    pub drop: [u8; 32],
}

fn lines(text: String) -> Vec<String> {
    text.lines()
        .filter(|l| !l.is_empty())
        .map(str::to_owned)
        .collect()
}

/// Os endereços de um código de ligação, como o nó guarda: os IPs e o retransmissor
/// (conferido).
pub fn link_addrs(link: &PairLink) -> Vec<String> {
    let mut addrs: Vec<String> = link.addrs.iter().map(|a| a.to_string()).collect();
    addrs.extend(
        link.relay
            .as_deref()
            .and_then(|r| crate::network::relay_url(r).ok()),
    );
    crate::network::clean_addrs(addrs)
}

pub fn get(conn: &Connection) -> CoreResult<Option<Paired>> {
    conn.query_row(
        "SELECT endpoint_id, addrs, paired_at, last_fetch, synced FROM mailbox WHERE id = 1",
        [],
        |r| {
            let id: Vec<u8> = r.get(0)?;
            Ok((id, r.get(1)?, r.get(2)?, r.get(3)?, r.get(4)?))
        },
    )
    .optional()?
    .map(|(id, addrs, paired_at, last_fetch, synced)| {
        Ok(Paired {
            endpoint_id: id.as_slice().try_into().map_err(|_| CoreError::Storage)?,
            addrs: lines(addrs),
            paired_at,
            last_fetch,
            synced,
        })
    })
    .transpose()
}

/// A caixa nova, no lugar da que houver.
pub fn set(
    conn: &Connection,
    endpoint_id: &[u8; 32],
    addrs: &[String],
    now: i64,
) -> CoreResult<()> {
    conn.execute(
        "INSERT OR REPLACE INTO mailbox (id, endpoint_id, addrs, paired_at, last_fetch, synced)
         VALUES (1, ?1, ?2, ?3, 0, NULL)",
        (endpoint_id.as_slice(), addrs.join("\n"), now),
    )?;
    Ok(())
}

pub fn clear(conn: &Connection) -> CoreResult<()> {
    conn.execute("DELETE FROM mailbox", [])?;
    Ok(())
}

pub fn set_synced(conn: &Connection, digest: &[u8]) -> CoreResult<()> {
    conn.execute("UPDATE mailbox SET synced = ?1 WHERE id = 1", [digest])?;
    Ok(())
}

pub fn set_last_fetch(conn: &Connection, now: i64) -> CoreResult<()> {
    conn.execute("UPDATE mailbox SET last_fetch = ?1 WHERE id = 1", [now])?;
    Ok(())
}

/// A ficha que já foi dada ao contato (no Hello, antes de ele ser estabelecido).
pub fn set_drop_token(conn: &Connection, contact_id: i64, token: &[u8; 32]) -> CoreResult<()> {
    conn.execute(
        "UPDATE contacts SET drop_token = ?2, drop_hash = ?3 WHERE id = ?1",
        (contact_id, token.as_slice(), proto::hash(token).as_slice()),
    )?;
    Ok(())
}

/// A ficha do contato, criada na primeira vez.
pub fn drop_token(conn: &Connection, contact_id: i64) -> CoreResult<[u8; 32]> {
    let known: Option<Vec<u8>> = conn.query_row(
        "SELECT drop_token FROM contacts WHERE id = ?1",
        [contact_id],
        |r| r.get(0),
    )?;
    if let Some(token) = known.and_then(|t| <[u8; 32]>::try_from(t.as_slice()).ok()) {
        return Ok(token);
    }
    let token = *secret_bytes::<32>()?;
    conn.execute(
        "UPDATE contacts SET drop_token = ?2, drop_hash = ?3 WHERE id = ?1",
        (contact_id, token.as_slice(), proto::hash(&token).as_slice()),
    )?;
    Ok(token)
}

/// O SHA-256 das fichas dos contatos (os pendentes também, pelo Welcome): o que a
/// caixa deve aceitar.
pub fn drops(conn: &Connection) -> CoreResult<Vec<Vec<u8>>> {
    let mut stmt = conn
        .prepare("SELECT drop_hash FROM contacts WHERE drop_hash IS NOT NULL ORDER BY drop_hash")?;
    let rows = stmt.query_map([], |r| r.get(0))?;
    let mut hashes: Vec<Vec<u8>> = rows.collect::<rusqlite::Result<_>>()?;
    hashes.truncate(proto::MAX_DROPS);
    Ok(hashes)
}

/// Um resumo das fichas, para só mandar à caixa quando mudam.
pub fn digest(hashes: &[Vec<u8>]) -> Vec<u8> {
    let mut sha = Sha256::new();
    for hash in hashes {
        sha.update(hash);
    }
    sha.finalize().to_vec()
}

/// O contato a quem demos a ficha com esse SHA-256.
pub fn contact_by_drop(conn: &Connection, hash: &[u8]) -> CoreResult<Option<Contact>> {
    let id: Option<i64> = conn
        .query_row(
            "SELECT id FROM contacts WHERE drop_hash = ?1",
            [hash],
            |r| r.get(0),
        )
        .optional()?;
    id.map(|id| contacts::by_id(conn, id)).transpose()
}

/// A caixa de que o contato soube por último (o nó dela), ou nada.
pub fn told(conn: &Connection, contact_id: i64) -> CoreResult<Option<Vec<u8>>> {
    Ok(conn.query_row(
        "SELECT mailbox_told FROM contacts WHERE id = ?1",
        [contact_id],
        |r| r.get(0),
    )?)
}

pub fn set_told(conn: &Connection, contact_id: i64, endpoint_id: Option<&[u8]>) -> CoreResult<()> {
    conn.execute(
        "UPDATE contacts SET mailbox_told = ?2 WHERE id = ?1",
        (contact_id, endpoint_id),
    )?;
    Ok(())
}

pub fn theirs(conn: &Connection, contact_id: i64) -> CoreResult<Option<Theirs>> {
    let row: (Option<Vec<u8>>, String, Option<Vec<u8>>) = conn.query_row(
        "SELECT their_mailbox, their_mailbox_addrs, their_drop FROM contacts WHERE id = ?1",
        [contact_id],
        |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
    )?;
    let (Some(id), addrs, Some(drop)) = row else {
        return Ok(None);
    };
    let (Ok(endpoint_id), Ok(drop)) = (id.as_slice().try_into(), drop.as_slice().try_into()) else {
        return Ok(None);
    };
    Ok(Some(Theirs {
        endpoint_id,
        addrs: lines(addrs),
        drop,
    }))
}

/// A caixa que veio num `MailboxInfo`: `Ok(None)` quando veio vazio (desligada), e
/// `Err` quando está fora do formato.
pub fn theirs_from_info(info: crate::wire::MailboxInfo) -> Result<Option<Theirs>, ()> {
    match (
        <[u8; 32]>::try_from(info.endpoint_id.as_slice()),
        <[u8; 32]>::try_from(info.drop.as_slice()),
    ) {
        (Ok(endpoint_id), Ok(drop)) => Ok(Some(Theirs {
            endpoint_id,
            addrs: crate::network::clean_addrs(info.addrs),
            drop,
        })),
        _ if info.endpoint_id.is_empty() => Ok(None),
        _ => Err(()),
    }
}

/// A caixa que o contato mandou (ou a falta dela). Devolve se mudou.
pub fn set_theirs(conn: &Connection, contact_id: i64, theirs: Option<&Theirs>) -> CoreResult<bool> {
    if self::theirs(conn, contact_id)?.as_ref() == theirs {
        return Ok(false);
    }
    match theirs {
        Some(t) => conn.execute(
            "UPDATE contacts SET their_mailbox = ?2, their_mailbox_addrs = ?3, their_drop = ?4
              WHERE id = ?1",
            (
                contact_id,
                t.endpoint_id.as_slice(),
                t.addrs.join("\n"),
                t.drop.as_slice(),
            ),
        )?,
        None => conn.execute(
            "UPDATE contacts SET their_mailbox = NULL, their_mailbox_addrs = '', their_drop = NULL
              WHERE id = ?1",
            [contact_id],
        )?,
    };
    Ok(true)
}

/// O envelope ficou na caixa do contato: sai da caixa de saída, e a mensagem fica
/// "na caixa postal" até o recibo de que chegou. Devolve se alguma mensagem mudou.
pub fn deposited(conn: &Connection, outbox_id: i64) -> CoreResult<bool> {
    let row: Option<(i64, Vec<u8>)> = conn
        .query_row(
            "DELETE FROM outbox WHERE id = ?1 RETURNING contact_id, message_id",
            [outbox_id],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )
        .optional()?;
    let Some((contact_id, message_id)) = row else {
        return Ok(false);
    };
    let changed = conn.execute(
        "UPDATE messages SET in_mailbox = 1
          WHERE contact_id = ?1 AND message_id = ?2 AND outgoing = 1 AND status = 0",
        (contact_id, message_id),
    )?;
    Ok(changed > 0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::store::Store;

    #[test]
    fn the_mailbox_is_kept_replaced_and_cleared() {
        let store = Store::memory();
        let conn = store.conn();
        assert_eq!(get(conn).unwrap(), None);
        set(conn, &[1; 32], &["192.168.0.2:47474".into()], 10).unwrap();
        set_synced(conn, &[9]).unwrap();
        set(conn, &[2; 32], &[], 20).unwrap();
        let paired = get(conn).unwrap().unwrap();
        assert_eq!(paired.endpoint_id, [2; 32]);
        assert_eq!(paired.synced, None, "a caixa nova recebe as fichas de novo");
        clear(conn).unwrap();
        assert_eq!(get(conn).unwrap(), None);
    }

    #[test]
    fn the_digest_follows_the_set() {
        assert_eq!(digest(&[vec![1], vec![2]]), digest(&[vec![1], vec![2]]));
        assert_ne!(digest(&[vec![1]]), digest(&[vec![1], vec![2]]));
    }
}

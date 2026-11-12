//! Os grupos (fase 9, docs/PLANO.md 6.8).
//!
//! - **O grupo é uma conversa**: uma linha de `contacts` no estado `Group`, com o id do
//!   grupo (16 bytes aleatórios) no lugar da chave de identidade. A lista de conversas,
//!   o histórico, a busca e a tela da conversa são os mesmos de um contato.
//! - **As mensagens vão a cada membro pela sessão a dois** (o *fan-out*), com o id do
//!   grupo no `Content.group`. Sem servidor, cada membro recebe a sua cópia de qualquer
//!   jeito: as Sender Keys do Signal só economizariam a cifra, e perderiam a recuperação
//!   do Double Ratchet depois de um vazamento. Quem sai deixa de receber, sem rotação.
//! - **O grupo muda só pelo admin**: o `GroupUpdate` leva o nome e todos os membros numa
//!   versão, e vale o que chega do admin com versão maior. Quem sai manda o
//!   `GroupLeave`; se era o admin, o novo é o membro com a menor chave de identidade,
//!   a mesma conta em todos os aparelhos.
//! - Hoje uma mensagem só chega aos membros que são contatos de quem manda; os outros
//!   aparecem no grupo como "sem conexão". Apresentar os membros entre si fica para a
//!   parte 2.

use rusqlite::{Connection, OptionalExtension};

use crate::contacts::{self, Contact, ContactState, NewContact};
use crate::error::{CoreError, CoreResult};
use crate::messages::{self, Effect, Kind, Status};
use crate::random::secret_bytes;
use crate::session::{self, Me};
use crate::store::Store;
use crate::wire::{self, Content, ContentBody, GroupMember};

pub const GROUP_ID_LEN: usize = 16;

/// Um membro guardado: a chave de identidade, o nó e o nome.
type Stored = (Vec<u8>, Vec<u8>, String);
/// Quantos membros, contando quem usa.
pub const MAX_MEMBERS: usize = 64;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Member {
    pub identity_key: Vec<u8>,
    pub endpoint_id: Vec<u8>,
    pub name: String,
    /// O contato, se é um (e só assim as mensagens chegam a ele).
    pub contact: Option<Contact>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Group {
    /// A linha de `contacts` (a conversa).
    pub id: i64,
    pub group_id: Vec<u8>,
    pub name: String,
    pub admin: Vec<u8>,
    pub version: u64,
    /// Ainda sou membro (não saí nem fui tirado).
    pub active: bool,
    /// Os outros membros, por nome.
    pub members: Vec<Member>,
    pub i_am_admin: bool,
}

struct Row {
    group_id: Vec<u8>,
    admin: Vec<u8>,
    version: u64,
    active: bool,
}

fn row(conn: &Connection, id: i64) -> CoreResult<Option<Row>> {
    Ok(conn
        .query_row(
            "SELECT group_id, admin, version, active FROM groups WHERE contact_id = ?1",
            [id],
            |r| {
                Ok(Row {
                    group_id: r.get(0)?,
                    admin: r.get(1)?,
                    version: r.get::<_, i64>(2)? as u64,
                    active: r.get(3)?,
                })
            },
        )
        .optional()?)
}

fn by_group_id(conn: &Connection, group_id: &[u8]) -> CoreResult<Option<i64>> {
    Ok(conn
        .query_row(
            "SELECT contact_id FROM groups WHERE group_id = ?1",
            [group_id],
            |r| r.get(0),
        )
        .optional()?)
}

/// Os membros guardados (sem mim): a chave, o nó e o nome.
fn stored_members(conn: &Connection, id: i64) -> CoreResult<Vec<Stored>> {
    let mut stmt = conn.prepare(
        "SELECT identity_key, endpoint_id, name FROM group_members
          WHERE group_ref = ?1 ORDER BY name, identity_key",
    )?;
    let rows = stmt.query_map([id], |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)))?;
    Ok(rows.collect::<rusqlite::Result<_>>()?)
}

fn established(conn: &Connection, identity_key: &[u8]) -> CoreResult<Option<Contact>> {
    Ok(contacts::by_identity(conn, identity_key)?.filter(|c| c.state == ContactState::Established))
}

/// O grupo da conversa `id`.
pub fn get(conn: &Connection, me_key: &[u8], id: i64) -> CoreResult<Group> {
    let contact = contacts::by_id(conn, id)?;
    let row = row(conn, id)?.ok_or(CoreError::UnknownContact)?;
    let mut members = Vec::new();
    for (identity_key, endpoint_id, name) in stored_members(conn, id)? {
        let contact = established(conn, &identity_key)?;
        members.push(Member {
            identity_key,
            endpoint_id,
            name,
            contact,
        });
    }
    Ok(Group {
        id,
        group_id: row.group_id,
        name: contact.display_name,
        i_am_admin: row.admin == me_key,
        admin: row.admin,
        version: row.version,
        active: row.active,
        members,
    })
}

/// Eu, como membro: a chave de identidade, o nó e o nome do perfil.
fn myself(store_conn: &Connection, me: &Me) -> CoreResult<GroupMember> {
    let keys = session::local_keys(store_conn)?;
    let endpoint = iroh::SecretKey::from_bytes(&keys.endpoint_secret).public();
    let name: String =
        store_conn.query_row("SELECT display_name FROM profile WHERE id = 1", [], |r| {
            r.get(0)
        })?;
    Ok(GroupMember {
        identity_key: me.public(),
        endpoint_id: endpoint.as_bytes().to_vec(),
        name,
    })
}

/// O grupo como vai no fio: todos os membros, comigo.
fn update_of(conn: &Connection, me: &Me, id: i64) -> CoreResult<wire::GroupUpdate> {
    let row = row(conn, id)?.ok_or(CoreError::UnknownContact)?;
    let name = contacts::by_id(conn, id)?.display_name;
    let mut members = vec![myself(conn, me)?];
    for (identity_key, endpoint_id, name) in stored_members(conn, id)? {
        members.push(GroupMember {
            identity_key,
            endpoint_id,
            name,
        });
    }
    Ok(wire::GroupUpdate {
        group_id: row.group_id,
        name,
        version: row.version,
        admin: row.admin,
        members,
    })
}

/// Cifra o conteúdo para cada um destes (os que são contatos), com o mesmo id no fio.
fn send_to(
    conn: &Connection,
    me: &Me,
    to: &[Vec<u8>],
    group: &[u8],
    body: ContentBody,
    lamport: i64,
    sent_at: i64,
) -> CoreResult<Vec<u8>> {
    let message_id = secret_bytes::<16>()?.to_vec();
    for identity_key in to {
        let Some(contact) = established(conn, identity_key)? else {
            continue;
        };
        let plain = Content {
            message_id: message_id.clone(),
            body: Some(body.clone()),
            sent_at: sent_at as u64,
            lamport: lamport as u64,
            padding: vec![],
            group: group.to_vec(),
        }
        .encode_padded();
        let (prekey, bytes) = session::encrypt(conn, me, &contact.identity_key, &plain)?;
        conn.execute(
            "INSERT INTO outbox (contact_id, message_id, prekey, ciphertext, ephemeral, created_at)
             VALUES (?1, ?2, ?3, ?4, 0, ?5)",
            (contact.id, &message_id, prekey, bytes, messages::now_ms()),
        )?;
    }
    Ok(message_id)
}

fn member_keys(conn: &Connection, id: i64) -> CoreResult<Vec<Vec<u8>>> {
    Ok(stored_members(conn, id)?
        .into_iter()
        .map(|(k, _, _)| k)
        .collect())
}

/// Manda o grupo de agora aos membros e a quem mais vier em `also` (quem saiu).
fn publish(conn: &Connection, me: &Me, id: i64, also: &[Vec<u8>]) -> CoreResult<()> {
    let update = update_of(conn, me, id)?;
    let mut to = member_keys(conn, id)?;
    to.extend(also.iter().cloned());
    send_to(
        conn,
        me,
        &to,
        &[],
        ContentBody::Group(update),
        0,
        messages::now_ms(),
    )?;
    Ok(())
}

/// Um grupo que eu administro e de que ainda sou membro.
fn mine(conn: &Connection, me: &Me, id: i64) -> CoreResult<Row> {
    let row = row(conn, id)?.ok_or(CoreError::UnknownContact)?;
    if !row.active || row.admin != me.public() {
        return Err(CoreError::NotAdmin);
    }
    Ok(row)
}

fn add_members(conn: &Connection, id: i64, contact_ids: &[i64]) -> CoreResult<()> {
    for contact_id in contact_ids {
        let contact = contacts::by_id(conn, *contact_id)?;
        if contact.state != ContactState::Established {
            return Err(CoreError::UnknownContact);
        }
        conn.execute(
            "INSERT OR IGNORE INTO group_members (group_ref, identity_key, endpoint_id, name)
             VALUES (?1, ?2, ?3, ?4)",
            (
                id,
                &contact.identity_key,
                &contact.endpoint_id,
                &contact.display_name,
            ),
        )?;
    }
    let count: i64 = conn.query_row(
        "SELECT count(*) FROM group_members WHERE group_ref = ?1",
        [id],
        |r| r.get(0),
    )?;
    if count as usize + 1 > MAX_MEMBERS {
        return Err(CoreError::TooManyMembers);
    }
    Ok(())
}

fn bump(conn: &Connection, id: i64) -> CoreResult<()> {
    conn.execute(
        "UPDATE groups SET version = version + 1 WHERE contact_id = ?1",
        [id],
    )?;
    Ok(())
}

/// Cria um grupo com estes contatos, comigo de admin, e manda a eles.
pub fn create(store: &mut Store, name: &str, contact_ids: &[i64]) -> CoreResult<Contact> {
    let name = crate::profile::validate_name(name)?;
    if contact_ids.is_empty() {
        return Err(CoreError::UnknownContact);
    }
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let group_id = secret_bytes::<GROUP_ID_LEN>()?.to_vec();
    let contact = contacts::insert(
        &tx,
        &NewContact {
            identity_key: &group_id,
            endpoint_id: &[],
            addrs: &[],
            discovery_key: &[],
            display_name: &name,
            profile_version: 0,
            verified: false,
            state: ContactState::Group,
        },
        (messages::now_ms() / 1000) as u64,
    )?;
    tx.execute(
        "INSERT INTO groups (contact_id, group_id, admin, version, active) VALUES (?1, ?2, ?3, 1, 1)",
        (contact.id, &group_id, me.public()),
    )?;
    add_members(&tx, contact.id, contact_ids)?;
    publish(&tx, &me, contact.id, &[])?;
    tx.commit()?;
    Ok(contact)
}

pub fn rename(store: &mut Store, id: i64, name: &str) -> CoreResult<()> {
    let name = crate::profile::validate_name(name)?;
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    mine(&tx, &me, id)?;
    tx.execute(
        "UPDATE contacts SET display_name = ?2 WHERE id = ?1",
        (id, &name),
    )?;
    bump(&tx, id)?;
    publish(&tx, &me, id, &[])?;
    tx.commit()?;
    Ok(())
}

pub fn add(store: &mut Store, id: i64, contact_ids: &[i64]) -> CoreResult<()> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    mine(&tx, &me, id)?;
    add_members(&tx, id, contact_ids)?;
    bump(&tx, id)?;
    publish(&tx, &me, id, &[])?;
    tx.commit()?;
    Ok(())
}

/// Tira um membro. Ele recebe o grupo sem ele, e assim fica sabendo.
pub fn remove(store: &mut Store, id: i64, identity_key: &[u8]) -> CoreResult<()> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    mine(&tx, &me, id)?;
    let changed = tx.execute(
        "DELETE FROM group_members WHERE group_ref = ?1 AND identity_key = ?2",
        (id, identity_key),
    )?;
    if changed == 0 {
        return Err(CoreError::UnknownContact);
    }
    bump(&tx, id)?;
    publish(&tx, &me, id, &[identity_key.to_vec()])?;
    tx.commit()?;
    Ok(())
}

/// Saio do grupo: aviso os membros, e a conversa fica só para ler.
pub fn leave(store: &mut Store, id: i64) -> CoreResult<()> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let row = row(&tx, id)?.ok_or(CoreError::UnknownContact)?;
    if row.active {
        let to = member_keys(&tx, id)?;
        send_to(
            &tx,
            &me,
            &to,
            &[],
            ContentBody::GroupLeave(wire::GroupLeave {
                group_id: row.group_id,
            }),
            0,
            messages::now_ms(),
        )?;
        tx.execute("UPDATE groups SET active = 0 WHERE contact_id = ?1", [id])?;
    }
    tx.commit()?;
    Ok(())
}

/// Uma conversa de grupo em que ainda posso escrever: os membros.
pub(crate) fn writable(conn: &Connection, id: i64) -> CoreResult<Option<Writable>> {
    let Some(row) = row(conn, id)? else {
        return Ok(None);
    };
    if !row.active {
        return Err(CoreError::NotAMember);
    }
    Ok(Some(Writable {
        group_id: row.group_id,
        members: member_keys(conn, id)?,
    }))
}

pub(crate) struct Writable {
    pub group_id: Vec<u8>,
    pub members: Vec<Vec<u8>>,
}

/// Manda um conteúdo da conversa do grupo a todos os membros (que são contatos).
pub(crate) fn fanout(
    conn: &Connection,
    me: &Me,
    group: &Writable,
    body: ContentBody,
    lamport: i64,
    sent_at: i64,
) -> CoreResult<Vec<u8>> {
    send_to(
        conn,
        me,
        &group.members,
        &group.group_id,
        body,
        lamport,
        sent_at,
    )
}

// ---------------------------------------------------------------- o que chega

fn valid_update(update: &wire::GroupUpdate) -> Option<Vec<Stored>> {
    if update.group_id.len() != GROUP_ID_LEN
        || update.members.len() > MAX_MEMBERS
        || update.version == 0
    {
        return None;
    }
    let mut out: Vec<Stored> = Vec::new();
    for m in &update.members {
        let name = crate::profile::validate_name(&m.name).ok()?;
        if m.identity_key.len() != 33
            || m.endpoint_id.len() != 32
            || out.iter().any(|(k, _, _)| *k == m.identity_key)
        {
            return None;
        }
        out.push((m.identity_key.clone(), m.endpoint_id.clone(), name));
    }
    out.iter()
        .any(|(k, _, _)| *k == update.admin)
        .then_some(out)
}

/// O grupo que um membro mandou. Vale só se quem manda é o admin (o de agora, ou o
/// do grupo novo) e a versão é maior que a guardada.
pub(crate) fn apply_update(
    conn: &Connection,
    me_key: &[u8],
    sender: &Contact,
    update: wire::GroupUpdate,
) -> CoreResult<Effect> {
    let Some(members) = valid_update(&update) else {
        return Ok(Effect::Nothing);
    };
    let Ok(name) = crate::profile::validate_name(&update.name) else {
        return Ok(Effect::Nothing);
    };
    if update.admin != sender.identity_key {
        return Ok(Effect::Nothing);
    }
    let in_it = members.iter().any(|(k, _, _)| k == me_key);
    let id = match by_group_id(conn, &update.group_id)? {
        Some(id) => {
            let row = row(conn, id)?.ok_or(CoreError::Storage)?;
            if row.admin != sender.identity_key || update.version <= row.version {
                return Ok(Effect::Nothing);
            }
            id
        }
        None => {
            // Um grupo novo só interessa se eu estou nele.
            if !in_it {
                return Ok(Effect::Nothing);
            }
            let contact = contacts::insert(
                conn,
                &NewContact {
                    identity_key: &update.group_id,
                    endpoint_id: &[],
                    addrs: &[],
                    discovery_key: &[],
                    display_name: &name,
                    profile_version: 0,
                    verified: false,
                    state: ContactState::Group,
                },
                (messages::now_ms() / 1000) as u64,
            )?;
            conn.execute(
                "INSERT INTO groups (contact_id, group_id, admin, version, active)
                 VALUES (?1, ?2, ?3, 0, 1)",
                (contact.id, &update.group_id, &update.admin),
            )?;
            contact.id
        }
    };
    conn.execute(
        "UPDATE contacts SET display_name = ?2 WHERE id = ?1",
        (id, &name),
    )?;
    conn.execute(
        "UPDATE groups SET admin = ?2, version = ?3, active = ?4 WHERE contact_id = ?1",
        (id, &update.admin, update.version as i64, in_it),
    )?;
    conn.execute("DELETE FROM group_members WHERE group_ref = ?1", [id])?;
    if in_it {
        for (identity_key, endpoint_id, name) in members.iter().filter(|(k, _, _)| k != me_key) {
            conn.execute(
                "INSERT INTO group_members (group_ref, identity_key, endpoint_id, name)
                 VALUES (?1, ?2, ?3, ?4)",
                (id, identity_key, endpoint_id, name),
            )?;
        }
    }
    Ok(Effect::Contact(id))
}

/// Um membro saiu. Se era o admin, o novo é o de menor chave (eu, talvez).
pub(crate) fn apply_leave(
    conn: &Connection,
    me_key: &[u8],
    sender: &Contact,
    leave: wire::GroupLeave,
) -> CoreResult<Effect> {
    let Some(id) = by_group_id(conn, &leave.group_id)? else {
        return Ok(Effect::Nothing);
    };
    let changed = conn.execute(
        "DELETE FROM group_members WHERE group_ref = ?1 AND identity_key = ?2",
        (id, &sender.identity_key),
    )?;
    if changed == 0 {
        return Ok(Effect::Nothing);
    }
    let row = row(conn, id)?.ok_or(CoreError::Storage)?;
    if row.admin == sender.identity_key {
        let mut keys = member_keys(conn, id)?;
        keys.push(me_key.to_vec());
        if let Some(next) = keys.into_iter().min() {
            conn.execute(
                "UPDATE groups SET admin = ?2 WHERE contact_id = ?1",
                (id, next),
            )?;
        }
    }
    Ok(Effect::Contact(id))
}

/// Uma mensagem da conversa de um grupo, de um membro que é contato: texto, editar e
/// apagar. O resto (reações, arquivos, atenção) fica para depois, e é ignorado.
pub(crate) fn apply_message(
    conn: &Connection,
    sender: &Contact,
    content: Content,
) -> CoreResult<Effect> {
    let Some(id) = by_group_id(conn, &content.group)? else {
        return Ok(Effect::Nothing);
    };
    let member: bool = conn.query_row(
        "SELECT EXISTS (SELECT 1 FROM group_members WHERE group_ref = ?1 AND identity_key = ?2)
            AND (SELECT active FROM groups WHERE contact_id = ?1)",
        (id, &sender.identity_key),
        |r| r.get(0),
    )?;
    if !member {
        return Ok(Effect::Nothing);
    }
    let lamport = messages::advance_lamport(conn, id, content.lamport)?;
    let sent_at = content.sent_at.min(i64::MAX as u64) as i64;
    let author_target = |target: &[u8], window: i64| -> CoreResult<Option<i64>> {
        Ok(conn
            .query_row(
                "SELECT id, received_at FROM messages
                  WHERE contact_id = ?1 AND message_id = ?2 AND author = ?3
                    AND outgoing = 0 AND kind = 0 AND deleted = 0",
                (id, target, &sender.identity_key),
                |r| Ok((r.get::<_, i64>(0)?, r.get::<_, i64>(1)?)),
            )
            .optional()?
            .filter(|(_, at)| messages::now_ms() - at <= window + messages::SLACK_MS)
            .map(|(m, _)| m))
    };
    match content.body {
        Some(ContentBody::Text(text)) => {
            let Ok(body) = messages::valid_text(&text.text) else {
                return Ok(Effect::Nothing);
            };
            let reply = (text.reply_to.len() == 16).then_some(text.reply_to.as_slice());
            if let Some(row) = messages::insert(
                conn,
                id,
                &content.message_id,
                false,
                Kind::Text,
                &body,
                reply,
                sent_at,
                lamport,
                Status::Pending,
            )? {
                conn.execute(
                    "UPDATE messages SET author = ?2 WHERE id = ?1",
                    (row, &sender.identity_key),
                )?;
            }
        }
        Some(ContentBody::Edit(edit)) => {
            let (Some(target), Ok(text)) = (
                author_target(&edit.target, messages::EDIT_WINDOW_MS)?,
                messages::valid_text(&edit.text),
            ) else {
                return Ok(Effect::Nothing);
            };
            conn.execute(
                "UPDATE messages SET body = ?2, edited = 1 WHERE id = ?1",
                (target, text),
            )?;
        }
        Some(ContentBody::Delete(delete)) => {
            let Some(target) = author_target(&delete.target, messages::DELETE_WINDOW_MS)? else {
                return Ok(Effect::Nothing);
            };
            messages::wipe(conn, target)?;
        }
        _ => return Ok(Effect::Nothing),
    }
    Ok(Effect::Messages(id))
}

#[cfg(test)]
mod tests;

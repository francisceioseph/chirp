//! As mensagens 1:1 (docs/PLANO.md, 6.4 a 6.6 e 11.1).
//!
//! **Caixa de saída**: mandar é gravar a mensagem, cifrar e guardar o cifrado na
//! `outbox`, tudo numa transação só com o avanço do ratchet. A rede (o `node`) lê da
//! caixa e só apaga com o `Ack` do outro lado. Se o app cair no meio, nada se perde e
//! nenhuma chave é gasta à toa: o reenvio manda os mesmos bytes.
//!
//! **Caixa de entrada idempotente**: decifrar, aplicar e confirmar também vão numa
//! transação. Um reenvio do que já foi decifrado é reconhecido (o ratchet não aceita a
//! mesma chave duas vezes) e só ganha o `Ack` de novo. O que se decifra mas não se
//! aplica (fora do formato, fora do prazo) é descartado e confirmado, para não voltar.
//!
//! **Ordem**: um relógio de Lamport por conversa; o relógio de quem manda é só para
//! mostrar.

use std::time::{SystemTime, UNIX_EPOCH};

use prost::Message as _;
use rusqlite::{Connection, OptionalExtension, Row};

use crate::contacts::{self, Contact, ContactState};
use crate::error::{CoreError, CoreResult};
use crate::random::secret_bytes;
use crate::session::{self, Me};
use crate::store::Store;
use crate::wire::{self, Content, ContentBody};

/// O texto mais comprido que se manda, em caracteres.
pub const MAX_TEXT_CHARS: usize = 4000;
/// Editar vale por 15 minutos, como no WhatsApp.
pub const EDIT_WINDOW_MS: i64 = 15 * 60 * 1000;
/// Apagar para todos vale por um dia.
pub const DELETE_WINDOW_MS: i64 = 24 * 60 * 60 * 1000;
/// Quem recebe dá essa folga aos prazos, pela demora da entrega.
pub(crate) const SLACK_MS: i64 = 5 * 60 * 1000;
/// Chamar atenção: uma vez a cada 10 segundos por conversa, nos dois sentidos.
pub const NUDGE_INTERVAL_MS: i64 = 10 * 1000;
/// O "digitando" que não sai nesse tempo já não diz nada e é jogado fora.
pub const EPHEMERAL_TTL_MS: i64 = 10 * 1000;
/// Quantos ids cabem num recibo.
const MAX_RECEIPT_IDS: usize = 256;
/// O relógio de Lamport de um contato não pula mais que isso de uma vez.
const MAX_LAMPORT_JUMP: i64 = 1 << 32;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Text = 0,
    /// Chamou atenção.
    Nudge = 1,
    /// Um arquivo (o corpo é o nome; o resto está em `files`).
    File = 2,
}

/// Para as minhas: na fila, entregue, lida. Para as do contato: não lida, lida.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Pending = 0,
    Delivered = 1,
    Read = 2,
}

/// As reações são de um conjunto fixo (a UI desenha cada uma com um ícone); 0 é
/// nenhuma.
pub const REACTIONS: u32 = 6;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Message {
    pub id: i64,
    pub contact_id: i64,
    pub message_id: Vec<u8>,
    pub outgoing: bool,
    pub kind: Kind,
    pub body: String,
    /// A mensagem citada, se ela existe aqui.
    pub reply_to: Option<i64>,
    /// O relógio de quem mandou, em milissegundos.
    pub sent_at: i64,
    /// Quando chegou (ou foi escrita, se é minha), em milissegundos.
    pub received_at: i64,
    pub lamport: i64,
    pub status: Status,
    pub edited: bool,
    pub deleted: bool,
    pub my_reaction: u32,
    pub their_reaction: u32,
    /// Minha, e esperando na caixa postal do contato (fase 7) até ele buscar.
    pub in_mailbox: bool,
    /// Num grupo, a chave de identidade de quem escreveu (as minhas não têm).
    pub author: Option<Vec<u8>>,
}

/// O que mudou com o que chegou, para avisar a UI.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Effect {
    /// Nada para mostrar (repetido, descartado).
    Nothing,
    /// A conversa mudou.
    Messages(i64),
    /// O contato está digitando.
    Typing(i64),
    /// O contato mudou o perfil.
    Contact(i64),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Settings {
    pub read_receipts: bool,
    pub typing: bool,
}

pub fn now_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}

const SELECT: &str = "SELECT m.id, m.contact_id, m.message_id, m.outgoing, m.kind, m.body,
        (SELECT r.id FROM messages r
          WHERE r.contact_id = m.contact_id AND r.message_id = m.reply_to),
        m.sent_at, m.received_at, m.lamport, m.status, m.edited, m.deleted,
        COALESCE((SELECT kind FROM reactions WHERE message = m.id AND outgoing = 1), 0),
        COALESCE((SELECT kind FROM reactions WHERE message = m.id AND outgoing = 0), 0),
        m.in_mailbox, m.author
   FROM messages m";

fn from_row(row: &Row) -> rusqlite::Result<Message> {
    let kind: i64 = row.get(4)?;
    let status: i64 = row.get(10)?;
    Ok(Message {
        id: row.get(0)?,
        contact_id: row.get(1)?,
        message_id: row.get(2)?,
        outgoing: row.get(3)?,
        kind: match kind {
            1 => Kind::Nudge,
            2 => Kind::File,
            _ => Kind::Text,
        },
        body: row.get(5)?,
        reply_to: row.get(6)?,
        sent_at: row.get(7)?,
        received_at: row.get(8)?,
        lamport: row.get(9)?,
        status: match status {
            0 => Status::Pending,
            1 => Status::Delivered,
            _ => Status::Read,
        },
        edited: row.get(11)?,
        deleted: row.get(12)?,
        my_reaction: row.get(13)?,
        their_reaction: row.get(14)?,
        in_mailbox: row.get(15)?,
        author: row.get(16)?,
    })
}

pub fn by_id(conn: &Connection, id: i64) -> CoreResult<Message> {
    conn.query_row(&format!("{SELECT} WHERE m.id = ?1"), [id], from_row)
        .optional()?
        .ok_or(CoreError::UnknownMessage)
}

/// As últimas `limit` mensagens da conversa, em ordem, antes de `before` (o id de uma
/// mensagem) quando ele vem.
pub fn list(
    conn: &Connection,
    contact_id: i64,
    before: Option<i64>,
    limit: u32,
) -> CoreResult<Vec<Message>> {
    let cursor = match before {
        Some(id) => {
            let m = by_id(conn, id)?;
            (m.lamport, m.sent_at, m.id)
        }
        None => (i64::MAX, i64::MAX, i64::MAX),
    };
    let mut stmt = conn.prepare(&format!(
        "{SELECT} WHERE m.contact_id = ?1 AND (m.lamport, m.sent_at, m.id) < (?2, ?3, ?4)
          ORDER BY m.lamport DESC, m.sent_at DESC, m.id DESC LIMIT ?5"
    ))?;
    let mut rows = stmt
        .query_map(
            (contact_id, cursor.0, cursor.1, cursor.2, limit.min(500)),
            from_row,
        )?
        .collect::<rusqlite::Result<Vec<_>>>()?;
    rows.reverse();
    Ok(rows)
}

/// Uma conversa na lista: o contato, a última mensagem e quantas não foram lidas.
pub struct Conversation {
    pub contact: Contact,
    pub last: Option<Message>,
    pub unread: u32,
}

/// Todas as conversas, a mais recente primeiro; as sem mensagem vão no fim, por nome.
pub fn conversations(conn: &Connection) -> CoreResult<Vec<Conversation>> {
    let mut out = Vec::new();
    for contact in contacts::list(conn)? {
        // Entrou por um convite de grupo: o meu (repassado pelo admin) ou o de outro.
        let via_group: bool = conn.query_row(
            "SELECT c.via_group OR EXISTS (
                    SELECT 1 FROM group_intros_out o
                     WHERE o.member = c.identity_key AND c.created_at >= o.sent_at)
               FROM contacts c WHERE c.id = ?1",
            [contact.id],
            |r| r.get(0),
        )?;
        let last = conn
            .query_row(
                &format!(
                    "{SELECT} WHERE m.contact_id = ?1
                      ORDER BY m.lamport DESC, m.sent_at DESC, m.id DESC LIMIT 1"
                ),
                [contact.id],
                from_row,
            )
            .optional()?;
        let unread: u32 = conn.query_row(
            "SELECT count(*) FROM messages WHERE contact_id = ?1 AND outgoing = 0 AND status = 0",
            [contact.id],
            |r| r.get(0),
        )?;
        // Um contato que só existe por um grupo aparece quando alguém escreve a dois.
        if via_group && last.is_none() {
            continue;
        }
        out.push(Conversation {
            contact,
            last,
            unread,
        });
    }
    // A ordem estável do `contacts::list` (por nome) desempata.
    out.sort_by_key(|c| std::cmp::Reverse(c.last.as_ref().map(|m| m.received_at)));
    Ok(out)
}

/// A busca no histórico (FTS5). Cada palavra vale como começo de palavra, sem acento
/// nem caixa; os símbolos são ignorados, para a busca não virar sintaxe do FTS.
pub fn search(conn: &Connection, query: &str, limit: u32) -> CoreResult<Vec<Message>> {
    let terms: Vec<String> = query
        .split_whitespace()
        .map(|t| {
            t.chars()
                .filter(|c| c.is_alphanumeric())
                .collect::<String>()
        })
        .filter(|t| !t.is_empty())
        .take(16)
        .map(|t| format!("\"{t}\"*"))
        .collect();
    if terms.is_empty() {
        return Ok(vec![]);
    }
    let mut stmt = conn.prepare(&format!(
        "{SELECT} JOIN messages_fts f ON f.rowid = m.id
          WHERE messages_fts MATCH ?1 AND m.deleted = 0
          ORDER BY m.received_at DESC LIMIT ?2"
    ))?;
    let rows = stmt
        .query_map((terms.join(" "), limit.min(500)), from_row)?
        .collect::<rusqlite::Result<Vec<_>>>()?;
    Ok(rows)
}

pub fn settings(conn: &Connection) -> CoreResult<Settings> {
    Ok(conn.query_row(
        "SELECT read_receipts, typing FROM settings WHERE id = 1",
        [],
        |r| {
            Ok(Settings {
                read_receipts: r.get(0)?,
                typing: r.get(1)?,
            })
        },
    )?)
}

pub fn set_settings(conn: &Connection, settings: Settings) -> CoreResult<()> {
    conn.execute(
        "UPDATE settings SET read_receipts = ?1, typing = ?2 WHERE id = 1",
        (settings.read_receipts, settings.typing),
    )?;
    Ok(())
}

// ---------------------------------------------------------------- mandar

fn established(conn: &Connection, contact_id: i64) -> CoreResult<Contact> {
    let contact = contacts::by_id(conn, contact_id)?;
    if contact.state != ContactState::Established {
        return Err(CoreError::UnknownContact);
    }
    Ok(contact)
}

fn next_lamport(conn: &Connection, contact_id: i64) -> CoreResult<i64> {
    Ok(conn.query_row(
        "UPDATE contacts SET lamport = lamport + 1 WHERE id = ?1 RETURNING lamport",
        [contact_id],
        |r| r.get(0),
    )?)
}

/// Cifra e põe na caixa de saída. Devolve o id da mensagem no fio.
fn enqueue(
    conn: &Connection,
    me: &Me,
    contact: &Contact,
    body: ContentBody,
    lamport: i64,
    sent_at: i64,
    ephemeral: bool,
) -> CoreResult<Vec<u8>> {
    let message_id = secret_bytes::<16>()?.to_vec();
    let plain = Content {
        message_id: message_id.clone(),
        body: Some(body),
        sent_at: sent_at as u64,
        lamport: lamport as u64,
        padding: vec![],
        group: vec![],
    }
    .encode_padded();
    let (prekey, bytes) = session::encrypt(conn, me, &contact.identity_key, &plain)?;
    conn.execute(
        "INSERT INTO outbox (contact_id, message_id, prekey, ciphertext, ephemeral, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        (contact.id, &message_id, prekey, bytes, ephemeral, now_ms()),
    )?;
    Ok(message_id)
}

pub(crate) fn valid_text(text: &str) -> CoreResult<String> {
    // O fim de linha do Windows (e um `\r` solto) vira `\n`.
    let text = text.replace("\r\n", "\n").replace('\r', "\n");
    let trimmed = text.trim();
    if trimmed.is_empty()
        || trimmed.chars().count() > MAX_TEXT_CHARS
        || trimmed
            .chars()
            .any(|c| c.is_control() && c != '\n' && c != '\t')
    {
        return Err(CoreError::InvalidMessage);
    }
    Ok(trimmed.to_owned())
}

#[allow(clippy::too_many_arguments)]
pub(crate) fn insert(
    conn: &Connection,
    contact_id: i64,
    message_id: &[u8],
    outgoing: bool,
    kind: Kind,
    body: &str,
    reply_to: Option<&[u8]>,
    sent_at: i64,
    lamport: i64,
    status: Status,
) -> CoreResult<Option<i64>> {
    let changed = conn.execute(
        "INSERT OR IGNORE INTO messages (contact_id, message_id, outgoing, kind, body, reply_to,
                                         sent_at, received_at, lamport, status)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
        (
            contact_id,
            message_id,
            outgoing,
            kind as i64,
            body,
            reply_to,
            sent_at,
            now_ms(),
            lamport,
            status as i64,
        ),
    )?;
    Ok((changed > 0).then(|| conn.last_insert_rowid()))
}

/// Manda um texto, citando outra mensagem da conversa se `reply_to` vem.
pub fn send_text(
    store: &mut Store,
    contact_id: i64,
    text: &str,
    reply_to: Option<i64>,
) -> CoreResult<Message> {
    let text = valid_text(text)?;
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let group = crate::groups::writable(&tx, contact_id)?;
    let contact = match group {
        Some(_) => contacts::by_id(&tx, contact_id)?,
        None => established(&tx, contact_id)?,
    };
    let quoted = match reply_to {
        Some(id) => {
            let m = by_id(&tx, id)?;
            if m.contact_id != contact_id {
                return Err(CoreError::UnknownMessage);
            }
            m.message_id
        }
        None => vec![],
    };
    let lamport = next_lamport(&tx, contact_id)?;
    let sent_at = now_ms();
    let body = ContentBody::Text(wire::Text {
        text: text.clone(),
        reply_to: quoted.clone(),
    });
    let message_id = match &group {
        Some(group) => crate::groups::fanout(&tx, &me, group, body, lamport, sent_at)?,
        None => enqueue(&tx, &me, &contact, body, lamport, sent_at, false)?,
    };
    let id = insert(
        &tx,
        contact_id,
        &message_id,
        true,
        Kind::Text,
        &text,
        (!quoted.is_empty()).then_some(quoted.as_slice()),
        sent_at,
        lamport,
        Status::Pending,
    )?
    .ok_or(CoreError::Storage)?;
    let message = by_id(&tx, id)?;
    tx.commit()?;
    Ok(message)
}

/// Chama a atenção do contato. Uma vez a cada 10 segundos.
pub fn send_nudge(store: &mut Store, contact_id: i64) -> CoreResult<Message> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let contact = established(&tx, contact_id)?;
    let now = now_ms();
    let last: i64 = tx.query_row(
        "SELECT nudge_out_at FROM contacts WHERE id = ?1",
        [contact_id],
        |r| r.get(0),
    )?;
    if now - last < NUDGE_INTERVAL_MS && now >= last {
        return Err(CoreError::TooSoon);
    }
    tx.execute(
        "UPDATE contacts SET nudge_out_at = ?2 WHERE id = ?1",
        (contact_id, now),
    )?;
    let lamport = next_lamport(&tx, contact_id)?;
    let message_id = enqueue(
        &tx,
        &me,
        &contact,
        ContentBody::Nudge(wire::Nudge {}),
        lamport,
        now,
        false,
    )?;
    let id = insert(
        &tx,
        contact_id,
        &message_id,
        true,
        Kind::Nudge,
        "",
        None,
        now,
        lamport,
        Status::Pending,
    )?
    .ok_or(CoreError::Storage)?;
    let message = by_id(&tx, id)?;
    tx.commit()?;
    Ok(message)
}

/// Uma mensagem minha, de texto e não apagada, ainda no prazo.
/// Para quem vai o que muda numa mensagem minha: o contato, ou os membros do grupo.
enum Target {
    Contact(Contact),
    Group(i64, crate::groups::Writable),
}

impl Target {
    fn id(&self) -> i64 {
        match self {
            Target::Contact(c) => c.id,
            Target::Group(id, _) => *id,
        }
    }

    fn send(&self, conn: &Connection, me: &Me, body: ContentBody, lamport: i64) -> CoreResult<()> {
        match self {
            Target::Contact(contact) => {
                enqueue(conn, me, contact, body, lamport, now_ms(), false)?;
            }
            Target::Group(_, group) => {
                crate::groups::fanout(conn, me, group, body, lamport, now_ms())?;
            }
        }
        Ok(())
    }
}

fn target_of(conn: &Connection, contact_id: i64) -> CoreResult<Target> {
    Ok(match crate::groups::writable(conn, contact_id)? {
        Some(group) => Target::Group(contact_id, group),
        None => Target::Contact(established(conn, contact_id)?),
    })
}

fn own_in_window(conn: &Connection, id: i64, window: i64) -> CoreResult<(Message, Target)> {
    let message = by_id(conn, id)?;
    // Apagar vale para texto e arquivo; editar, só texto (o `edit` confere).
    if !message.outgoing || message.kind == Kind::Nudge || message.deleted {
        return Err(CoreError::UnknownMessage);
    }
    if now_ms() - message.received_at > window {
        return Err(CoreError::TooLate);
    }
    let target = target_of(conn, message.contact_id)?;
    Ok((message, target))
}

pub fn edit(store: &mut Store, id: i64, text: &str) -> CoreResult<Message> {
    let text = valid_text(text)?;
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let (message, target) = own_in_window(&tx, id, EDIT_WINDOW_MS)?;
    if message.kind != Kind::Text {
        return Err(CoreError::UnknownMessage);
    }
    if message.body == text {
        return Ok(message);
    }
    let lamport = next_lamport(&tx, target.id())?;
    target.send(
        &tx,
        &me,
        ContentBody::Edit(wire::Edit {
            target: message.message_id.clone(),
            text: text.clone(),
        }),
        lamport,
    )?;
    tx.execute(
        "UPDATE messages SET body = ?2, edited = 1 WHERE id = ?1",
        (id, &text),
    )?;
    let message = by_id(&tx, id)?;
    tx.commit()?;
    Ok(message)
}

pub(crate) fn wipe(conn: &Connection, id: i64) -> CoreResult<()> {
    conn.execute(
        "UPDATE messages SET body = '', reply_to = NULL, deleted = 1, edited = 0 WHERE id = ?1",
        [id],
    )?;
    conn.execute("DELETE FROM reactions WHERE message = ?1", [id])?;
    // O arquivo some junto; o blob sai na próxima varredura (`files::sweep`).
    conn.execute("DELETE FROM files WHERE message = ?1", [id])?;
    Ok(())
}

/// Apaga para todos: o texto sai do banco e da busca aqui e lá.
pub fn delete_for_everyone(store: &mut Store, id: i64) -> CoreResult<Message> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let (message, target) = own_in_window(&tx, id, DELETE_WINDOW_MS)?;
    let lamport = next_lamport(&tx, target.id())?;
    target.send(
        &tx,
        &me,
        ContentBody::Delete(wire::Delete {
            target: message.message_id.clone(),
        }),
        lamport,
    )?;
    wipe(&tx, id)?;
    let message = by_id(&tx, id)?;
    tx.commit()?;
    Ok(message)
}

/// Apaga só deste aparelho.
pub fn delete_for_me(store: &mut Store, id: i64) -> CoreResult<()> {
    let changed = store
        .conn()
        .execute("DELETE FROM messages WHERE id = ?1", [id])?;
    if changed == 0 {
        return Err(CoreError::UnknownMessage);
    }
    Ok(())
}

/// Reage a uma mensagem da conversa (0 tira a reação).
pub fn react(store: &mut Store, id: i64, kind: u32) -> CoreResult<Message> {
    if kind > REACTIONS {
        return Err(CoreError::InvalidMessage);
    }
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let message = by_id(&tx, id)?;
    if message.deleted || message.kind != Kind::Text {
        return Err(CoreError::UnknownMessage);
    }
    let contact = established(&tx, message.contact_id)?;
    let lamport = next_lamport(&tx, contact.id)?;
    enqueue(
        &tx,
        &me,
        &contact,
        ContentBody::Reaction(wire::Reaction {
            target: message.message_id.clone(),
            kind,
        }),
        lamport,
        now_ms(),
        false,
    )?;
    set_reaction(&tx, id, true, kind)?;
    let message = by_id(&tx, id)?;
    tx.commit()?;
    Ok(message)
}

fn set_reaction(conn: &Connection, id: i64, outgoing: bool, kind: u32) -> CoreResult<()> {
    if kind == 0 {
        conn.execute(
            "DELETE FROM reactions WHERE message = ?1 AND outgoing = ?2",
            (id, outgoing),
        )?;
    } else {
        conn.execute(
            "INSERT OR REPLACE INTO reactions (message, outgoing, kind) VALUES (?1, ?2, ?3)",
            (id, outgoing, kind),
        )?;
    }
    Ok(())
}

/// Avisa que estou digitando, se o aviso está ligado. Vai só se sair logo.
pub fn typing(store: &mut Store, contact_id: i64) -> CoreResult<bool> {
    if !settings(store.conn())?.typing {
        return Ok(false);
    }
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let contact = established(&tx, contact_id)?;
    // Um aviso por vez na fila basta.
    let queued: bool = tx.query_row(
        "SELECT EXISTS(SELECT 1 FROM outbox WHERE contact_id = ?1 AND ephemeral = 1)",
        [contact_id],
        |r| r.get(0),
    )?;
    if queued {
        return Ok(false);
    }
    let lamport: i64 = tx.query_row(
        "SELECT lamport FROM contacts WHERE id = ?1",
        [contact_id],
        |r| r.get(0),
    )?;
    enqueue(
        &tx,
        &me,
        &contact,
        ContentBody::Typing(wire::Typing {}),
        lamport,
        now_ms(),
        true,
    )?;
    tx.commit()?;
    Ok(true)
}

/// Marca como lidas as mensagens do contato e manda o recibo, se os recibos estão
/// ligados. Devolve se alguma mudou.
pub fn mark_read(store: &mut Store, contact_id: i64) -> CoreResult<bool> {
    let me = session::me(store)?;
    let receipts = settings(store.conn())?.read_receipts;
    let tx = store.conn_mut().transaction()?;
    let ids: Vec<Vec<u8>> = {
        let mut stmt = tx.prepare(
            "SELECT message_id FROM messages
              WHERE contact_id = ?1 AND outgoing = 0 AND status = 0 AND kind = 0
              ORDER BY id",
        )?;
        let rows = stmt.query_map([contact_id], |r| r.get(0))?;
        rows.collect::<rusqlite::Result<_>>()?
    };
    let changed = tx.execute(
        "UPDATE messages SET status = 2 WHERE contact_id = ?1 AND outgoing = 0 AND status = 0",
        [contact_id],
    )?;
    if receipts && !ids.is_empty() {
        if let Ok(contact) = established(&tx, contact_id) {
            let lamport: i64 = tx.query_row(
                "SELECT lamport FROM contacts WHERE id = ?1",
                [contact_id],
                |r| r.get(0),
            )?;
            for chunk in ids.chunks(MAX_RECEIPT_IDS) {
                enqueue(
                    &tx,
                    &me,
                    &contact,
                    ContentBody::Receipt(wire::Receipt {
                        read: chunk.to_vec(),
                        delivered: vec![],
                    }),
                    lamport,
                    now_ms(),
                    false,
                )?;
            }
        }
    }
    tx.commit()?;
    Ok(changed > 0)
}

/// Manda o perfil de agora a todos os contatos. Devolve a quem.
pub fn send_profile(store: &mut Store) -> CoreResult<Vec<i64>> {
    let me = session::me(store)?;
    let profile = store.profile()?.ok_or(CoreError::NoProfile)?;
    let tx = store.conn_mut().transaction()?;
    let mut sent = Vec::new();
    for contact in contacts::list(&tx)? {
        if contact.state != ContactState::Established {
            continue;
        }
        let lamport: i64 = tx.query_row(
            "SELECT lamport FROM contacts WHERE id = ?1",
            [contact.id],
            |r| r.get(0),
        )?;
        enqueue(
            &tx,
            &me,
            &contact,
            ContentBody::Profile(wire::PeerProfile {
                display_name: profile.display_name.clone(),
                version: profile.version,
            }),
            lamport,
            now_ms(),
            false,
        )?;
        sent.push(contact.id);
    }
    tx.commit()?;
    Ok(sent)
}

/// Manda os endereços de agora (os IPs e os retransmissores) a todos os contatos,
/// pela sessão. Devolve a quem.
pub fn send_addrs(store: &mut Store, addrs: &[String]) -> CoreResult<Vec<i64>> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let mut sent = Vec::new();
    for contact in contacts::list(&tx)? {
        if contact.state != ContactState::Established {
            continue;
        }
        let lamport: i64 = tx.query_row(
            "SELECT lamport FROM contacts WHERE id = ?1",
            [contact.id],
            |r| r.get(0),
        )?;
        enqueue(
            &tx,
            &me,
            &contact,
            ContentBody::Addrs(wire::Peer {
                addrs: addrs.to_vec(),
                ..Default::default()
            }),
            lamport,
            now_ms(),
            false,
        )?;
        sent.push(contact.id);
    }
    crate::network::set_announced(&tx, addrs)?;
    tx.commit()?;
    Ok(sent)
}

/// Oferece ao contato um arquivo já preparado (`files::prepare`): a mensagem e a
/// oferta saem juntas, e as fatias, quando o contato pedir.
pub fn send_file(
    store: &mut Store,
    contact_id: i64,
    prepared: crate::files::Prepared,
) -> CoreResult<Message> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let contact = established(&tx, contact_id)?;
    let lamport = next_lamport(&tx, contact_id)?;
    let sent_at = now_ms();
    let message_id = enqueue(
        &tx,
        &me,
        &contact,
        ContentBody::File(wire::FileOffer {
            file_id: prepared.file_id.clone(),
            name: prepared.name.clone(),
            size: prepared.size,
            mime: prepared.mime.clone(),
            hash: prepared.hash.clone(),
            key: prepared.key.to_vec(),
            thumbnail: prepared.thumbnail.clone().unwrap_or_default(),
        }),
        lamport,
        sent_at,
        false,
    )?;
    let id = insert(
        &tx,
        contact_id,
        &message_id,
        true,
        Kind::File,
        &prepared.name,
        None,
        sent_at,
        lamport,
        Status::Pending,
    )?
    .ok_or(CoreError::Storage)?;
    crate::files::insert(
        &tx,
        &crate::files::FileRow {
            message: id,
            file_id: prepared.file_id,
            name: prepared.name,
            size: prepared.size,
            mime: prepared.mime,
            hash: prepared.hash,
            key: prepared.key,
            thumbnail: prepared.thumbnail,
            chunks: prepared.chunks,
            received: prepared.chunks,
            state: crate::files::State::Done,
        },
    )?;
    let message = by_id(&tx, id)?;
    tx.commit()?;
    Ok(message)
}

/// Conta a cada contato estabelecido onde fica a caixa postal deste aparelho, com a
/// ficha dele (a primeira vez, ou quando a caixa mudou), ou que ela foi desligada.
/// Devolve a quem mandou.
pub fn send_mailbox(store: &mut Store) -> CoreResult<Vec<i64>> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let mine = crate::mailbox::get(&tx)?;
    let mut sent = Vec::new();
    for contact in contacts::list(&tx)? {
        if contact.state != ContactState::Established {
            continue;
        }
        let told = crate::mailbox::told(&tx, contact.id)?;
        let info = match &mine {
            Some(paired) if told.as_deref() != Some(paired.endpoint_id.as_slice()) => {
                wire::MailboxInfo {
                    endpoint_id: paired.endpoint_id.to_vec(),
                    addrs: paired.addrs.clone(),
                    drop: crate::mailbox::drop_token(&tx, contact.id)?.to_vec(),
                }
            }
            None if told.is_some() => wire::MailboxInfo::default(),
            _ => continue,
        };
        let lamport: i64 = tx.query_row(
            "SELECT lamport FROM contacts WHERE id = ?1",
            [contact.id],
            |r| r.get(0),
        )?;
        enqueue(
            &tx,
            &me,
            &contact,
            ContentBody::Mailbox(info),
            lamport,
            now_ms(),
            false,
        )?;
        crate::mailbox::set_told(
            &tx,
            contact.id,
            mine.as_ref().map(|p| p.endpoint_id.as_slice()),
        )?;
        sent.push(contact.id);
    }
    tx.commit()?;
    Ok(sent)
}

/// Manda a foto do perfil a quem deve ver e ainda não tem a de agora, e uma vazia a
/// quem tinha e não deve ver mais. Devolve a quem mandou.
pub fn send_photos(store: &mut Store) -> CoreResult<Vec<i64>> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let own = crate::photo::own(&tx)?;
    let mut sent = Vec::new();
    for contact in contacts::list(&tx)? {
        if contact.state != ContactState::Established {
            continue;
        }
        let before = crate::photo::sent(&tx, contact.id)?;
        let target = if crate::photo::visible_to(&own, contact.photo_allowed) {
            own.hash.clone().unwrap_or_default()
        } else {
            vec![]
        };
        // Quem nunca recebeu nada e não deve ver não precisa saber que não há foto.
        if before.as_ref() == Some(&target) || (before.is_none() && target.is_empty()) {
            continue;
        }
        let jpeg = if target.is_empty() {
            vec![]
        } else {
            own.jpeg.clone().unwrap_or_default()
        };
        let lamport: i64 = tx.query_row(
            "SELECT lamport FROM contacts WHERE id = ?1",
            [contact.id],
            |r| r.get(0),
        )?;
        enqueue(
            &tx,
            &me,
            &contact,
            ContentBody::Photo(wire::PeerPhoto { jpeg }),
            lamport,
            now_ms(),
            false,
        )?;
        crate::photo::set_sent(&tx, contact.id, &target)?;
        sent.push(contact.id);
    }
    tx.commit()?;
    Ok(sent)
}

/// Avisa o contato de que as mensagens que vieram pela caixa postal chegaram (elas não
/// tiveram o `Ack`). Vale mesmo sem os recibos de leitura: é o "entregue".
pub fn send_delivered(store: &mut Store, contact_id: i64, ids: &[Vec<u8>]) -> CoreResult<()> {
    if ids.is_empty() {
        return Ok(());
    }
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let contact = established(&tx, contact_id)?;
    let lamport: i64 = tx.query_row(
        "SELECT lamport FROM contacts WHERE id = ?1",
        [contact_id],
        |r| r.get(0),
    )?;
    for chunk in ids.chunks(MAX_RECEIPT_IDS) {
        enqueue(
            &tx,
            &me,
            &contact,
            ContentBody::Receipt(wire::Receipt {
                read: vec![],
                delivered: chunk.to_vec(),
            }),
            lamport,
            now_ms(),
            false,
        )?;
    }
    tx.commit()?;
    Ok(())
}

// ---------------------------------------------------------------- a caixa de saída

/// Põe na caixa de saída um envelope já cifrado (o Welcome de um contato que chegou
/// pela caixa postal).
pub fn queue_raw(conn: &Connection, contact_id: i64, ciphertext: &[u8]) -> CoreResult<()> {
    conn.execute(
        "INSERT INTO outbox (contact_id, message_id, prekey, ciphertext, ephemeral, created_at)
         VALUES (?1, ?2, 0, ?3, 0, ?4)",
        (
            contact_id,
            secret_bytes::<16>()?.to_vec(),
            ciphertext,
            now_ms(),
        ),
    )?;
    Ok(())
}

/// Um envelope esperando entrega.
pub struct Outgoing {
    pub id: i64,
    pub prekey: bool,
    pub ciphertext: Vec<u8>,
}

/// O próximo envelope para o contato, na ordem em que foram cifrados.
pub fn next_out(conn: &Connection, contact_id: i64) -> CoreResult<Option<Outgoing>> {
    Ok(conn
        .query_row(
            "SELECT id, prekey, ciphertext FROM outbox WHERE contact_id = ?1 ORDER BY id LIMIT 1",
            [contact_id],
            |r| {
                Ok(Outgoing {
                    id: r.get(0)?,
                    prekey: r.get(1)?,
                    ciphertext: r.get(2)?,
                })
            },
        )
        .optional()?)
}

/// O outro lado confirmou: o envelope sai, e a mensagem fica "entregue". Devolve se
/// alguma mensagem mudou.
pub fn delivered(conn: &Connection, outbox_id: i64) -> CoreResult<bool> {
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
        "UPDATE messages SET status = 1
          WHERE contact_id = ?1 AND message_id = ?2 AND outgoing = 1 AND status = 0",
        (contact_id, &message_id),
    )?;
    Ok(changed > 0 || group_delivered(conn, &message_id)?)
}

/// Uma mensagem minha num grupo fica "entregue" quando nenhuma cópia espera mais.
fn group_delivered(conn: &Connection, message_id: &[u8]) -> CoreResult<bool> {
    let changed = conn.execute(
        "UPDATE messages SET status = 1, in_mailbox = 0
          WHERE message_id = ?1 AND outgoing = 1 AND status = 0
            AND contact_id IN (SELECT contact_id FROM groups)
            AND NOT EXISTS (SELECT 1 FROM outbox WHERE message_id = ?1)",
        [message_id],
    )?;
    Ok(changed > 0)
}

/// Joga fora os avisos de "digitando" do contato (não saíram agora, não valem
/// depois), ou de todos quando `contact_id` não vem, os velhos.
pub fn drop_ephemeral(conn: &Connection, contact_id: Option<i64>) -> CoreResult<()> {
    match contact_id {
        Some(id) => conn.execute(
            "DELETE FROM outbox WHERE contact_id = ?1 AND ephemeral = 1",
            [id],
        )?,
        None => conn.execute(
            "DELETE FROM outbox WHERE ephemeral = 1 AND created_at < ?1",
            [now_ms() - EPHEMERAL_TTL_MS],
        )?,
    };
    Ok(())
}

/// Os contatos com alguma coisa esperando entrega.
pub fn waiting(conn: &Connection) -> CoreResult<Vec<i64>> {
    let mut stmt = conn.prepare("SELECT DISTINCT contact_id FROM outbox ORDER BY contact_id")?;
    let rows = stmt.query_map([], |r| r.get(0))?;
    Ok(rows.collect::<rusqlite::Result<_>>()?)
}

// ---------------------------------------------------------------- a caixa de entrada

/// Uma mensagem do contato que fala por `remote_endpoint`: decifra, aplica e grava,
/// numa transação. Um erro aqui deixa o banco como estava; o que decifra e não serve
/// é descartado (e confirmado).
pub fn receive(
    store: &mut Store,
    remote_endpoint: &[u8],
    prekey: bool,
    bytes: &[u8],
) -> CoreResult<Effect> {
    let contact =
        contacts::by_endpoint(store.conn(), remote_endpoint)?.ok_or(CoreError::UnknownContact)?;
    Ok(receive_from(store, &contact, prekey, bytes)?.0)
}

/// O mesmo, de um contato já conhecido (o que veio pela caixa postal, pela ficha).
/// Devolve também o id no fio quando é uma mensagem da conversa (texto, atenção,
/// arquivo), para o recibo de "entregue".
pub fn receive_from(
    store: &mut Store,
    contact: &Contact,
    prekey: bool,
    bytes: &[u8],
) -> CoreResult<(Effect, Option<Vec<u8>>)> {
    let me = session::me(store)?;
    let tx = store.conn_mut().transaction()?;
    let Some(plain) = session::decrypt(&tx, &me, &contact.identity_key, prekey, bytes)? else {
        return Ok((Effect::Nothing, None));
    };
    let (effect, shown) = match Content::decode(plain.as_slice()) {
        Ok(content) if content.message_id.len() == 16 => {
            let shown = matches!(
                content.body,
                Some(ContentBody::Text(_) | ContentBody::Nudge(_) | ContentBody::File(_))
            )
            .then(|| content.message_id.clone());
            (apply(&tx, &me, contact, content)?, shown)
        }
        _ => (Effect::Nothing, None),
    };
    tx.commit()?;
    Ok((effect, shown))
}

/// O relógio de Lamport da conversa avança com o que chega, sem deixar um contato
/// empurrá-lo para longe. Devolve o valor da mensagem.
pub(crate) fn advance_lamport(conn: &Connection, id: i64, theirs: u64) -> CoreResult<i64> {
    let local: i64 = conn.query_row("SELECT lamport FROM contacts WHERE id = ?1", [id], |r| {
        r.get(0)
    })?;
    let lamport = (theirs.min(i64::MAX as u64) as i64).min(local + MAX_LAMPORT_JUMP);
    conn.execute(
        "UPDATE contacts SET lamport = max(lamport, ?2) WHERE id = ?1",
        (id, lamport),
    )?;
    Ok(lamport)
}

fn apply(conn: &Connection, me: &Me, contact: &Contact, content: Content) -> CoreResult<Effect> {
    let me_key = &me.public()[..];
    if !content.group.is_empty() {
        return crate::groups::apply_message(conn, contact, content);
    }
    let Some(body) = content.body else {
        return Ok(Effect::Nothing);
    };
    let lamport = match body {
        // O grupo tem o relógio dele; o da conversa a dois não muda.
        ContentBody::Group(_) | ContentBody::GroupLeave(_) | ContentBody::GroupIntro(_) => 0,
        _ => advance_lamport(conn, contact.id, content.lamport)?,
    };
    let sent_at = content.sent_at.min(i64::MAX as u64) as i64;
    let id = contact.id;
    let messages = Effect::Messages(id);
    let incoming_target = |target: &[u8], window: i64| -> CoreResult<Option<Message>> {
        let row = conn
            .query_row(
                &format!("{SELECT} WHERE m.contact_id = ?1 AND m.message_id = ?2"),
                (id, target),
                from_row,
            )
            .optional()?;
        Ok(row.filter(|m| {
            !m.outgoing
                && m.kind == Kind::Text
                && !m.deleted
                && now_ms() - m.received_at <= window + SLACK_MS
        }))
    };
    Ok(match body {
        ContentBody::Text(text) => {
            let Ok(body) = valid_text(&text.text) else {
                return Ok(Effect::Nothing);
            };
            let reply = (text.reply_to.len() == 16).then_some(text.reply_to.as_slice());
            insert(
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
            )?;
            messages
        }
        ContentBody::Nudge(_) => {
            let now = now_ms();
            let last: i64 = conn.query_row(
                "SELECT nudge_in_at FROM contacts WHERE id = ?1",
                [id],
                |r| r.get(0),
            )?;
            if now - last < NUDGE_INTERVAL_MS && now >= last {
                return Ok(Effect::Nothing);
            }
            conn.execute(
                "UPDATE contacts SET nudge_in_at = ?2 WHERE id = ?1",
                (id, now),
            )?;
            insert(
                conn,
                id,
                &content.message_id,
                false,
                Kind::Nudge,
                "",
                None,
                sent_at,
                lamport,
                Status::Pending,
            )?;
            messages
        }
        ContentBody::Edit(edit) => {
            let (Some(target), Ok(text)) = (
                incoming_target(&edit.target, EDIT_WINDOW_MS)?,
                valid_text(&edit.text),
            ) else {
                return Ok(Effect::Nothing);
            };
            conn.execute(
                "UPDATE messages SET body = ?2, edited = 1 WHERE id = ?1",
                (target.id, text),
            )?;
            messages
        }
        ContentBody::Delete(delete) => {
            let Some(target) = incoming_target(&delete.target, DELETE_WINDOW_MS)? else {
                return Ok(Effect::Nothing);
            };
            wipe(conn, target.id)?;
            messages
        }
        ContentBody::Reaction(reaction) => {
            if reaction.kind > REACTIONS {
                return Ok(Effect::Nothing);
            }
            let target: Option<(i64, bool)> = conn
                .query_row(
                    "SELECT id, deleted FROM messages
                      WHERE contact_id = ?1 AND message_id = ?2 AND kind = 0",
                    (id, &reaction.target),
                    |r| Ok((r.get(0)?, r.get(1)?)),
                )
                .optional()?;
            let Some((target, false)) = target else {
                return Ok(Effect::Nothing);
            };
            set_reaction(conn, target, false, reaction.kind)?;
            messages
        }
        ContentBody::Receipt(receipt) => {
            for message_id in receipt.delivered.iter().take(MAX_RECEIPT_IDS) {
                conn.execute(
                    "UPDATE messages SET status = 1, in_mailbox = 0
                      WHERE contact_id = ?1 AND message_id = ?2 AND outgoing = 1 AND status = 0",
                    (id, message_id),
                )?;
                group_delivered(conn, message_id)?;
            }
            if settings(conn)?.read_receipts {
                for message_id in receipt.read.iter().take(MAX_RECEIPT_IDS) {
                    conn.execute(
                        "UPDATE messages SET status = 2, in_mailbox = 0
                          WHERE contact_id = ?1 AND message_id = ?2 AND outgoing = 1",
                        (id, message_id),
                    )?;
                }
            }
            messages
        }
        // Não confere a hora: o relógio de quem manda pode estar em outra. O aviso só
        // sai na hora (`EPHEMERAL_TTL_MS`), ou não sai.
        ContentBody::Typing(_) => {
            if settings(conn)?.typing {
                Effect::Typing(id)
            } else {
                Effect::Nothing
            }
        }
        ContentBody::Profile(profile) => {
            match crate::profile::validate_name(&profile.display_name) {
                Ok(name) if contacts::update_profile(conn, id, &name, profile.version)? => {
                    Effect::Contact(id)
                }
                _ => Effect::Nothing,
            }
        }
        ContentBody::Addrs(peer) => {
            let addrs = crate::network::clean_addrs(peer.addrs);
            if !addrs.is_empty() && contacts::set_addrs(conn, id, &addrs)? {
                Effect::Contact(id)
            } else {
                Effect::Nothing
            }
        }
        ContentBody::File(offer) => {
            let valid = offer.file_id.len() == 16
                && offer.key.len() == 32
                && offer.hash.len() == 32
                && offer.size <= crate::files::MAX_FILE
                && offer.thumbnail.len() <= crate::files::MAX_THUMBNAIL;
            if !valid {
                return Ok(Effect::Nothing);
            }
            let name = crate::files::clean_name(&offer.name);
            let Some(row) = insert(
                conn,
                id,
                &content.message_id,
                false,
                Kind::File,
                &name,
                None,
                sent_at,
                lamport,
                Status::Pending,
            )?
            else {
                return Ok(Effect::Nothing);
            };
            // O mesmo arquivo oferecido de novo (com outro id de mensagem) é ignorado.
            let known: bool = conn.query_row(
                "SELECT EXISTS (SELECT 1 FROM files WHERE file_id = ?1)",
                [&offer.file_id],
                |r| r.get(0),
            )?;
            if known {
                conn.execute("DELETE FROM messages WHERE id = ?1", [row])?;
                return Ok(Effect::Nothing);
            }
            let mime = if offer.mime.len() <= 100 && !offer.mime.chars().any(char::is_control) {
                offer.mime
            } else {
                "application/octet-stream".to_owned()
            };
            crate::files::insert(
                conn,
                &crate::files::FileRow {
                    message: row,
                    file_id: offer.file_id,
                    name,
                    size: offer.size,
                    mime,
                    hash: offer.hash,
                    key: zeroize::Zeroizing::new(offer.key),
                    thumbnail: (!offer.thumbnail.is_empty()).then_some(offer.thumbnail),
                    chunks: crate::files::chunks_for(offer.size),
                    received: 0,
                    state: if crate::downloads::get(conn)?
                        .allows(offer.size, contacts::by_id(conn, id)?.verified)
                    {
                        crate::files::State::Downloading
                    } else {
                        crate::files::State::Waiting
                    },
                },
            )?;
            messages
        }
        ContentBody::Mailbox(info) => {
            let Ok(theirs) = crate::mailbox::theirs_from_info(info) else {
                return Ok(Effect::Nothing);
            };
            if crate::mailbox::set_theirs(conn, id, theirs.as_ref())? {
                Effect::Contact(id)
            } else {
                Effect::Nothing
            }
        }
        ContentBody::Photo(photo) => {
            let jpeg = if photo.jpeg.is_empty() {
                None
            } else if crate::photo::check(&photo.jpeg) {
                Some(photo.jpeg.as_slice())
            } else {
                return Ok(Effect::Nothing);
            };
            if crate::photo::set_theirs(conn, id, jpeg)? {
                Effect::Contact(id)
            } else {
                Effect::Nothing
            }
        }
        ContentBody::Group(update) => crate::groups::apply_update(conn, me_key, contact, update)?,
        ContentBody::GroupLeave(leave) => crate::groups::apply_leave(conn, me_key, contact, leave)?,
        ContentBody::GroupIntro(intro) => crate::groups::apply_intro(conn, me, contact, intro)?,
        // O aperto de mão já passou.
        ContentBody::Hello(_) | ContentBody::Welcome(_) => Effect::Nothing,
    })
}

#[cfg(test)]
mod tests;

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
    // 3: as mensagens, a caixa de saída e a busca (fase 3).
    "ALTER TABLE local_keys ADD COLUMN port INTEGER NOT NULL DEFAULT 0;
     ALTER TABLE contacts ADD COLUMN lamport INTEGER NOT NULL DEFAULT 0;
     ALTER TABLE contacts ADD COLUMN nudge_in_at INTEGER NOT NULL DEFAULT 0;
     ALTER TABLE contacts ADD COLUMN nudge_out_at INTEGER NOT NULL DEFAULT 0;
     CREATE TABLE messages (
         id          INTEGER PRIMARY KEY,
         contact_id  INTEGER NOT NULL REFERENCES contacts (id) ON DELETE CASCADE,
         message_id  BLOB NOT NULL,
         outgoing    INTEGER NOT NULL,
         kind        INTEGER NOT NULL,
         body        TEXT NOT NULL,
         reply_to    BLOB,
         sent_at     INTEGER NOT NULL,
         received_at INTEGER NOT NULL,
         lamport     INTEGER NOT NULL,
         status      INTEGER NOT NULL,
         edited      INTEGER NOT NULL DEFAULT 0,
         deleted     INTEGER NOT NULL DEFAULT 0,
         UNIQUE (contact_id, message_id)
     );
     CREATE INDEX messages_order ON messages (contact_id, lamport, sent_at, id);
     CREATE TABLE reactions (
         message  INTEGER NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
         outgoing INTEGER NOT NULL,
         kind     INTEGER NOT NULL,
         PRIMARY KEY (message, outgoing)
     );
     CREATE TABLE outbox (
         id         INTEGER PRIMARY KEY,
         contact_id INTEGER NOT NULL REFERENCES contacts (id) ON DELETE CASCADE,
         message_id BLOB NOT NULL,
         prekey     INTEGER NOT NULL,
         ciphertext BLOB NOT NULL,
         ephemeral  INTEGER NOT NULL,
         created_at INTEGER NOT NULL
     );
     CREATE INDEX outbox_order ON outbox (contact_id, id);
     CREATE TABLE settings (
         id            INTEGER PRIMARY KEY CHECK (id = 1),
         read_receipts INTEGER NOT NULL,
         typing        INTEGER NOT NULL
     );
     INSERT INTO settings (id, read_receipts, typing) VALUES (1, 1, 1);
     CREATE VIRTUAL TABLE messages_fts USING fts5 (
         body, content = 'messages', content_rowid = 'id',
         tokenize = 'unicode61 remove_diacritics 2'
     );
     CREATE TRIGGER messages_fts_insert AFTER INSERT ON messages BEGIN
         INSERT INTO messages_fts (rowid, body) VALUES (new.id, new.body);
     END;
     CREATE TRIGGER messages_fts_delete AFTER DELETE ON messages BEGIN
         INSERT INTO messages_fts (messages_fts, rowid, body) VALUES ('delete', old.id, old.body);
     END;
     CREATE TRIGGER messages_fts_update AFTER UPDATE OF body ON messages BEGIN
         INSERT INTO messages_fts (messages_fts, rowid, body) VALUES ('delete', old.id, old.body);
         INSERT INTO messages_fts (rowid, body) VALUES (new.id, new.body);
     END;",
    // 4: a aparência (fase 4).
    "CREATE TABLE appearance (
         id         INTEGER PRIMARY KEY CHECK (id = 1),
         theme      TEXT NOT NULL,
         brightness INTEGER NOT NULL,
         glass      INTEGER NOT NULL
     );
     INSERT INTO appearance (id, theme, brightness, glass) VALUES (1, 'lutino', 0, 0);",
    // 5: a internet e os retransmissores (fase 5).
    "CREATE TABLE network (
         id        INTEGER PRIMARY KEY CHECK (id = 1),
         internet  INTEGER NOT NULL,
         relays    TEXT NOT NULL,
         announced TEXT NOT NULL
     );
     INSERT INTO network (id, internet, relays, announced) VALUES (1, 0, '', '');",
    // 6: os arquivos (fase 6). O blob cifrado fica em `files/`, ao lado do banco.
    "CREATE TABLE files (
         message   INTEGER PRIMARY KEY REFERENCES messages (id) ON DELETE CASCADE,
         file_id   BLOB NOT NULL UNIQUE,
         name      TEXT NOT NULL,
         size      INTEGER NOT NULL,
         mime      TEXT NOT NULL,
         hash      BLOB NOT NULL,
         key       BLOB NOT NULL,
         thumbnail BLOB,
         chunks    INTEGER NOT NULL,
         received  INTEGER NOT NULL,
         state     INTEGER NOT NULL
     );",
    // 7: o que as notificações mostram (fase 6); o padrão é o nome, sem o texto.
    "CREATE TABLE notifications (
         id   INTEGER PRIMARY KEY CHECK (id = 1),
         mode INTEGER NOT NULL
     );
     INSERT INTO notifications (id, mode) VALUES (1, 2);",
    // 8: continuar recebendo com a janela fechada (fase 6), ligado por padrão.
    "ALTER TABLE notifications ADD COLUMN keep_running INTEGER NOT NULL DEFAULT 1;",
    // 9: o baixar sozinho (fase 6): até 32 MiB, de qualquer contato.
    "CREATE TABLE downloads (
         id            INTEGER PRIMARY KEY CHECK (id = 1),
         auto_limit    INTEGER NOT NULL,
         only_verified INTEGER NOT NULL
     );
     INSERT INTO downloads (id, auto_limit, only_verified) VALUES (1, 2, 0);",
    // 10: a caixa postal (fase 7). A deste aparelho, a ficha que cada contato recebeu
    // dela, a caixa de cada contato e as mensagens que esperam numa caixa.
    "CREATE TABLE mailbox (
         id          INTEGER PRIMARY KEY CHECK (id = 1),
         endpoint_id BLOB NOT NULL,
         addrs       TEXT NOT NULL,
         paired_at   INTEGER NOT NULL,
         last_fetch  INTEGER NOT NULL DEFAULT 0,
         synced      BLOB
     );
     ALTER TABLE contacts ADD COLUMN drop_token BLOB;
     ALTER TABLE contacts ADD COLUMN drop_hash BLOB;
     ALTER TABLE contacts ADD COLUMN mailbox_told BLOB;
     ALTER TABLE contacts ADD COLUMN their_mailbox BLOB;
     ALTER TABLE contacts ADD COLUMN their_mailbox_addrs TEXT NOT NULL DEFAULT '';
     ALTER TABLE contacts ADD COLUMN their_drop BLOB;
     CREATE INDEX contacts_drop ON contacts (drop_hash);
     ALTER TABLE messages ADD COLUMN in_mailbox INTEGER NOT NULL DEFAULT 0;",
    // 11: o primeiro contato pela caixa postal (fase 7): o SHA-256 da ficha com que o
    // Hello de um convite publicado chega.
    "ALTER TABLE invites ADD COLUMN drop_hash BLOB;
     CREATE INDEX invites_drop ON invites (drop_hash);",
    // 12: a foto do perfil, quem vê, e a de cada contato. `photo_sent` é o que o
    // contato recebeu: nada (nunca), vazio (sem foto) ou o SHA-256 da foto.
    "CREATE TABLE photo (
         id         INTEGER PRIMARY KEY CHECK (id = 1),
         jpeg       BLOB,
         hash       BLOB,
         visibility INTEGER NOT NULL
     );
     INSERT INTO photo (id, jpeg, hash, visibility) VALUES (1, NULL, NULL, 1);
     ALTER TABLE contacts ADD COLUMN photo BLOB;
     ALTER TABLE contacts ADD COLUMN photo_allowed INTEGER NOT NULL DEFAULT 0;
     ALTER TABLE contacts ADD COLUMN photo_sent BLOB;",
    // 13: o Bluetooth (fase 8), desligado por padrão.
    "ALTER TABLE network ADD COLUMN bluetooth INTEGER NOT NULL DEFAULT 0;",
    // 14: os grupos (fase 9). O grupo é uma linha de `contacts` (o estado 2, com o id
    // do grupo no lugar da chave), para a conversa ser a mesma; os membros sem mim.
    "CREATE TABLE groups (
         contact_id INTEGER PRIMARY KEY REFERENCES contacts (id) ON DELETE CASCADE,
         group_id   BLOB NOT NULL UNIQUE,
         admin      BLOB NOT NULL,
         version    INTEGER NOT NULL,
         active     INTEGER NOT NULL
     );
     CREATE TABLE group_members (
         group_ref    INTEGER NOT NULL REFERENCES groups (contact_id) ON DELETE CASCADE,
         identity_key BLOB NOT NULL,
         endpoint_id  BLOB NOT NULL,
         name         TEXT NOT NULL,
         PRIMARY KEY (group_ref, identity_key)
     );
     ALTER TABLE messages ADD COLUMN author BLOB;",
    // 15: apresentar os membros de um grupo entre si (fase 9, parte 2). O contato que
    // nasce assim fica fora da lista de conversas até alguém escrever a dois.
    "ALTER TABLE contacts ADD COLUMN via_group INTEGER NOT NULL DEFAULT 0;
     CREATE TABLE group_intros_out (
         group_ref INTEGER NOT NULL REFERENCES groups (contact_id) ON DELETE CASCADE,
         member    BLOB NOT NULL,
         sent_at   INTEGER NOT NULL,
         PRIMARY KEY (group_ref, member)
     );
     CREATE TABLE group_intros_in (
         group_ref   INTEGER NOT NULL REFERENCES groups (contact_id) ON DELETE CASCADE,
         member      BLOB NOT NULL,
         invite      TEXT NOT NULL,
         received_at INTEGER NOT NULL,
         PRIMARY KEY (group_ref, member)
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

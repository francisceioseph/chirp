//! As mensagens sem rede: dois aparelhos, e um "carteiro" que leva a caixa de saída de
//! um para a caixa de entrada do outro.

use super::*;
use crate::session::{accept_hello, accept_welcome, bundle_for, create_invite, join, InviteKind};
use crate::wire::Peer;

struct Device {
    store: Store,
    endpoint: [u8; 32],
    /// O id do outro aparelho nos contatos deste.
    other: i64,
}

impl Device {
    fn new(name: &str, endpoint: u8) -> Self {
        Self::with(Store::memory(), name, endpoint)
    }

    fn with(mut store: Store, name: &str, endpoint: u8) -> Self {
        store.create_profile(name).unwrap();
        Self {
            store,
            endpoint: [endpoint; 32],
            other: 0,
        }
    }

    fn peer(&self) -> Peer {
        Peer {
            endpoint_id: self.endpoint.to_vec(),
            addrs: vec![],
            discovery_key: session::local_keys(self.store.conn())
                .unwrap()
                .discovery_key
                .to_vec(),
        }
    }

    fn list(&self) -> Vec<Message> {
        list(self.store.conn(), self.other, None, 100).unwrap()
    }

    fn outbox(&self) -> i64 {
        self.store
            .conn()
            .query_row("SELECT count(*) FROM outbox", [], |r| r.get(0))
            .unwrap()
    }
}

fn pair() -> (Device, Device) {
    pair_with(Device::new("Bob", 2))
}

fn pair_with(mut bob: Device) -> (Device, Device) {
    let mut alice = Device::new("Alice", 1);
    let invite = create_invite(&mut alice.store, InviteKind::Qr, alice.endpoint, vec![]).unwrap();
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let bob_peer = bob.peer();
    let (pending, hello) = join(&mut bob.store, &invite, &bundle, bob_peer, true).unwrap();
    let alice_peer = alice.peer();
    let (at_alice, welcome) =
        accept_hello(&mut alice.store, &bob.endpoint, &hello, alice_peer).unwrap();
    let at_bob = accept_welcome(&mut bob.store, pending.id, &alice.endpoint, &welcome).unwrap();
    alice.other = at_alice.id;
    bob.other = at_bob.id;
    (alice, bob)
}

/// Leva tudo da caixa de saída de `from` para `to`, como a rede levaria, e devolve os
/// efeitos.
fn post(from: &mut Device, to: &mut Device) -> Vec<Effect> {
    let mut effects = vec![];
    while let Some(out) = next_out(from.store.conn(), from.other).unwrap() {
        let effect = receive(&mut to.store, &from.endpoint, out.prekey, &out.ciphertext).unwrap();
        delivered(from.store.conn(), out.id).unwrap();
        effects.push(effect);
    }
    effects
}

#[test]
fn a_text_goes_and_comes_back_with_the_receipts() {
    let (mut alice, mut bob) = pair();
    let sent = send_text(&mut alice.store, alice.other, "  Oi, Bob!  ", None).unwrap();
    assert_eq!(sent.body, "Oi, Bob!");
    assert_eq!(sent.status, Status::Pending);
    assert_eq!(alice.outbox(), 1);

    assert_eq!(
        post(&mut alice, &mut bob),
        vec![Effect::Messages(bob.other)]
    );
    assert_eq!(alice.outbox(), 0);
    assert_eq!(alice.list()[0].status, Status::Delivered);
    let at_bob = bob.list();
    assert_eq!(at_bob.len(), 1);
    assert!(!at_bob[0].outgoing);
    assert_eq!(at_bob[0].body, "Oi, Bob!");
    assert_eq!(at_bob[0].message_id, sent.message_id);
    let unread = |d: &Device| -> u32 {
        conversations(d.store.conn())
            .unwrap()
            .into_iter()
            .find(|c| c.contact.id == d.other)
            .unwrap()
            .unread
    };
    assert_eq!(unread(&bob), 1);

    // Bob lê: a mensagem fica lida, e o recibo volta para Alice.
    assert!(mark_read(&mut bob.store, bob.other).unwrap());
    assert!(!mark_read(&mut bob.store, bob.other).unwrap());
    assert_eq!(unread(&bob), 0);
    post(&mut bob, &mut alice);
    assert_eq!(alice.list()[0].status, Status::Read);
}

#[test]
fn reading_without_receipts_sends_nothing_and_ignores_theirs() {
    let (mut alice, mut bob) = pair();
    set_settings(
        bob.store.conn(),
        Settings {
            read_receipts: false,
            typing: true,
        },
    )
    .unwrap();
    send_text(&mut alice.store, alice.other, "um", None).unwrap();
    post(&mut alice, &mut bob);
    mark_read(&mut bob.store, bob.other).unwrap();
    assert_eq!(bob.outbox(), 0);
    assert_eq!(alice.list()[0].status, Status::Delivered);

    // Alice manda o recibo dela, e Bob, com os recibos desligados, não aplica.
    send_text(&mut bob.store, bob.other, "dois", None).unwrap();
    post(&mut bob, &mut alice);
    mark_read(&mut alice.store, alice.other).unwrap();
    post(&mut alice, &mut bob);
    assert_eq!(bob.list()[1].status, Status::Delivered);
}

#[test]
fn a_resend_after_a_lost_ack_is_recognized() {
    let (mut alice, mut bob) = pair();
    send_text(&mut alice.store, alice.other, "de novo?", None).unwrap();
    let out = next_out(alice.store.conn(), alice.other).unwrap().unwrap();
    // Bob grava, mas o Ack se perde: Alice manda os mesmos bytes outra vez.
    let first = receive(&mut bob.store, &alice.endpoint, out.prekey, &out.ciphertext).unwrap();
    let again = receive(&mut bob.store, &alice.endpoint, out.prekey, &out.ciphertext).unwrap();
    assert_eq!(first, Effect::Messages(bob.other));
    assert_eq!(again, Effect::Nothing);
    assert_eq!(bob.list().len(), 1);
    assert!(delivered(alice.store.conn(), out.id).unwrap());
    assert!(!delivered(alice.store.conn(), out.id).unwrap());
}

#[test]
fn messages_queued_offline_arrive_in_order() {
    let (mut alice, mut bob) = pair();
    for n in 0..30 {
        send_text(&mut alice.store, alice.other, &format!("m{n}"), None).unwrap();
    }
    // Bob responde antes de receber nada: os dois lados escreveram ao mesmo tempo.
    send_text(&mut bob.store, bob.other, "e aí?", None).unwrap();
    post(&mut alice, &mut bob);
    post(&mut bob, &mut alice);
    let at_bob: Vec<String> = bob.list().into_iter().map(|m| m.body).collect();
    assert_eq!(at_bob.len(), 31);
    let alice_texts: Vec<&String> = at_bob.iter().filter(|b| b.starts_with('m')).collect();
    let expected: Vec<String> = (0..30).map(|n| format!("m{n}")).collect();
    assert_eq!(alice_texts, expected.iter().collect::<Vec<_>>());
    // A conversa tem a mesma ordem nos dois aparelhos.
    let at_alice: Vec<String> = alice.list().into_iter().map(|m| m.body).collect();
    assert_eq!(at_alice, at_bob);
}

#[test]
fn reply_edit_react_and_delete() {
    let (mut alice, mut bob) = pair();
    let first = send_text(&mut alice.store, alice.other, "calopsita", None).unwrap();
    post(&mut alice, &mut bob);
    let at_bob = bob.list()[0].clone();

    let reply = send_text(&mut bob.store, bob.other, "lutino", Some(at_bob.id)).unwrap();
    assert_eq!(reply.reply_to, Some(at_bob.id));
    post(&mut bob, &mut alice);
    assert_eq!(alice.list()[1].reply_to, Some(first.id));

    let edited = edit(&mut alice.store, first.id, "calopsita arlequim").unwrap();
    assert!(edited.edited);
    let theirs = alice.list()[1].id;
    react(&mut alice.store, theirs, 2).unwrap();
    post(&mut alice, &mut bob);
    let at_bob = bob.list();
    assert_eq!(at_bob[0].body, "calopsita arlequim");
    assert!(at_bob[0].edited);
    assert_eq!(at_bob[1].their_reaction, 2);
    assert_eq!(alice.list()[1].my_reaction, 2);

    // Só a própria mensagem se edita ou apaga para todos.
    assert_eq!(
        edit(&mut bob.store, at_bob[0].id, "não").err(),
        Some(CoreError::UnknownMessage)
    );
    assert_eq!(
        react(&mut alice.store, first.id, REACTIONS + 1).err(),
        Some(CoreError::InvalidMessage)
    );

    let gone = delete_for_everyone(&mut alice.store, first.id).unwrap();
    assert!(gone.deleted);
    assert!(gone.body.is_empty());
    post(&mut alice, &mut bob);
    let at_bob = bob.list();
    assert!(at_bob[0].deleted);
    assert!(at_bob[0].body.is_empty());
    assert!(search(bob.store.conn(), "arlequim", 10).unwrap().is_empty());
    assert!(search(alice.store.conn(), "arlequim", 10)
        .unwrap()
        .is_empty());
    // A resposta continua, sem a citação apagada mudar nada nela.
    assert_eq!(at_bob[1].body, "lutino");
}

#[test]
fn edits_and_deletes_have_a_deadline() {
    let (mut alice, mut bob) = pair();
    let old = send_text(&mut alice.store, alice.other, "antiga", None).unwrap();
    post(&mut alice, &mut bob);
    let long_ago = now_ms() - DELETE_WINDOW_MS - SLACK_MS - 1000;
    for device in [&alice, &bob] {
        device
            .store
            .conn()
            .execute("UPDATE messages SET received_at = ?1", [long_ago])
            .unwrap();
    }
    assert_eq!(
        edit(&mut alice.store, old.id, "nova").err(),
        Some(CoreError::TooLate)
    );
    assert_eq!(
        delete_for_everyone(&mut alice.store, old.id).err(),
        Some(CoreError::TooLate)
    );
    // Mesmo que o aparelho de Alice mande (um relógio adiantado, um app alterado), Bob
    // confere o prazo pela hora em que recebeu.
    alice
        .store
        .conn()
        .execute("UPDATE messages SET received_at = ?1", [now_ms()])
        .unwrap();
    delete_for_everyone(&mut alice.store, old.id).unwrap();
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Nothing]);
    assert_eq!(bob.list()[0].body, "antiga");
}

#[test]
fn nudges_are_rate_limited_both_ways() {
    let (mut alice, mut bob) = pair();
    let nudge = send_nudge(&mut alice.store, alice.other).unwrap();
    assert_eq!(nudge.kind, Kind::Nudge);
    assert_eq!(
        send_nudge(&mut alice.store, alice.other).err(),
        Some(CoreError::TooSoon)
    );
    post(&mut alice, &mut bob);
    assert_eq!(bob.list()[0].kind, Kind::Nudge);

    // Um aparelho que ignora o limite não treme a janela do outro duas vezes.
    alice
        .store
        .conn()
        .execute("UPDATE contacts SET nudge_out_at = 0", [])
        .unwrap();
    send_nudge(&mut alice.store, alice.other).unwrap();
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Nothing]);
    assert_eq!(bob.list().len(), 1);
}

#[test]
fn typing_is_ephemeral_and_can_be_turned_off() {
    let (mut alice, mut bob) = pair();
    assert!(typing(&mut alice.store, alice.other).unwrap());
    // Um aviso por vez na fila.
    assert!(!typing(&mut alice.store, alice.other).unwrap());
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Typing(bob.other)]);
    assert!(bob.list().is_empty());

    // Não saiu agora: vai fora, e não chega atrasado.
    typing(&mut alice.store, alice.other).unwrap();
    drop_ephemeral(alice.store.conn(), Some(alice.other)).unwrap();
    assert_eq!(alice.outbox(), 0);
    // Uma mensagem depois do aviso perdido se decifra igual.
    send_text(&mut alice.store, alice.other, "depois", None).unwrap();
    assert_eq!(
        post(&mut alice, &mut bob),
        vec![Effect::Messages(bob.other)]
    );

    set_settings(
        alice.store.conn(),
        Settings {
            read_receipts: true,
            typing: false,
        },
    )
    .unwrap();
    assert!(!typing(&mut alice.store, alice.other).unwrap());
}

#[test]
fn a_profile_change_reaches_the_contacts() {
    let (mut alice, mut bob) = pair();
    alice.store.rename("Alice Lutino").unwrap();
    assert_eq!(send_profile(&mut alice.store).unwrap(), vec![alice.other]);
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Contact(bob.other)]);
    let contact = contacts::by_id(bob.store.conn(), bob.other).unwrap();
    assert_eq!(contact.display_name, "Alice Lutino");
    // Uma versão velha não volta o nome.
    send_profile(&mut alice.store).unwrap();
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Nothing]);
}

#[test]
fn bad_texts_are_refused_before_going_out() {
    let (mut alice, _bob) = pair();
    for bad in [
        "".to_owned(),
        "   ".to_owned(),
        "a".repeat(MAX_TEXT_CHARS + 1),
        "sino\u{7}".to_owned(),
    ] {
        assert_eq!(
            send_text(&mut alice.store, alice.other, &bad, None).err(),
            Some(CoreError::InvalidMessage)
        );
    }
    assert_eq!(alice.outbox(), 0);
    send_text(&mut alice.store, alice.other, "linha\noutra", None).unwrap();
    let windows = send_text(&mut alice.store, alice.other, "linha\r\noutra\rmais", None).unwrap();
    assert_eq!(windows.body, "linha\noutra\nmais");
    assert_eq!(
        send_text(&mut alice.store, 999, "ninguém", None).err(),
        Some(CoreError::UnknownContact)
    );
}

#[test]
fn a_stranger_cannot_inject_messages() {
    let (mut alice, mut bob) = pair();
    let (mut mallory, mut carol) = pair();
    send_text(&mut mallory.store, mallory.other, "sou a Alice", None).unwrap();
    let out = next_out(mallory.store.conn(), mallory.other)
        .unwrap()
        .unwrap();
    // Pelo nó de Mallory, Bob não a conhece.
    assert_eq!(
        receive(&mut bob.store, &[9; 32], out.prekey, &out.ciphertext).err(),
        Some(CoreError::UnknownContact)
    );
    // Pelo nó de Alice (se Mallory conseguisse falar por ele), a sessão não decifra.
    assert_eq!(
        receive(&mut bob.store, &alice.endpoint, out.prekey, &out.ciphertext).err(),
        Some(CoreError::Protocol)
    );
    assert!(bob.list().is_empty());
    // E a sessão de Alice com Bob continua boa.
    send_text(&mut alice.store, alice.other, "oi", None).unwrap();
    assert_eq!(
        post(&mut alice, &mut bob),
        vec![Effect::Messages(bob.other)]
    );
    let _ = post(&mut mallory, &mut carol);
}

#[test]
fn search_finds_words_without_accents_or_syntax() {
    let (mut alice, mut bob) = pair();
    send_text(&mut alice.store, alice.other, "A calopsita cantou", None).unwrap();
    send_text(&mut alice.store, alice.other, "Pão de queijo", None).unwrap();
    post(&mut alice, &mut bob);
    let found = |q: &str| -> Vec<String> {
        search(bob.store.conn(), q, 10)
            .unwrap()
            .into_iter()
            .map(|m| m.body)
            .collect()
    };
    assert_eq!(found("calop"), vec!["A calopsita cantou"]);
    assert_eq!(found("PAO"), vec!["Pão de queijo"]);
    assert_eq!(found("cantou calopsita"), vec!["A calopsita cantou"]);
    assert!(found("\"* OR NEAR(").is_empty());
    assert!(found("   ").is_empty());
    assert!(found("periquito").is_empty());
}

#[test]
fn history_pages_backwards() {
    let (mut alice, _bob) = pair();
    for n in 0..10 {
        send_text(&mut alice.store, alice.other, &format!("{n}"), None).unwrap();
    }
    let last = list(alice.store.conn(), alice.other, None, 4).unwrap();
    let bodies = |ms: &[Message]| ms.iter().map(|m| m.body.clone()).collect::<Vec<_>>();
    assert_eq!(bodies(&last), ["6", "7", "8", "9"]);
    let before = list(alice.store.conn(), alice.other, Some(last[0].id), 4).unwrap();
    assert_eq!(bodies(&before), ["2", "3", "4", "5"]);
    delete_for_me(&mut alice.store, last[0].id).unwrap();
    assert_eq!(
        list(alice.store.conn(), alice.other, None, 100)
            .unwrap()
            .len(),
        9
    );
}

#[test]
fn the_database_keeps_no_plain_text_of_messages() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("chirp.db");
    {
        let bob = Device::with(Store::open(&path, &[5; 32]).unwrap(), "Bob", 2);
        let (mut alice, mut bob) = pair_with(bob);
        send_text(&mut alice.store, alice.other, "segredo da calopsita", None).unwrap();
        post(&mut alice, &mut bob);
        assert_eq!(bob.list()[0].body, "segredo da calopsita");
    }
    let mut bytes = Vec::new();
    for entry in std::fs::read_dir(dir.path()).unwrap() {
        bytes.extend(std::fs::read(entry.unwrap().path()).unwrap());
    }
    assert!(!bytes.windows(7).any(|w| w == b"segredo"));
    assert!(!bytes.windows(9).any(|w| w == b"calopsita"));
}

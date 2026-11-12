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
    let invite = create_invite(
        &mut alice.store,
        InviteKind::Qr,
        alice.endpoint,
        vec![],
        None,
    )
    .unwrap();
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let bob_peer = bob.peer();
    let (pending, hello) = join(&mut bob.store, &invite, &bundle, bob_peer, true, None).unwrap();
    let alice_peer = alice.peer();
    let (at_alice, welcome, _) = accept_hello(
        &mut alice.store,
        crate::session::HelloFrom::Node(&bob.endpoint),
        &hello,
        alice_peer,
    )
    .unwrap();
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
fn new_addresses_reach_the_contact() {
    let (mut alice, mut bob) = pair();
    let addrs = vec![
        "192.168.1.20:4000".to_owned(),
        "203.0.113.7:4000".to_owned(),
        "https://relay.example.org/".to_owned(),
    ];
    assert_eq!(
        send_addrs(&mut alice.store, &addrs).unwrap(),
        vec![alice.other]
    );
    assert_eq!(
        crate::network::announced(alice.store.conn()).unwrap(),
        addrs
    );
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Contact(bob.other)]);
    assert_eq!(
        contacts::by_id(bob.store.conn(), bob.other).unwrap().addrs,
        addrs
    );
    // O mesmo de novo não muda nada, e lixo não apaga o que havia.
    send_addrs(&mut alice.store, &addrs).unwrap();
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Nothing]);
    send_addrs(&mut alice.store, &["nada".to_owned()]).unwrap();
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Nothing]);
    assert_eq!(
        contacts::by_id(bob.store.conn(), bob.other).unwrap().addrs,
        addrs
    );
}

/// Uma oferta de arquivo feita à mão (sem passar pelo `files::prepare`).
fn offer(alice: &mut Device, file_id: u8, key_len: usize, size: u64) {
    let me = session::me(&alice.store).unwrap();
    let tx = alice.store.conn_mut().transaction().unwrap();
    let contact = contacts::by_id(&tx, alice.other).unwrap();
    enqueue(
        &tx,
        &me,
        &contact,
        ContentBody::File(wire::FileOffer {
            file_id: vec![file_id; 16],
            name: "../../segredo.txt".into(),
            size,
            mime: "text/plain".into(),
            hash: vec![1; 32],
            key: vec![2; key_len],
            thumbnail: vec![],
        }),
        1,
        now_ms(),
        false,
    )
    .unwrap();
    tx.commit().unwrap();
}

#[test]
fn file_offers_are_checked_on_arrival() {
    let (mut alice, mut bob) = pair();
    // Chave curta, e grande demais: nada entra.
    offer(&mut alice, 1, 31, 10);
    offer(&mut alice, 2, 32, crate::files::MAX_FILE + 1);
    assert_eq!(
        post(&mut alice, &mut bob),
        vec![Effect::Nothing, Effect::Nothing]
    );
    assert!(bob.list().is_empty());

    // Uma boa: entra com o nome limpo, e pequena, já para baixar.
    offer(&mut alice, 3, 32, 10);
    assert_eq!(
        post(&mut alice, &mut bob),
        vec![Effect::Messages(bob.other)]
    );
    let message = bob.list().pop().unwrap();
    assert_eq!(
        (message.kind, message.body.as_str()),
        (Kind::File, "segredo.txt")
    );
    let row = crate::files::by_message(bob.store.conn(), message.id)
        .unwrap()
        .unwrap();
    assert_eq!(row.state, crate::files::State::Downloading);
    // A mesma oferta de novo não vira outra mensagem; uma grande espera quem usa.
    offer(&mut alice, 3, 32, 10);
    offer(&mut alice, 4, 32, (32 << 20) + 1);
    post(&mut alice, &mut bob);
    let list = bob.list();
    assert_eq!(list.len(), 2);
    let big = crate::files::by_message(bob.store.conn(), list[1].id)
        .unwrap()
        .unwrap();
    assert_eq!(big.state, crate::files::State::Waiting);
}

#[test]
fn the_download_policy_decides_what_starts_alone() {
    let (mut alice, mut bob) = pair();
    let strict = crate::downloads::Policy {
        limit: crate::downloads::Limit::Small,
        only_verified: true,
    };
    crate::downloads::set(bob.store.conn(), strict).unwrap();
    crate::contacts::set_verified(bob.store.conn(), bob.other, false).unwrap();
    // De um contato não verificado, nem o pequeno baixa sozinho.
    offer(&mut alice, 1, 32, 10);
    post(&mut alice, &mut bob);
    let state = |bob: &Device, index: usize| {
        let id = bob.list()[index].id;
        crate::files::by_message(bob.store.conn(), id)
            .unwrap()
            .unwrap()
            .state
    };
    assert_eq!(state(&bob, 0), crate::files::State::Waiting);
    // Verificado, o pequeno baixa e o acima do limite espera.
    crate::contacts::set_verified(bob.store.conn(), bob.other, true).unwrap();
    offer(&mut alice, 2, 32, 10);
    offer(&mut alice, 3, 32, (4 << 20) + 1);
    post(&mut alice, &mut bob);
    assert_eq!(state(&bob, 1), crate::files::State::Downloading);
    assert_eq!(state(&bob, 2), crate::files::State::Waiting);
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

#[test]
fn the_mailbox_reaches_contacts_and_the_delivered_receipt_closes_it() {
    use crate::mailbox::{self, proto};
    let (mut alice, mut bob) = pair();
    // Bob liga uma caixa: Alice fica sabendo, com uma ficha só dela, uma vez.
    mailbox::set(bob.store.conn(), &[8; 32], &["192.168.0.9:47474".into()], 1).unwrap();
    assert_eq!(send_mailbox(&mut bob.store).unwrap(), vec![bob.other]);
    assert!(send_mailbox(&mut bob.store).unwrap().is_empty());
    assert_eq!(
        post(&mut bob, &mut alice),
        vec![Effect::Contact(alice.other)]
    );
    let theirs = mailbox::theirs(alice.store.conn(), alice.other)
        .unwrap()
        .unwrap();
    assert_eq!(theirs.endpoint_id, [8; 32]);
    assert_eq!(theirs.addrs, ["192.168.0.9:47474"]);
    let hash = proto::hash(&theirs.drop);
    assert_eq!(
        mailbox::drops(bob.store.conn()).unwrap(),
        vec![hash.to_vec()]
    );
    let at_bob = mailbox::contact_by_drop(bob.store.conn(), &hash)
        .unwrap()
        .unwrap();
    assert_eq!(at_bob.id, bob.other);

    // Alice deixa na caixa: a mensagem fica "na caixa postal" até o recibo.
    send_text(&mut alice.store, alice.other, "oi", None).unwrap();
    let out = next_out(alice.store.conn(), alice.other).unwrap().unwrap();
    assert!(mailbox::deposited(alice.store.conn(), out.id).unwrap());
    assert_eq!(alice.outbox(), 0);
    assert!(alice.list()[0].in_mailbox);
    let (effect, shown) =
        receive_from(&mut bob.store, &at_bob, out.prekey, &out.ciphertext).unwrap();
    assert_eq!(effect, Effect::Messages(bob.other));
    send_delivered(&mut bob.store, bob.other, &[shown.unwrap()]).unwrap();
    post(&mut bob, &mut alice);
    let sent = &alice.list()[0];
    assert_eq!((sent.status, sent.in_mailbox), (Status::Delivered, false));

    // Bob desliga a caixa: Alice esquece.
    mailbox::clear(bob.store.conn()).unwrap();
    assert_eq!(send_mailbox(&mut bob.store).unwrap(), vec![bob.other]);
    post(&mut bob, &mut alice);
    assert_eq!(
        mailbox::theirs(alice.store.conn(), alice.other).unwrap(),
        None
    );
}

#[test]
fn a_bad_mailbox_from_a_contact_is_ignored() {
    let (mut alice, mut bob) = pair();
    let me = session::me(&bob.store).unwrap();
    let contact = contacts::by_id(bob.store.conn(), bob.other).unwrap();
    enqueue(
        bob.store.conn(),
        &me,
        &contact,
        ContentBody::Mailbox(wire::MailboxInfo {
            endpoint_id: vec![1; 31],
            addrs: vec![],
            drop: vec![2; 32],
        }),
        0,
        now_ms(),
        false,
    )
    .unwrap();
    assert_eq!(post(&mut bob, &mut alice), vec![Effect::Nothing]);
    assert_eq!(
        crate::mailbox::theirs(alice.store.conn(), alice.other).unwrap(),
        None
    );
}

#[test]
fn the_profile_photo_goes_only_to_who_should_see_it() {
    use crate::photo::{self, Visibility};
    let (mut alice, mut bob) = pair();
    let theirs = |d: &Device| contacts::by_id(d.store.conn(), d.other).unwrap().photo;
    // Sem foto, ninguém recebe nada.
    assert!(send_photos(&mut alice.store).unwrap().is_empty());

    let png = {
        let mut out = Vec::new();
        image::DynamicImage::new_rgb8(600, 400)
            .write_to(&mut std::io::Cursor::new(&mut out), image::ImageFormat::Png)
            .unwrap();
        out
    };
    let jpeg = photo::prepare(&png).unwrap();
    photo::set_own(alice.store.conn(), Some(&jpeg)).unwrap();
    assert_eq!(send_photos(&mut alice.store).unwrap(), vec![alice.other]);
    assert!(
        send_photos(&mut alice.store).unwrap().is_empty(),
        "uma vez só"
    );
    assert_eq!(post(&mut alice, &mut bob), vec![Effect::Contact(bob.other)]);
    assert_eq!(theirs(&bob), Some(jpeg.clone()));

    // Só os marcados, e Bob não está: a foto sai do app dele.
    photo::set_visibility(alice.store.conn(), Visibility::Chosen).unwrap();
    assert_eq!(send_photos(&mut alice.store).unwrap(), vec![alice.other]);
    post(&mut alice, &mut bob);
    assert_eq!(theirs(&bob), None);
    // Marcado, volta.
    photo::set_allowed(alice.store.conn(), alice.other, true).unwrap();
    send_photos(&mut alice.store).unwrap();
    post(&mut alice, &mut bob);
    assert_eq!(theirs(&bob), Some(jpeg));
    // Ninguém.
    photo::set_visibility(alice.store.conn(), Visibility::Nobody).unwrap();
    send_photos(&mut alice.store).unwrap();
    post(&mut alice, &mut bob);
    assert_eq!(theirs(&bob), None);

    // Uma foto que não é foto é ignorada.
    let me = session::me(&bob.store).unwrap();
    let contact = contacts::by_id(bob.store.conn(), bob.other).unwrap();
    enqueue(
        bob.store.conn(),
        &me,
        &contact,
        ContentBody::Photo(wire::PeerPhoto {
            jpeg: vec![0xFF, 0xD8, 1, 2, 3],
        }),
        0,
        now_ms(),
        false,
    )
    .unwrap();
    assert_eq!(post(&mut bob, &mut alice), vec![Effect::Nothing]);
    assert_eq!(theirs(&alice), None);
}

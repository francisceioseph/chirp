//! Os grupos sem rede: alguns aparelhos, contatos entre si como cada teste pede, e um
//! "carteiro" que leva a caixa de saída de cada um ao aparelho certo.

use super::*;
use crate::messages::{self, Status};
use crate::session::{accept_hello, accept_welcome, bundle_for, create_invite, join, InviteKind};
use crate::wire::Peer;

struct Device {
    store: Store,
    endpoint: [u8; 32],
}

impl Device {
    fn new(name: &str, n: u8) -> Self {
        let mut store = Store::memory();
        store.create_profile(name).unwrap();
        Self {
            store,
            endpoint: [n; 32],
        }
    }

    fn key(&self) -> Vec<u8> {
        session::me(&self.store).unwrap().public()
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

    /// O contato do outro aparelho neste.
    fn contact(&self, other: &Device) -> i64 {
        contacts::by_identity(self.store.conn(), &other.key())
            .unwrap()
            .unwrap()
            .id
    }

    /// A conversa do grupo neste aparelho (o único grupo).
    fn group(&self) -> Option<Group> {
        let id: Option<i64> = self
            .store
            .conn()
            .query_row("SELECT contact_id FROM groups", [], |r| r.get(0))
            .optional()
            .unwrap();
        id.map(|id| get(self.store.conn(), &self.key(), id).unwrap())
    }

    fn texts(&self) -> Vec<(String, Option<Vec<u8>>)> {
        let g = self.group().unwrap();
        messages::list(self.store.conn(), g.id, None, 100)
            .unwrap()
            .into_iter()
            .filter(|m| !m.deleted)
            .map(|m| (m.body, m.author))
            .collect()
    }
}

fn befriend(a: &mut Device, b: &mut Device) {
    let invite = create_invite(&mut a.store, InviteKind::Qr, a.endpoint, vec![], None).unwrap();
    let bundle = bundle_for(&a.store, &invite.token).unwrap();
    let b_peer = b.peer();
    let (pending, hello) = join(&mut b.store, &invite, &bundle, b_peer, true, None).unwrap();
    let a_peer = a.peer();
    let (_, welcome, _) = accept_hello(
        &mut a.store,
        crate::session::HelloFrom::Node(&b.endpoint),
        &hello,
        a_peer,
    )
    .unwrap();
    accept_welcome(&mut b.store, pending.id, &a.endpoint, &welcome).unwrap();
}

/// Leva tudo que espera em todas as caixas de saída, até não sobrar nada.
fn post(devices: &mut [&mut Device]) {
    loop {
        let mut moved = false;
        for i in 0..devices.len() {
            loop {
                let row: Option<(i64, Vec<u8>)> = devices[i]
                    .store
                    .conn()
                    .query_row(
                        "SELECT o.id, c.identity_key FROM outbox o
                           JOIN contacts c ON c.id = o.contact_id ORDER BY o.id LIMIT 1",
                        [],
                        |r| Ok((r.get(0)?, r.get(1)?)),
                    )
                    .optional()
                    .unwrap();
                let Some((outbox_id, to_key)) = row else {
                    break;
                };
                let out: (bool, Vec<u8>) = devices[i]
                    .store
                    .conn()
                    .query_row(
                        "SELECT prekey, ciphertext FROM outbox WHERE id = ?1",
                        [outbox_id],
                        |r| Ok((r.get(0)?, r.get(1)?)),
                    )
                    .unwrap();
                let from = devices[i].endpoint;
                let j = (0..devices.len())
                    .find(|j| devices[*j].key() == to_key)
                    .unwrap();
                messages::receive(&mut devices[j].store, &from, out.0, &out.1).unwrap();
                messages::delivered(devices[i].store.conn(), outbox_id).unwrap();
                moved = true;
            }
        }
        if !moved {
            return;
        }
    }
}

fn three() -> (Device, Device, Device) {
    let (mut ana, mut bia, mut caio) = (
        Device::new("Ana", 1),
        Device::new("Bia", 2),
        Device::new("Caio", 3),
    );
    befriend(&mut ana, &mut bia);
    befriend(&mut ana, &mut caio);
    befriend(&mut bia, &mut caio);
    (ana, bia, caio)
}

#[test]
fn a_group_is_made_and_everyone_talks_in_it() {
    let (mut ana, mut bia, mut caio) = three();
    let ids = [ana.contact(&bia), ana.contact(&caio)];
    let group = create(&mut ana.store, "Calopsitas", &ids).unwrap();
    assert_eq!(group.state, ContactState::Group);
    post(&mut [&mut ana, &mut bia, &mut caio]);

    for d in [&bia, &caio] {
        let g = d.group().unwrap();
        assert_eq!(g.name, "Calopsitas");
        assert!(g.active && !g.i_am_admin);
        assert_eq!(g.admin, ana.key());
        assert_eq!(g.members.len(), 2);
        assert!(g.members.iter().all(|m| m.contact.is_some()));
    }
    assert!(ana.group().unwrap().i_am_admin);

    let sent = messages::send_text(&mut ana.store, group.id, "oi, bando", None).unwrap();
    assert_eq!(sent.status, Status::Pending);
    let bia_group = bia.group().unwrap().id;
    messages::send_text(&mut bia.store, bia_group, "piu", None).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);

    let from = |d: &Device| Some(d.key());
    assert_eq!(
        caio.texts(),
        [("oi, bando".into(), from(&ana)), ("piu".into(), from(&bia))]
    );
    assert_eq!(
        ana.texts(),
        [("oi, bando".into(), None), ("piu".into(), from(&bia))]
    );
    // Entregue: chegou aos dois.
    assert_eq!(
        messages::by_id(ana.store.conn(), sent.id).unwrap().status,
        Status::Delivered
    );
    // A conversa a dois não vê nada do grupo.
    let ana_at_caio = caio.contact(&ana);
    assert!(messages::list(caio.store.conn(), ana_at_caio, None, 10)
        .unwrap()
        .is_empty());
}

#[test]
fn edits_and_deletes_reach_the_group_only_from_the_author() {
    let (mut ana, mut bia, mut caio) = three();
    let ids = [ana.contact(&bia), ana.contact(&caio)];
    let group = create(&mut ana.store, "Calopsitas", &ids).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    let sent = messages::send_text(&mut ana.store, group.id, "errado", None).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    messages::edit(&mut ana.store, sent.id, "certo").unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert_eq!(bia.texts()[0].0, "certo");

    // Bia não apaga a mensagem de Ana nos outros: um Delete dela não acha a mensagem.
    let bia_group = bia.group().unwrap();
    let forged = wire::Delete {
        target: sent.message_id.clone(),
    };
    let me = session::me(&bia.store).unwrap();
    let w = writable(bia.store.conn(), bia_group.id).unwrap().unwrap();
    fanout(
        bia.store.conn(),
        &me,
        &w,
        ContentBody::Delete(forged),
        99,
        messages::now_ms(),
    )
    .unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert_eq!(caio.texts()[0].0, "certo");

    messages::delete_for_everyone(&mut ana.store, sent.id).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert!(caio.texts().is_empty());
}

#[test]
fn only_the_admin_changes_the_group() {
    let (mut ana, mut bia, mut caio) = three();
    let ids = [ana.contact(&bia), ana.contact(&caio)];
    let group = create(&mut ana.store, "Calopsitas", &ids).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    let bia_group = bia.group().unwrap().id;
    assert_eq!(
        rename(&mut bia.store, bia_group, "Meu"),
        Err(CoreError::NotAdmin)
    );

    // Bia forja um grupo com versão maior, dizendo-se admin: Caio ignora.
    let me = session::me(&bia.store).unwrap();
    let mut update = update_of(bia.store.conn(), &me, bia_group).unwrap();
    update.admin = me.public();
    update.version = 50;
    update.name = "Tomado".into();
    send_to(
        bia.store.conn(),
        &me,
        &[caio.key()],
        &[],
        ContentBody::Group(update),
        0,
        messages::now_ms(),
    )
    .unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert_eq!(caio.group().unwrap().name, "Calopsitas");

    rename(&mut ana.store, group.id, "Calopsitas e cia").unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert_eq!(caio.group().unwrap().name, "Calopsitas e cia");
    assert_eq!(caio.group().unwrap().version, 2);
}

#[test]
fn a_removed_member_stops_receiving_and_knows_it() {
    let (mut ana, mut bia, mut caio) = three();
    let ids = [ana.contact(&bia), ana.contact(&caio)];
    let group = create(&mut ana.store, "Calopsitas", &ids).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);

    remove(&mut ana.store, group.id, &caio.key()).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    let at_caio = caio.group().unwrap();
    assert!(!at_caio.active && at_caio.members.is_empty());
    assert_eq!(bia.group().unwrap().members.len(), 1);
    assert_eq!(
        messages::send_text(&mut caio.store, at_caio.id, "ei", None).map(|_| ()),
        Err(CoreError::NotAMember)
    );

    messages::send_text(&mut ana.store, group.id, "sem o Caio", None).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert_eq!(bia.texts().len(), 1);
    assert!(caio.texts().is_empty());

    // Adicionado de novo, volta a receber.
    let caio_at_ana = ana.contact(&caio);
    add(&mut ana.store, group.id, &[caio_at_ana]).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert!(caio.group().unwrap().active);
    messages::send_text(&mut ana.store, group.id, "voltou", None).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert_eq!(caio.texts().last().unwrap().0, "voltou");
}

#[test]
fn when_the_admin_leaves_the_smallest_key_takes_over() {
    let (mut ana, mut bia, mut caio) = three();
    let ids = [ana.contact(&bia), ana.contact(&caio)];
    let group = create(&mut ana.store, "Calopsitas", &ids).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    leave(&mut ana.store, group.id).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);

    assert!(!ana.group().unwrap().active);
    let next = bia.key().min(caio.key());
    for d in [&bia, &caio] {
        let g = d.group().unwrap();
        assert_eq!(g.admin, next);
        assert_eq!(g.members.len(), 1);
    }
    let (admin, other) = if bia.key() == next {
        (&mut bia, &mut caio)
    } else {
        (&mut caio, &mut bia)
    };
    let id = admin.group().unwrap().id;
    rename(&mut admin.store, id, "Sem a Ana").unwrap();
    post(&mut [&mut ana, admin, other]);
    assert_eq!(other.group().unwrap().name, "Sem a Ana");
    // Ana saiu: não volta pelo grupo novo (não está nele).
    assert_eq!(ana.group().unwrap().name, "Calopsitas");
}

#[test]
fn a_member_who_is_not_my_contact_shows_but_gets_nothing_from_me() {
    let (mut ana, mut bia, mut caio) = (
        Device::new("Ana", 1),
        Device::new("Bia", 2),
        Device::new("Caio", 3),
    );
    befriend(&mut ana, &mut bia);
    befriend(&mut ana, &mut caio);
    let ids = [ana.contact(&bia), ana.contact(&caio)];
    create(&mut ana.store, "Calopsitas", &ids).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    let g = bia.group().unwrap();
    let caio_there = g.members.iter().find(|m| m.name == "Caio").unwrap();
    assert!(caio_there.contact.is_none());
    messages::send_text(&mut bia.store, g.id, "oi", None).unwrap();
    post(&mut [&mut ana, &mut bia, &mut caio]);
    assert_eq!(ana.texts().len(), 1);
    assert!(caio.texts().is_empty());
}

#[test]
fn strange_updates_are_ignored() {
    let (mut ana, bia, caio) = three();
    let ids = [ana.contact(&bia), ana.contact(&caio)];
    create(&mut ana.store, "Calopsitas", &ids).unwrap();
    let me = session::me(&ana.store).unwrap();
    let id = ana.group().unwrap().id;
    let good = update_of(ana.store.conn(), &me, id).unwrap();
    let mut cases = vec![];
    let mut u = good.clone();
    u.group_id = vec![1; 3];
    cases.push(u);
    let mut u = good.clone();
    u.admin = vec![7; 33];
    cases.push(u);
    let mut u = good.clone();
    u.members.push(u.members[0].clone());
    cases.push(u);
    let mut u = good.clone();
    u.name = "\u{202e}x".into();
    cases.push(u);
    let mut u = good.clone();
    u.members.retain(|m| m.identity_key != bia.key());
    cases.push(u);
    let sender = contacts::by_identity(bia.store.conn(), &ana.key())
        .unwrap()
        .unwrap();
    for u in cases {
        assert_eq!(
            apply_update(bia.store.conn(), &bia.key(), &sender, u).unwrap(),
            Effect::Nothing
        );
    }
    assert!(bia.group().is_none());
}

//! O aperto de mão sem rede: dois (e três) aparelhos, cada um com o banco dele.

use super::*;

struct Device {
    store: Store,
    endpoint: [u8; 32],
    peer: Peer,
}

impl Device {
    fn new(name: &str, endpoint: u8) -> Self {
        let mut store = Store::memory();
        store.create_profile(name).unwrap();
        let peer = Peer {
            endpoint_id: vec![endpoint; 32],
            addrs: vec![
                format!("192.168.0.{endpoint}:4000"),
                "not an address".to_owned(),
            ],
            discovery_key: local_keys(store.conn()).unwrap().discovery_key.to_vec(),
        };
        Self {
            store,
            endpoint: [endpoint; 32],
            peer,
        }
    }

    fn invite(&mut self, kind: InviteKind) -> Invite {
        let endpoint = self.endpoint;
        create_invite(&mut self.store, kind, endpoint, vec![], None).unwrap()
    }

    fn identity_key(&self) -> Vec<u8> {
        identity_pair(&self.store)
            .unwrap()
            .identity_key()
            .serialize()
            .to_vec()
    }

    fn contacts(&self) -> Vec<Contact> {
        contacts::list(self.store.conn()).unwrap()
    }

    fn count(&self, table: &str) -> i64 {
        self.store
            .conn()
            .query_row(&format!("SELECT count(*) FROM {table}"), [], |r| r.get(0))
            .unwrap()
    }
}

/// O aperto de mão inteiro: `guest` lê o convite de `host`.
fn handshake(host: &mut Device, guest: &mut Device, kind: InviteKind) -> (Contact, Contact) {
    let invite = host.invite(kind);
    let bundle = bundle_for(&host.store, &invite.token).unwrap();
    let guest_peer = guest.peer.clone();
    let (pending, hello) = join(
        &mut guest.store,
        &invite,
        &bundle,
        guest_peer,
        kind == InviteKind::Qr,
        None,
    )
    .unwrap();
    assert_eq!(pending.state, ContactState::Pending);
    let host_peer = host.peer.clone();
    let (at_host, welcome, _) = accept_hello(
        &mut host.store,
        crate::session::HelloFrom::Node(&guest.endpoint),
        &hello,
        host_peer,
    )
    .unwrap();
    let at_guest = accept_welcome(&mut guest.store, pending.id, &host.endpoint, &welcome).unwrap();
    (at_host, at_guest)
}

#[test]
fn a_qr_invite_verifies_only_the_reader_side() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let (at_alice, at_bob) = handshake(&mut alice, &mut bob, InviteKind::Qr);

    assert_eq!(at_alice.display_name, "Bob");
    assert_eq!(at_alice.identity_key, bob.identity_key());
    assert_eq!(at_alice.endpoint_id, bob.endpoint.to_vec());
    assert_eq!(at_alice.state, ContactState::Established);
    // Quem mostrou o QR não conferiu a chave de quem leu.
    assert!(!at_alice.verified);

    assert_eq!(at_bob.display_name, "Alice");
    assert_eq!(at_bob.identity_key, alice.identity_key());
    assert_eq!(at_bob.state, ContactState::Established);
    assert!(at_bob.verified);
    assert_eq!(at_bob.addrs, vec!["192.168.0.1:4000".to_owned()]);

    let a = safety_number(&alice.identity_key(), &bob.identity_key()).unwrap();
    let b = safety_number(&bob.identity_key(), &alice.identity_key()).unwrap();
    assert_eq!(a, b);
    assert_eq!(a.len(), 60);
    // A metade de cada um é a "Sua chave" do perfil.
    let own = crate::identity::fingerprint(&alice.identity_key()).replace(' ', "");
    assert!(a.contains(&own));

    // As prekeys do convite foram gastas dos dois tipos.
    assert_eq!(alice.count("prekeys"), 0);
    assert_eq!(alice.count("signed_prekeys"), 0);
    assert_eq!(alice.count("kyber_prekeys"), 0);
}

#[test]
fn a_link_invite_makes_unverified_contacts() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let (at_alice, at_bob) = handshake(&mut alice, &mut bob, InviteKind::Link);
    assert!(!at_alice.verified);
    assert!(!at_bob.verified);
}

#[test]
fn a_replayed_hello_is_refused_and_leaves_nothing() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let invite = alice.invite(InviteKind::Qr);
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let (_, hello) = join(
        &mut bob.store,
        &invite,
        &bundle,
        bob.peer.clone(),
        true,
        None,
    )
    .unwrap();
    let peer = alice.peer.clone();
    accept_hello(
        &mut alice.store,
        crate::session::HelloFrom::Node(&bob.endpoint),
        &hello,
        peer.clone(),
    )
    .unwrap();
    assert_eq!(
        accept_hello(
            &mut alice.store,
            crate::session::HelloFrom::Node(&bob.endpoint),
            &hello,
            peer
        ),
        Err(CoreError::AlreadyExists)
    );
    assert_eq!(alice.contacts().len(), 1);
}

#[test]
fn a_spent_or_unknown_token_gets_no_bundle() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let invite = alice.invite(InviteKind::Qr);
    handshake_with(&mut alice, &mut bob, &invite);
    // Mallory fotografou o QR: o token já foi gasto.
    assert_eq!(
        bundle_for(&alice.store, &invite.token).err(),
        Some(CoreError::InviteRefused)
    );
    assert_eq!(
        bundle_for(&alice.store, &[7; 32]).err(),
        Some(CoreError::InviteRefused)
    );
}

fn handshake_with(host: &mut Device, guest: &mut Device, invite: &Invite) {
    let bundle = bundle_for(&host.store, &invite.token).unwrap();
    let (pending, hello) = join(
        &mut guest.store,
        invite,
        &bundle,
        guest.peer.clone(),
        true,
        None,
    )
    .unwrap();
    let (_, welcome, _) = accept_hello(
        &mut host.store,
        crate::session::HelloFrom::Node(&guest.endpoint),
        &hello,
        host.peer.clone(),
    )
    .unwrap();
    accept_welcome(&mut guest.store, pending.id, &host.endpoint, &welcome).unwrap();
}

#[test]
fn an_expired_invite_is_refused() {
    let mut alice = Device::new("Alice", 1);
    let invite = alice.invite(InviteKind::Link);
    alice
        .store
        .conn()
        .execute("UPDATE invites SET expires_at = 0", [])
        .unwrap();
    assert_eq!(
        bundle_for(&alice.store, &invite.token).err(),
        Some(CoreError::InviteRefused)
    );
}

#[test]
fn a_hello_from_another_node_is_refused_and_rolled_back() {
    // Mallory repassa o Hello de Bob pela conexão dela: o nó não bate.
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let invite = alice.invite(InviteKind::Qr);
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let (_, hello) = join(
        &mut bob.store,
        &invite,
        &bundle,
        bob.peer.clone(),
        true,
        None,
    )
    .unwrap();
    let mallory_node = [66u8; 32];
    assert_eq!(
        accept_hello(
            &mut alice.store,
            crate::session::HelloFrom::Node(&mallory_node),
            &hello,
            alice.peer.clone()
        ),
        Err(CoreError::Protocol)
    );
    assert!(alice.contacts().is_empty());
    assert_eq!(alice.count("sessions"), 0);
    assert_eq!(alice.count("identities"), 0);
    // E o convite continua valendo para o Bob de verdade.
    let (_, welcome, _) = accept_hello(
        &mut alice.store,
        crate::session::HelloFrom::Node(&bob.endpoint),
        &hello,
        alice.peer.clone(),
    )
    .unwrap();
    assert!(!welcome.is_empty());
}

#[test]
fn a_tampered_bundle_is_caught_by_the_signature() {
    // Mallory, no meio, troca a prekey assinada pela dela.
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let mut mallory = Device::new("Mallory", 3);
    let invite = alice.invite(InviteKind::Qr);
    let mut bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let fake_invite = mallory.invite(InviteKind::Qr);
    let fake = bundle_for(&mallory.store, &fake_invite.token).unwrap();
    bundle.signed_prekey = fake.signed_prekey;
    assert!(join(
        &mut bob.store,
        &invite,
        &bundle,
        bob.peer.clone(),
        true,
        None
    )
    .is_err());
    assert!(bob.contacts().is_empty());
    assert_eq!(bob.count("sessions"), 0);
    // A Kyber também é assinada.
    let mut bundle = bundle_for(&alice.store, &invite.token).unwrap();
    bundle.kyber_prekey = fake.kyber_prekey.clone();
    assert!(join(
        &mut bob.store,
        &invite,
        &bundle,
        bob.peer.clone(),
        true,
        None
    )
    .is_err());
    assert!(bob.contacts().is_empty());
}

#[test]
fn a_hello_for_someone_else_cannot_be_read() {
    // Mallory recebe o Hello que Bob mandou para Alice: não decifra.
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let mut mallory = Device::new("Mallory", 3);
    mallory.invite(InviteKind::Qr);
    let invite = alice.invite(InviteKind::Qr);
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let (_, hello) = join(
        &mut bob.store,
        &invite,
        &bundle,
        bob.peer.clone(),
        true,
        None,
    )
    .unwrap();
    assert!(accept_hello(
        &mut mallory.store,
        crate::session::HelloFrom::Node(&bob.endpoint),
        &hello,
        mallory.peer.clone()
    )
    .is_err());
    assert!(mallory.contacts().is_empty());
}

#[test]
fn a_welcome_from_another_node_or_a_stranger_is_refused() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let invite = alice.invite(InviteKind::Qr);
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let (pending, hello) = join(
        &mut bob.store,
        &invite,
        &bundle,
        bob.peer.clone(),
        true,
        None,
    )
    .unwrap();
    let (_, welcome, _) = accept_hello(
        &mut alice.store,
        crate::session::HelloFrom::Node(&bob.endpoint),
        &hello,
        alice.peer.clone(),
    )
    .unwrap();
    // Pela conexão de outro nó.
    assert_eq!(
        accept_welcome(&mut bob.store, pending.id, &[66; 32], &welcome),
        Err(CoreError::Protocol)
    );
    // Um "aceite" que não responde a pedido nosso (o S1 do protótipo).
    assert!(accept_welcome(&mut bob.store, pending.id, &alice.endpoint, &[1, 2, 3]).is_err());
    assert_eq!(bob.contacts()[0].state, ContactState::Pending);
    // O de verdade fecha.
    let done = accept_welcome(&mut bob.store, pending.id, &alice.endpoint, &welcome).unwrap();
    assert_eq!(done.state, ContactState::Established);
    // E não fecha duas vezes.
    assert_eq!(
        accept_welcome(&mut bob.store, pending.id, &alice.endpoint, &welcome),
        Err(CoreError::Protocol)
    );
}

#[test]
fn reading_your_own_invite_or_a_known_contact_is_refused() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let invite = alice.invite(InviteKind::Qr);
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let peer = alice.peer.clone();
    assert_eq!(
        join(&mut alice.store, &invite, &bundle, peer, true, None).err(),
        Some(CoreError::OwnInvite)
    );
    handshake(&mut alice, &mut bob, InviteKind::Qr);
    let again = alice.invite(InviteKind::Qr);
    let bundle = bundle_for(&alice.store, &again.token).unwrap();
    assert_eq!(
        join(
            &mut bob.store,
            &again,
            &bundle,
            bob.peer.clone(),
            true,
            None
        )
        .err(),
        Some(CoreError::AlreadyExists)
    );
}

#[test]
fn without_a_profile_there_is_no_invite() {
    let mut store = Store::memory();
    assert_eq!(
        create_invite(&mut store, InviteKind::Qr, [1; 32], vec![], None).err(),
        Some(CoreError::NoProfile)
    );
}

#[test]
fn dead_invites_and_their_prekeys_are_cleaned_up() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    alice.invite(InviteKind::Qr);
    alice
        .store
        .conn()
        .execute("UPDATE invites SET expires_at = 0", [])
        .unwrap();
    let invite = alice.invite(InviteKind::Qr);
    handshake_with(&mut alice, &mut bob, &invite);
    // O vencido saiu ao criar o segundo; o usado sai ao criar o próximo.
    assert_eq!(alice.count("invites"), 1);
    alice.invite(InviteKind::Qr);
    assert_eq!(alice.count("invites"), 1);
    assert_eq!(alice.count("prekeys"), 1);
    assert_eq!(alice.count("signed_prekeys"), 1);
    assert_eq!(alice.count("kyber_prekeys"), 1);
}

#[test]
fn bad_peer_data_is_dropped_or_refused() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let (_, at_bob) = handshake(&mut alice, &mut bob, InviteKind::Qr);
    // O endereço que não se lê ficou de fora.
    assert_eq!(at_bob.addrs, vec!["192.168.0.1:4000".to_owned()]);
    // Uma chave de descoberta do tamanho errado derruba o Hello.
    let mut carol = Device::new("Carol", 3);
    carol.peer.discovery_key = vec![1, 2, 3];
    let invite = alice.invite(InviteKind::Qr);
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let (_, hello) = join(
        &mut carol.store,
        &invite,
        &bundle,
        carol.peer.clone(),
        true,
        None,
    )
    .unwrap();
    assert_eq!(
        accept_hello(
            &mut alice.store,
            crate::session::HelloFrom::Node(&carol.endpoint),
            &hello,
            alice.peer.clone()
        ),
        Err(CoreError::Protocol)
    );
}

#[test]
fn a_hello_from_the_mailbox_counts_from_when_it_arrived_and_takes_no_known_node() {
    let mut alice = Device::new("Alice", 1);
    let mut bob = Device::new("Bob", 2);
    let mut carol = Device::new("Carol", 3);
    // Carol já é contato de Alice.
    handshake(&mut alice, &mut carol, InviteKind::Qr);

    let invite = alice.invite(InviteKind::Link);
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let info = wire::MailboxInfo {
        endpoint_id: vec![8; 32],
        addrs: vec![],
        drop: vec![9; 32],
    };
    let (_, hello) = join(
        &mut bob.store,
        &invite,
        &bundle,
        bob.peer.clone(),
        false,
        Some(info.clone()),
    )
    .unwrap();
    // O convite venceu há pouco: o Hello guardado na caixa depois disso é recusado.
    let now = now_secs() as i64;
    alice
        .store
        .conn()
        .execute("UPDATE invites SET expires_at = ?1", [now - 10])
        .unwrap();
    assert!(matches!(
        accept_hello(
            &mut alice.store,
            HelloFrom::Mailbox(now as u64),
            &hello,
            alice.peer.clone()
        ),
        Err(CoreError::InviteRefused)
    ));
    // Guardado antes de vencer, vale mesmo lido depois, e traz a caixa de quem leu.
    let (contact, _, theirs) = accept_hello(
        &mut alice.store,
        HelloFrom::Mailbox(now as u64 - 100),
        &hello,
        alice.peer.clone(),
    )
    .unwrap();
    assert_eq!(contact.display_name, "Bob");
    assert_eq!(theirs, Some(info));

    // Um Hello pela caixa que diz ser o nó de Carol é recusado, sem deixar nada.
    let mut mallory = Device::new("Mallory", 3);
    let invite = alice.invite(InviteKind::Link);
    let bundle = bundle_for(&alice.store, &invite.token).unwrap();
    let (_, hello) = join(
        &mut mallory.store,
        &invite,
        &bundle,
        mallory.peer.clone(),
        false,
        None,
    )
    .unwrap();
    let before = alice.contacts().len();
    assert!(accept_hello(
        &mut alice.store,
        HelloFrom::Mailbox(now_secs()),
        &hello,
        alice.peer.clone()
    )
    .is_err());
    assert_eq!(alice.contacts().len(), before);
}

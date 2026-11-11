//! O nó da rede: um endpoint do iroh (QUIC, TLS 1.3 com a chave do nó) só para a rede
//! local nesta fase (docs/PLANO.md, 7.2).
//!
//! Sem relay, sem descoberta por servidor e sem UPnP (o preset `Minimal`, com o relay
//! desligado e as features padrão do iroh fora): o nó só fala com os endereços que um
//! convite ou um contato deram. Nenhum pacote vai para terceiros.
//!
//! Cada conexão é um aperto de mão (o `session`): no máximo quatro frames, em até
//! `HANDSHAKE_TIMEOUT`.

use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use iroh::address_lookup::MemoryLookup;
use iroh::endpoint::{presets, Connection, RelayMode};
use iroh::{Endpoint, EndpointAddr, EndpointId, SecretKey};
use tokio::sync::broadcast;

use crate::contacts::Contact;
use crate::error::{CoreError, CoreResult};
use crate::invite::Invite;
use crate::session::{self, InviteKind};
use crate::store::Store;
use crate::wire::{self, Body, Peer};

pub const ALPN: &[u8] = b"chirp/1";
const HANDSHAKE_TIMEOUT: Duration = Duration::from_secs(20);
const MAX_FRAMES: usize = 4;
/// Quantos apertos de mão ao mesmo tempo; os de além esperam.
const MAX_HANDSHAKES: usize = 8;

/// O que muda no núcleo sem a UI pedir.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NodeEvent {
    /// Um contato novo ou mudado (o id).
    ContactChanged(i64),
}

pub type SharedStore = Arc<Mutex<Store>>;

pub struct Node {
    endpoint: Endpoint,
    lookup: MemoryLookup,
    store: SharedStore,
    events: broadcast::Sender<NodeEvent>,
    discovery_key: Vec<u8>,
}

/// Um endereço da rede local: IPv4 privado (RFC 1918) ou IPv6 local único (fc00::/7).
/// O link-local do IPv6 fica de fora, porque sem a interface não se usa.
fn is_local(addr: &SocketAddr) -> bool {
    match addr.ip() {
        std::net::IpAddr::V4(ip) => ip.is_private(),
        std::net::IpAddr::V6(ip) => (ip.segments()[0] & 0xfe00) == 0xfc00,
    }
}

fn lock(store: &SharedStore) -> CoreResult<std::sync::MutexGuard<'_, Store>> {
    store.lock().map_err(|_| CoreError::Storage)
}

/// Roda um trabalho síncrono no banco fora das threads do tokio.
async fn with_store<T: Send + 'static>(
    store: &SharedStore,
    work: impl FnOnce(&mut Store) -> CoreResult<T> + Send + 'static,
) -> CoreResult<T> {
    let store = store.clone();
    tokio::task::spawn_blocking(move || work(&mut *lock(&store)?))
        .await
        .map_err(|_| CoreError::Storage)?
}

impl Node {
    /// Liga o nó, com a chave guardada no banco, em todas as interfaces.
    pub async fn start(store: SharedStore) -> CoreResult<Arc<Node>> {
        let keys = with_store(&store, |s| session::local_keys(s.conn())).await?;
        let secret = SecretKey::from_bytes(&keys.endpoint_secret);
        let lookup = MemoryLookup::new();
        let endpoint = Endpoint::builder(presets::Minimal)
            .relay_mode(RelayMode::Disabled)
            .clear_address_lookup()
            .address_lookup(lookup.clone())
            .secret_key(secret)
            .alpns(vec![ALPN.to_vec()])
            .bind()
            .await
            .map_err(|_| CoreError::Unreachable)?;
        let (events, _) = broadcast::channel(64);
        let node = Arc::new(Node {
            endpoint,
            lookup,
            store,
            events,
            discovery_key: keys.discovery_key.to_vec(),
        });
        let accepting = node.clone();
        tokio::spawn(async move { accepting.accept_loop().await });
        Ok(node)
    }

    pub fn id(&self) -> [u8; 32] {
        *self.endpoint.id().as_bytes()
    }

    pub fn subscribe(&self) -> broadcast::Receiver<NodeEvent> {
        self.events.subscribe()
    }

    /// Os endereços de agora na rede local, para o convite e para os contatos. Só os
    /// privados: um link mandado por outro canal não leva o IP público de ninguém (a
    /// internet é a fase 5). Sem nenhum, o loopback, que só serve no mesmo aparelho.
    pub fn addrs(&self) -> Vec<SocketAddr> {
        let all: Vec<SocketAddr> = self.endpoint.addr().ip_addrs().copied().collect();
        let mut addrs: Vec<SocketAddr> = all.iter().copied().filter(is_local).collect();
        if addrs.is_empty() {
            addrs = all.into_iter().filter(|a| a.ip().is_loopback()).collect();
        }
        addrs.sort_by_key(|a| a.is_ipv6());
        addrs.truncate(8);
        addrs
    }

    fn me(&self) -> Peer {
        Peer {
            endpoint_id: self.id().to_vec(),
            addrs: self.addrs().iter().map(|a| a.to_string()).collect(),
            discovery_key: self.discovery_key.clone(),
        }
    }

    pub async fn create_invite(&self, kind: InviteKind) -> CoreResult<Invite> {
        let (id, addrs) = (self.id(), self.addrs());
        with_store(&self.store, move |s| {
            session::create_invite(s, kind, id, addrs)
        })
        .await
    }

    /// Lê um convite: conecta a quem convidou e faz o aperto de mão inteiro.
    pub async fn join(&self, invite: Invite, verified: bool) -> CoreResult<Contact> {
        let remote =
            EndpointId::from_bytes(&invite.endpoint_id).map_err(|_| CoreError::InvalidInvite)?;
        if remote == self.endpoint.id() {
            return Err(CoreError::OwnInvite);
        }
        let addr = EndpointAddr::from_parts(
            remote,
            invite.addrs.iter().map(|a| iroh::TransportAddr::Ip(*a)),
        );
        self.lookup.add_endpoint_info(addr.clone());
        let conn = tokio::time::timeout(HANDSHAKE_TIMEOUT, self.endpoint.connect(addr, ALPN))
            .await
            .map_err(|_| CoreError::Unreachable)?
            .map_err(|_| CoreError::Unreachable)?;
        let result = tokio::time::timeout(HANDSHAKE_TIMEOUT, self.join_on(&conn, invite, verified))
            .await
            .unwrap_or(Err(CoreError::Unreachable));
        conn.close(0u32.into(), b"");
        result
    }

    async fn join_on(
        &self,
        conn: &Connection,
        invite: Invite,
        verified: bool,
    ) -> CoreResult<Contact> {
        let (mut send, mut recv) = conn.open_bi().await.map_err(|_| CoreError::Unreachable)?;
        let request = wire::frame(Body::BundleRequest(wire::BundleRequest {
            token: invite.token.to_vec(),
        }));
        wire::write_frame(&mut send, &request).await?;
        let bundle = match wire::read_frame(&mut recv).await? {
            Body::Bundle(bundle) => bundle,
            Body::Refused(_) => return Err(CoreError::InviteRefused),
            _ => return Err(CoreError::Protocol),
        };
        let me = self.me();
        let (pending, hello) = with_store(&self.store, move |s| {
            session::join(s, &invite, &bundle, me, verified)
        })
        .await?;
        let remote = *conn.remote_id().as_bytes();
        let result = async {
            wire::write_frame(&mut send, &wire::frame(Body::PreKeyMessage(hello))).await?;
            let welcome = match wire::read_frame(&mut recv).await? {
                Body::Message(welcome) => welcome,
                Body::Refused(_) => return Err(CoreError::InviteRefused),
                _ => return Err(CoreError::Protocol),
            };
            with_store(&self.store, move |s| {
                session::accept_welcome(s, pending.id, &remote, &welcome)
            })
            .await
        }
        .await;
        match result {
            Ok(contact) => {
                let _ = send.finish();
                let _ = self.events.send(NodeEvent::ContactChanged(contact.id));
                Ok(contact)
            }
            Err(error) => {
                // Sem o Welcome, o contato pendente e a sessão saem: dá para tentar de
                // novo com outro convite.
                let _ = with_store(&self.store, move |s| session::forget(s, pending.id)).await;
                Err(error)
            }
        }
    }

    async fn accept_loop(self: Arc<Self>) {
        let slots = Arc::new(tokio::sync::Semaphore::new(MAX_HANDSHAKES));
        while let Some(incoming) = self.endpoint.accept().await {
            let Ok(slot) = slots.clone().acquire_owned().await else {
                return;
            };
            let node = self.clone();
            tokio::spawn(async move {
                let _slot = slot;
                let Ok(conn) = incoming.await else { return };
                let _ = tokio::time::timeout(HANDSHAKE_TIMEOUT, node.serve(&conn)).await;
                conn.close(0u32.into(), b"");
            });
        }
    }

    /// O lado de quem convidou: responde ao pedido de prekeys e ao Hello.
    async fn serve(&self, conn: &Connection) -> CoreResult<()> {
        let remote = *conn.remote_id().as_bytes();
        let (mut send, mut recv) = conn.accept_bi().await.map_err(|_| CoreError::Unreachable)?;
        for _ in 0..MAX_FRAMES {
            let reply = match wire::read_frame(&mut recv).await? {
                Body::BundleRequest(request) => {
                    match with_store(&self.store, move |s| session::bundle_for(s, &request.token))
                        .await
                    {
                        Ok(bundle) => Body::Bundle(bundle),
                        Err(_) => Body::Refused(wire::Refused {}),
                    }
                }
                Body::PreKeyMessage(hello) => {
                    let me = self.me();
                    match with_store(&self.store, move |s| {
                        session::accept_hello(s, &remote, &hello, me)
                    })
                    .await
                    {
                        Ok((contact, welcome)) => {
                            wire::write_frame(&mut send, &wire::frame(Body::Message(welcome)))
                                .await?;
                            let _ = send.finish();
                            let _ = self.events.send(NodeEvent::ContactChanged(contact.id));
                            // Espera o outro lado ler antes de fechar.
                            let _ =
                                tokio::time::timeout(Duration::from_secs(5), conn.closed()).await;
                            return Ok(());
                        }
                        Err(_) => Body::Refused(wire::Refused {}),
                    }
                }
                _ => return Err(CoreError::Protocol),
            };
            wire::write_frame(&mut send, &wire::frame(reply)).await?;
        }
        Err(CoreError::Protocol)
    }

    pub async fn close(&self) {
        self.endpoint.close().await;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn device(name: &str) -> SharedStore {
        let mut store = Store::memory();
        store.create_profile(name).unwrap();
        Arc::new(Mutex::new(store))
    }

    fn contacts(store: &SharedStore) -> Vec<Contact> {
        crate::contacts::list(store.lock().unwrap().conn()).unwrap()
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn two_nodes_become_contacts_over_the_network() {
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start(alice_store.clone()).await.unwrap();
        let bob = Node::start(bob_store.clone()).await.unwrap();
        let mut alice_events = alice.subscribe();

        let invite = alice.create_invite(InviteKind::Qr).await.unwrap();
        assert!(!invite.addrs.is_empty());
        // O convite passa pelo link, como passaria pelo QR.
        let invite = Invite::from_link(&invite.to_link()).unwrap();
        let at_bob = bob.join(invite.clone(), true).await.unwrap();
        assert_eq!(at_bob.display_name, "Alice");
        assert_eq!(at_bob.state, crate::contacts::ContactState::Established);

        let event = tokio::time::timeout(Duration::from_secs(5), alice_events.recv())
            .await
            .unwrap()
            .unwrap();
        let NodeEvent::ContactChanged(id) = event;
        let at_alice = crate::contacts::by_id(alice_store.lock().unwrap().conn(), id).unwrap();
        assert_eq!(at_alice.display_name, "Bob");
        assert!(!at_alice.verified);
        assert!(at_bob.verified);
        assert_eq!(at_alice.endpoint_id, bob.id().to_vec());

        // O mesmo convite não serve para mais ninguém.
        let carol = Node::start(device("Carol")).await.unwrap();
        assert_eq!(
            carol.join(invite, true).await.err(),
            Some(CoreError::InviteRefused)
        );
        assert_eq!(contacts(&alice_store).len(), 1);

        for node in [alice, bob, carol] {
            node.close().await;
        }
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn an_impostor_node_cannot_take_an_invite_meant_for_another() {
        // Mallory conhece o convite (viu o QR), mas fala com a chave de nó dela: o
        // aperto de mão fecha com a identidade dela, não com a de Bob. Ninguém se passa
        // por ninguém: Alice fica com "Mallory", e Bob não ganha contato nenhum.
        let alice_store = device("Alice");
        let alice = Node::start(alice_store.clone()).await.unwrap();
        let mallory = Node::start(device("Mallory")).await.unwrap();
        let invite = alice.create_invite(InviteKind::Link).await.unwrap();
        let at_mallory = mallory.join(invite, false).await.unwrap();
        assert_eq!(at_mallory.display_name, "Alice");
        let at_alice = contacts(&alice_store);
        assert_eq!(at_alice[0].display_name, "Mallory");
        assert!(!at_alice[0].verified);
        alice.close().await;
        mallory.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn nobody_listening_is_unreachable_and_leaves_nothing() {
        let bob_store = device("Bob");
        let bob = Node::start(bob_store.clone()).await.unwrap();
        let alice = Node::start(device("Alice")).await.unwrap();
        let invite = alice.create_invite(InviteKind::Qr).await.unwrap();
        alice.close().await;
        assert!(bob.join(invite, true).await.is_err());
        assert!(contacts(&bob_store).is_empty());
        bob.close().await;
    }
}

#[cfg(test)]
mod addr_tests {
    use super::is_local;

    #[test]
    fn only_local_addresses_go_out() {
        for local in ["192.168.0.2:1", "10.1.2.3:1", "172.16.0.9:1", "[fd12::1]:1"] {
            assert!(is_local(&local.parse().unwrap()), "{local}");
        }
        for other in [
            "8.8.8.8:1",
            "127.0.0.1:1",
            "[2804:248::1]:1",
            "[fe80::1]:1",
            "[::1]:1",
        ] {
            assert!(!is_local(&other.parse().unwrap()), "{other}");
        }
    }
}

//! O nó da rede: um endpoint do iroh (QUIC, TLS 1.3 com a chave do nó) só para a rede
//! local nesta fase (docs/PLANO.md, 7.2).
//!
//! Sem relay, sem descoberta por servidor e sem UPnP (o preset `Minimal`, com o relay
//! desligado e as features padrão do iroh fora): o nó só fala com os endereços que um
//! convite ou um contato deram. Nenhum pacote vai para terceiros.
//!
//! Uma conexão que chega é de um de dois tipos, pelo nó de quem conecta:
//!
//! - de um contato: as mensagens dele, uma por frame, cada uma confirmada com `Ack`
//!   depois de gravada (`messages::receive`);
//! - de qualquer outro: um aperto de mão (o `session`), no máximo quatro frames em até
//!   `HANDSHAKE_TIMEOUT`.
//!
//! Para mandar, o nó esvazia a caixa de saída de cada contato numa conexão, na ordem,
//! e só tira um envelope com o `Ack`. Tenta de novo a cada `RETRY_INTERVAL`, quando
//! o contato fala com a gente, quando a descoberta (mDNS, `discovery`) o acha num
//! endereço novo e quando há algo novo na caixa.

use std::collections::{HashMap, HashSet};
use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use iroh::address_lookup::MemoryLookup;
use iroh::endpoint::{presets, Connection, IncomingAddr, RecvStream, RelayMode, SendStream};
use iroh::{Endpoint, EndpointAddr, EndpointId, SecretKey};
use tokio::sync::{broadcast, mpsc};

use crate::contacts::{self, Contact, ContactState};
use crate::discovery;
use crate::error::{CoreError, CoreResult};
use crate::invite::Invite;
use crate::messages::{self, Effect};
use crate::session::{self, InviteKind};
use crate::store::Store;
use crate::wire::{self, Body, Peer};

pub const ALPN: &[u8] = b"chirp/1";
const HANDSHAKE_TIMEOUT: Duration = Duration::from_secs(20);
const MAX_FRAMES: usize = 4;
/// Quantas conexões que chegam ao mesmo tempo; as de além esperam.
const MAX_INCOMING: usize = 16;
/// Para conectar a um contato.
const CONNECT_TIMEOUT: Duration = Duration::from_secs(5);
/// Uma conexão de mensagens sem nada por esse tempo é fechada.
const IDLE_TIMEOUT: Duration = Duration::from_secs(30);
/// Quantas mensagens numa conexão; o resto vai na próxima.
const MAX_MESSAGES: usize = 1024;
/// De quanto em quanto tempo a caixa de saída é tentada de novo.
const RETRY_INTERVAL: Duration = Duration::from_secs(20);
/// Um contato que falou com a gente (ou recebeu) há menos que isso está online.
const ONLINE_FOR: Duration = Duration::from_secs(90);
/// De quanto em quanto tempo o anúncio do mDNS é conferido (a época, os endereços).
const ANNOUNCE_CHECK: Duration = Duration::from_secs(60);

/// O que muda no núcleo sem a UI pedir.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NodeEvent {
    /// Um contato novo ou mudado (o id).
    ContactChanged(i64),
    /// A conversa com o contato mudou: chegou mensagem, recibo, edição.
    MessagesChanged(i64),
    /// O contato está digitando.
    Typing(i64),
}

pub type SharedStore = Arc<Mutex<Store>>;

pub struct Node {
    endpoint: Endpoint,
    lookup: MemoryLookup,
    store: SharedStore,
    events: broadcast::Sender<NodeEvent>,
    discovery_key: Vec<u8>,
    wake: mpsc::UnboundedSender<i64>,
    /// Os contatos sendo entregues agora, e os que pediram entrega de novo no meio.
    flushing: Mutex<(HashSet<i64>, HashSet<i64>)>,
    /// Quando cada contato falou com a gente (ou recebeu) pela última vez.
    seen: Mutex<HashMap<i64, Instant>>,
    /// O mDNS, quando o sistema deixa (no iOS, pede uma permissão da Apple).
    mdns: Option<mdns_sd::ServiceDaemon>,
    /// O anúncio de agora: o nome completo, o token e os endereços.
    announced: Mutex<Option<(String, String, Vec<SocketAddr>)>>,
}

/// Um endereço da rede local: IPv4 privado (RFC 1918) ou IPv6 local único (fc00::/7).
/// O link-local do IPv6 fica de fora, porque sem a interface não se usa.
pub(crate) fn is_local(addr: &SocketAddr) -> bool {
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
    /// Liga o nó, com a chave guardada no banco, em todas as interfaces. A porta é a da
    /// última vez, para os contatos acharem o aparelho onde ele estava; se ela estiver
    /// ocupada, vai outra, que fica guardada.
    pub async fn start(store: SharedStore) -> CoreResult<Arc<Node>> {
        let (keys, port) = with_store(&store, |s| {
            let keys = session::local_keys(s.conn())?;
            let port: u16 =
                s.conn()
                    .query_row("SELECT port FROM local_keys WHERE id = 1", [], |r| r.get(0))?;
            Ok((keys, port))
        })
        .await?;
        let lookup = MemoryLookup::new();
        let builder = |port: u16| -> CoreResult<iroh::endpoint::Builder> {
            let builder = Endpoint::builder(presets::Minimal)
                .relay_mode(RelayMode::Disabled)
                .clear_address_lookup()
                .address_lookup(lookup.clone())
                .secret_key(SecretKey::from_bytes(&keys.endpoint_secret))
                .alpns(vec![ALPN.to_vec()]);
            if port == 0 {
                return Ok(builder);
            }
            builder
                .clear_ip_transports()
                .bind_addr(SocketAddr::from(([0, 0, 0, 0], port)))
                .and_then(|b| b.bind_addr(SocketAddr::from(([0u16; 8], port))))
                .map_err(|_| CoreError::Unreachable)
        };
        let mut bound = match builder(port) {
            Ok(b) if port != 0 => b.bind().await.ok(),
            _ => None,
        };
        if bound.is_none() {
            bound = builder(0)?.bind().await.ok();
        }
        let endpoint = bound.ok_or(CoreError::Unreachable)?;
        if let Some(now) = endpoint
            .bound_sockets()
            .iter()
            .map(|a| a.port())
            .find(|p| *p != 0)
        {
            if now != port {
                let _ = with_store(&store, move |s| {
                    s.conn()
                        .execute("UPDATE local_keys SET port = ?1 WHERE id = 1", [now])?;
                    Ok(())
                })
                .await;
            }
        }
        let (events, _) = broadcast::channel(256);
        let (wake, woken) = mpsc::unbounded_channel();
        let node = Arc::new(Node {
            endpoint,
            lookup,
            store,
            events,
            discovery_key: keys.discovery_key.to_vec(),
            wake,
            flushing: Mutex::new((HashSet::new(), HashSet::new())),
            seen: Mutex::new(HashMap::new()),
            mdns: mdns_sd::ServiceDaemon::new().ok(),
            announced: Mutex::new(None),
        });
        tokio::spawn(node.clone().accept_loop());
        tokio::spawn(node.clone().delivery_loop(woken));
        tokio::spawn(node.clone().announce());
        tokio::spawn(node.clone().discovery_loop());
        Ok(node)
    }

    fn now_secs() -> u64 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0)
    }

    /// Anuncia pelo mDNS e procura os contatos, enquanto o nó estiver ligado.
    async fn discovery_loop(self: Arc<Self>) {
        let Some(daemon) = self.mdns.as_ref() else {
            return;
        };
        let Ok(found) = daemon.browse(discovery::SERVICE) else {
            return;
        };
        let mut tick = tokio::time::interval(ANNOUNCE_CHECK);
        loop {
            tokio::select! {
                _ = tick.tick() => {
                    if self.endpoint.is_closed() {
                        return;
                    }
                    self.announce_mdns();
                }
                event = found.recv_async() => match event {
                    Ok(mdns_sd::ServiceEvent::ServiceResolved(service)) => {
                        let ips = service.addresses.iter().map(|ip| ip.to_ip_addr());
                        let addrs = discovery::usable(ips, service.port);
                        let _ = self.found(&service.fullname, addrs).await;
                    }
                    Ok(_) => {}
                    Err(_) => return,
                },
            }
        }
    }

    /// O anúncio desta época, com os endereços de agora. Só refaz quando muda.
    fn announce_mdns(&self) {
        let Some(daemon) = self.mdns.as_ref() else {
            return;
        };
        let token = discovery::token(&self.discovery_key, discovery::epoch(Self::now_secs()));
        let addrs = self.addrs();
        let Ok(mut announced) = self.announced.lock() else {
            return;
        };
        if let Some((_, old_token, old_addrs)) = announced.as_ref() {
            if *old_token == token && *old_addrs == addrs {
                return;
            }
        }
        if let Some((fullname, _, _)) = announced.take() {
            let _ = daemon.unregister(&fullname);
        }
        let Some(port) = addrs.first().map(|a| a.port()) else {
            return;
        };
        let ips: Vec<std::net::IpAddr> = addrs.iter().map(|a| a.ip()).collect();
        let Ok(service) = mdns_sd::ServiceInfo::new(
            discovery::SERVICE,
            &token,
            &format!("{token}.local."),
            ips.as_slice(),
            port,
            None::<HashMap<String, String>>,
        ) else {
            return;
        };
        let fullname = service.get_fullname().to_owned();
        if daemon.register(service).is_ok() {
            *announced = Some((fullname, token, addrs));
        }
    }

    /// Um anúncio na rede: se o token é de um contato, os endereços dele vão para a
    /// frente da lista, e o que esperava por ele sai.
    async fn found(&self, fullname: &str, addrs: Vec<SocketAddr>) -> CoreResult<()> {
        let Some(token) = discovery::instance(fullname).map(str::to_owned) else {
            return Ok(());
        };
        if addrs.is_empty() {
            return Ok(());
        }
        let now = Self::now_secs();
        let contact = with_store(&self.store, move |s| {
            let contacts = contacts::list(s.conn())?;
            let Some(id) = discovery::owner(
                contacts
                    .iter()
                    .filter(|c| c.state == ContactState::Established)
                    .map(|c| (c.id, c.discovery_key.as_slice())),
                &token,
                now,
            ) else {
                return Ok(None);
            };
            // Na ordem inversa, para o primeiro anunciado ficar na frente.
            for addr in addrs.iter().rev() {
                contacts::learn_addr(s.conn(), id, &addr.to_string())?;
            }
            Ok(Some(id))
        })
        .await?;
        if let Some(id) = contact {
            self.flush(id);
        }
        Ok(())
    }

    /// Diz a cada contato que o aparelho está aqui: uma conexão sem nada dentro, que
    /// o nó do contato reconhece pela chave. Ele guarda o endereço de agora e entrega o
    /// que esperava por nós.
    async fn announce(self: Arc<Self>) {
        let Ok(contacts) = with_store(&self.store, |s| contacts::list(s.conn())).await else {
            return;
        };
        for contact in contacts {
            if contact.state != ContactState::Established {
                continue;
            }
            let node = self.clone();
            tokio::spawn(async move {
                let Ok(conn) = node.connect(&contact).await else {
                    return;
                };
                node.saw(contact.id);
                if let Ok((mut send, _recv)) = conn.open_bi().await {
                    let _ = send.finish();
                    let _ = tokio::time::timeout(Duration::from_secs(5), conn.closed()).await;
                }
                conn.close(0u32.into(), b"");
            });
        }
    }

    /// O contato respondeu há pouco. O "digitando" só vai para quem está online: cada
    /// aviso gasta uma chave do ratchet, e os que não saem viram chaves puladas do
    /// outro lado (o libsignal aceita um número limitado delas).
    pub fn is_online(&self, contact_id: i64) -> bool {
        self.seen
            .lock()
            .ok()
            .and_then(|seen| seen.get(&contact_id).copied())
            .is_some_and(|at| at.elapsed() < ONLINE_FOR)
    }

    fn saw(&self, contact_id: i64) {
        if let Ok(mut seen) = self.seen.lock() {
            seen.insert(contact_id, Instant::now());
        }
    }

    /// Pede a entrega da caixa de saída do contato, logo.
    pub fn flush(&self, contact_id: i64) {
        let _ = self.wake.send(contact_id);
    }

    fn emit(&self, event: NodeEvent) {
        let _ = self.events.send(event);
    }

    async fn delivery_loop(self: Arc<Self>, mut woken: mpsc::UnboundedReceiver<i64>) {
        let mut tick = tokio::time::interval(RETRY_INTERVAL);
        loop {
            let ids = tokio::select! {
                id = woken.recv() => match id {
                    Some(id) => vec![id],
                    None => return,
                },
                _ = tick.tick() => {
                    let waiting = with_store(&self.store, |s| {
                        messages::drop_ephemeral(s.conn(), None)?;
                        messages::waiting(s.conn())
                    })
                    .await;
                    waiting.unwrap_or_default()
                }
            };
            if self.endpoint.is_closed() {
                return;
            }
            for id in ids {
                tokio::spawn(self.clone().flush_now(id));
            }
        }
    }

    /// Esvazia a caixa do contato; uma entrega por contato de cada vez.
    async fn flush_now(self: Arc<Self>, contact_id: i64) {
        {
            let Ok(mut flushing) = self.flushing.lock() else {
                return;
            };
            if !flushing.0.insert(contact_id) {
                flushing.1.insert(contact_id);
                return;
            }
        }
        loop {
            let _ = self.deliver(contact_id).await;
            let Ok(mut flushing) = self.flushing.lock() else {
                return;
            };
            if !flushing.1.remove(&contact_id) {
                flushing.0.remove(&contact_id);
                return;
            }
        }
    }

    async fn deliver(&self, contact_id: i64) -> CoreResult<()> {
        let (contact, first) = with_store(&self.store, move |s| {
            let contact = contacts::by_id(s.conn(), contact_id)?;
            Ok((contact, messages::next_out(s.conn(), contact_id)?))
        })
        .await?;
        if first.is_none() || contact.state != ContactState::Established {
            return Ok(());
        }
        let result = self.deliver_to(&contact).await;
        // O "digitando" que não saiu agora não vale depois.
        let _ = with_store(&self.store, move |s| {
            messages::drop_ephemeral(s.conn(), Some(contact_id))
        })
        .await;
        result
    }

    async fn deliver_to(&self, contact: &Contact) -> CoreResult<()> {
        let conn = self.connect(contact).await?;
        self.saw(contact.id);
        let result = self.send_all(&conn, contact.id).await;
        conn.close(0u32.into(), b"");
        result
    }

    async fn connect(&self, contact: &Contact) -> CoreResult<Connection> {
        let remote = EndpointId::from_bytes(
            contact
                .endpoint_id
                .as_slice()
                .try_into()
                .map_err(|_| CoreError::Storage)?,
        )
        .map_err(|_| CoreError::Storage)?;
        let addrs: Vec<SocketAddr> = contact
            .addrs
            .iter()
            .filter_map(|a| a.parse().ok())
            .collect();
        let addr = EndpointAddr::from_parts(remote, addrs.into_iter().map(iroh::TransportAddr::Ip));
        self.lookup.add_endpoint_info(addr.clone());
        tokio::time::timeout(CONNECT_TIMEOUT, self.endpoint.connect(addr, ALPN))
            .await
            .map_err(|_| CoreError::Unreachable)?
            .map_err(|_| CoreError::Unreachable)
    }

    async fn send_all(&self, conn: &Connection, contact_id: i64) -> CoreResult<()> {
        let (mut send, mut recv) = conn.open_bi().await.map_err(|_| CoreError::Unreachable)?;
        for _ in 0..MAX_MESSAGES {
            let Some(out) = with_store(&self.store, move |s| {
                messages::next_out(s.conn(), contact_id)
            })
            .await?
            else {
                break;
            };
            let body = if out.prekey {
                Body::PreKeyMessage(out.ciphertext)
            } else {
                Body::Message(out.ciphertext)
            };
            wire::write_frame(&mut send, &wire::frame(body)).await?;
            let reply = tokio::time::timeout(IDLE_TIMEOUT, wire::read_frame(&mut recv))
                .await
                .map_err(|_| CoreError::Unreachable)??;
            match reply {
                Body::Ack(_) => {
                    let id = out.id;
                    if with_store(&self.store, move |s| messages::delivered(s.conn(), id)).await? {
                        self.emit(NodeEvent::MessagesChanged(contact_id));
                    }
                }
                Body::Refused(_) => return Err(CoreError::Protocol),
                _ => return Err(CoreError::Protocol),
            }
        }
        let _ = send.finish();
        Ok(())
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
        let key = invite.identity_key;
        if with_store(&self.store, move |s| contacts::by_identity(s.conn(), &key))
            .await?
            .is_some()
        {
            return Err(CoreError::AlreadyExists);
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
                self.emit(NodeEvent::ContactChanged(contact.id));
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
        let slots = Arc::new(tokio::sync::Semaphore::new(MAX_INCOMING));
        while let Some(incoming) = self.endpoint.accept().await {
            let Ok(slot) = slots.clone().acquire_owned().await else {
                return;
            };
            let node = self.clone();
            tokio::spawn(async move {
                let _slot = slot;
                let from = match incoming.remote_addr() {
                    IncomingAddr::Ip(addr) => Some(addr),
                    _ => None,
                };
                let Ok(conn) = incoming.await else { return };
                let _ = node.serve(&conn, from).await;
                conn.close(0u32.into(), b"");
            });
        }
    }

    async fn serve(&self, conn: &Connection, from: Option<SocketAddr>) -> CoreResult<()> {
        let remote = *conn.remote_id().as_bytes();
        let contact = with_store(&self.store, move |s| {
            contacts::by_endpoint(s.conn(), &remote)
        })
        .await?;
        match contact {
            Some(contact) => {
                self.saw(contact.id);
                // O contato falou daqui: é o endereço mais provável dele agora.
                if let Some(addr) = from.filter(|a| is_local(a) || a.ip().is_loopback()) {
                    let id = contact.id;
                    let _ = with_store(&self.store, move |s| {
                        contacts::learn_addr(s.conn(), id, &addr.to_string())
                    })
                    .await;
                }
                let result = self.serve_messages(conn, remote).await;
                // Está online: o que esperava por ele vai agora.
                self.flush(contact.id);
                result
            }
            None => tokio::time::timeout(HANDSHAKE_TIMEOUT, self.serve_handshake(conn))
                .await
                .unwrap_or(Err(CoreError::Unreachable)),
        }
    }

    /// As mensagens de um contato: cada uma é decifrada e gravada antes do `Ack`.
    async fn serve_messages(&self, conn: &Connection, remote: [u8; 32]) -> CoreResult<()> {
        let (mut send, mut recv): (SendStream, RecvStream) =
            tokio::time::timeout(IDLE_TIMEOUT, conn.accept_bi())
                .await
                .map_err(|_| CoreError::Unreachable)?
                .map_err(|_| CoreError::Unreachable)?;
        for _ in 0..MAX_MESSAGES {
            let frame = match tokio::time::timeout(IDLE_TIMEOUT, wire::read_frame(&mut recv)).await
            {
                Ok(Ok(frame)) => frame,
                // O outro lado terminou (ou sumiu).
                _ => break,
            };
            let (prekey, bytes) = match frame {
                Body::Message(bytes) => (false, bytes),
                Body::PreKeyMessage(bytes) => (true, bytes),
                _ => return Err(CoreError::Protocol),
            };
            let result = with_store(&self.store, move |s| {
                messages::receive(s, &remote, prekey, &bytes)
            })
            .await;
            let reply = match result {
                Ok(effect) => {
                    match effect {
                        Effect::Messages(id) => self.emit(NodeEvent::MessagesChanged(id)),
                        Effect::Typing(id) => self.emit(NodeEvent::Typing(id)),
                        Effect::Contact(id) => self.emit(NodeEvent::ContactChanged(id)),
                        Effect::Nothing => {}
                    }
                    Body::Ack(wire::Ack {})
                }
                Err(_) => Body::Refused(wire::Refused {}),
            };
            wire::write_frame(&mut send, &wire::frame(reply)).await?;
        }
        let _ = send.finish();
        let _ = tokio::time::timeout(Duration::from_secs(2), conn.closed()).await;
        Ok(())
    }

    /// O lado de quem convidou: responde ao pedido de prekeys e ao Hello.
    async fn serve_handshake(&self, conn: &Connection) -> CoreResult<()> {
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
                            self.emit(NodeEvent::ContactChanged(contact.id));
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
        if let Some(daemon) = self.mdns.as_ref() {
            if let Ok(Some((fullname, _, _))) = self.announced.lock().map(|mut a| a.take()) {
                let _ = daemon.unregister(&fullname);
            }
            let _ = daemon.shutdown();
        }
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
        let NodeEvent::ContactChanged(id) = event else {
            panic!("{event:?}");
        };
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

    /// Espera até o banco dizer o que se quer (a rede é assíncrona).
    async fn until(what: &str, mut ok: impl FnMut() -> bool) {
        for _ in 0..400 {
            if ok() {
                return;
            }
            tokio::time::sleep(Duration::from_millis(50)).await;
        }
        panic!("timed out waiting for {what}");
    }

    fn texts(store: &SharedStore, contact: i64) -> Vec<(String, crate::messages::Status)> {
        crate::messages::list(store.lock().unwrap().conn(), contact, None, 100)
            .unwrap()
            .into_iter()
            .map(|m| (m.body, m.status))
            .collect()
    }

    async fn befriend(alice_store: &SharedStore, alice: &Node, bob: &Node) -> (i64, i64) {
        let mut events = alice.subscribe();
        let invite = alice.create_invite(InviteKind::Qr).await.unwrap();
        let at_bob = bob.join(invite, true).await.unwrap();
        loop {
            if let Ok(Ok(NodeEvent::ContactChanged(id))) =
                tokio::time::timeout(Duration::from_secs(5), events.recv()).await
            {
                assert_eq!(contacts(alice_store).len(), 1);
                return (id, at_bob.id);
            }
        }
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn messages_go_both_ways_with_receipts() {
        use crate::messages::{self, Status};
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start(alice_store.clone()).await.unwrap();
        let bob = Node::start(bob_store.clone()).await.unwrap();
        let (bob_at_alice, alice_at_bob) = befriend(&alice_store, &alice, &bob).await;
        let mut bob_events = bob.subscribe();

        messages::send_text(&mut alice_store.lock().unwrap(), bob_at_alice, "oi", None).unwrap();
        alice.flush(bob_at_alice);
        until("Bob receives", || {
            texts(&bob_store, alice_at_bob).len() == 1
        })
        .await;
        until("Alice sees it delivered", || {
            texts(&alice_store, bob_at_alice) == [("oi".to_owned(), Status::Delivered)]
        })
        .await;
        let event = tokio::time::timeout(Duration::from_secs(5), async {
            loop {
                if let Ok(NodeEvent::MessagesChanged(id)) = bob_events.recv().await {
                    return id;
                }
            }
        })
        .await
        .unwrap();
        assert_eq!(event, alice_at_bob);
        // Os dois acabaram de se falar: o "digitando" pode sair.
        assert!(alice.is_online(bob_at_alice));
        assert!(bob.is_online(alice_at_bob));
        assert!(!bob.is_online(999));

        // Bob lê e responde; o recibo e a resposta voltam.
        messages::mark_read(&mut bob_store.lock().unwrap(), alice_at_bob).unwrap();
        messages::send_text(&mut bob_store.lock().unwrap(), alice_at_bob, "olá", None).unwrap();
        bob.flush(alice_at_bob);
        until("Alice gets the reply and the receipt", || {
            texts(&alice_store, bob_at_alice)
                == [
                    ("oi".to_owned(), Status::Read),
                    ("olá".to_owned(), Status::Pending),
                ]
        })
        .await;
        alice.close().await;
        bob.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn messages_wait_for_a_contact_that_was_off() {
        use crate::messages::{self, Status};
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start(alice_store.clone()).await.unwrap();
        let bob = Node::start(bob_store.clone()).await.unwrap();
        let (bob_at_alice, alice_at_bob) = befriend(&alice_store, &alice, &bob).await;
        bob.close().await;

        for text in ["um", "dois", "três"] {
            messages::send_text(&mut alice_store.lock().unwrap(), bob_at_alice, text, None)
                .unwrap();
        }
        alice.flush(bob_at_alice);
        tokio::time::sleep(Duration::from_millis(300)).await;
        assert!(texts(&alice_store, bob_at_alice)
            .iter()
            .all(|(_, s)| *s == Status::Pending));

        // Bob volta (na mesma porta, ou avisando onde está): tudo chega, na ordem.
        let bob = Node::start(bob_store.clone()).await.unwrap();
        until("Bob gets the queue", || {
            texts(&bob_store, alice_at_bob)
                .iter()
                .map(|(t, _)| t.as_str())
                .collect::<Vec<_>>()
                == ["um", "dois", "três"]
        })
        .await;
        until("Alice sees all delivered", || {
            texts(&alice_store, bob_at_alice)
                .iter()
                .all(|(_, s)| *s == Status::Delivered)
        })
        .await;
        alice.close().await;
        bob.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn discovery_finds_a_contact_that_moved() {
        use crate::messages::{self, Status};
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start(alice_store.clone()).await.unwrap();
        let bob = Node::start(bob_store.clone()).await.unwrap();
        let (bob_at_alice, alice_at_bob) = befriend(&alice_store, &alice, &bob).await;
        if alice.addrs().iter().all(|a| !is_local(a)) {
            // Sem rede local (só o loopback), não há o que anunciar.
            return;
        }
        alice.close().await;

        // Alice "muda de endereço": volta numa porta nova, e nenhum dos dois sabe onde
        // o outro está (o aviso ao ligar não chega a Bob).
        let wrong = "192.0.2.1:9";
        for store in [&alice_store, &bob_store] {
            store
                .lock()
                .unwrap()
                .conn()
                .execute("UPDATE contacts SET addrs = ?1", [wrong])
                .unwrap();
        }
        alice_store
            .lock()
            .unwrap()
            .conn()
            .execute("UPDATE local_keys SET port = 0", [])
            .unwrap();
        let alice = Node::start(alice_store.clone()).await.unwrap();
        alice.announce_mdns();

        // Bob escreve: só o mDNS diz a ele onde Alice está agora.
        messages::send_text(&mut bob_store.lock().unwrap(), alice_at_bob, "achei", None).unwrap();
        bob.flush(alice_at_bob);
        until("discovery delivers", || {
            texts(&bob_store, alice_at_bob) == [("achei".to_owned(), Status::Delivered)]
        })
        .await;
        assert_eq!(texts(&alice_store, bob_at_alice).len(), 1);
        alice.close().await;
        bob.close().await;
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

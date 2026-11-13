//! O nó da rede: um endpoint do iroh (QUIC, TLS 1.3 com a chave do nó), na rede local
//! (docs/PLANO.md, 7.2) e, se ligada, na internet (7.3, o `network`).
//!
//! Sem descoberta por servidor e sem UPnP (o preset `Minimal`, com as features padrão
//! do iroh fora): o nó só fala com os endereços que um convite ou um contato deram.
//! Com a internet desligada (o padrão), só os da rede local, e nenhum pacote vai para
//! terceiros. Ligada, os endereços públicos também valem, e os contatos os recebem
//! pela sessão (`Addrs`) quando mudam. Com um retransmissor escolhido, o iroh o usa
//! para furar o NAT, e para repassar quando o furo não dá; sem nenhum, só conecta se
//! um dos dois aceitar conexões de fora.
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
//!
//! A caixa postal (fase 7, o `mailbox`): um contato que não atende e que tem uma
//! recebe o que esperava na caixa dele, que guarda até ele buscar. A deste aparelho é
//! lida ao ligar e a cada `MAILBOX_INTERVAL`.
//!
//! O Bluetooth (fase 8, o `ble`), se ligado: o nó anuncia o token de época e procura
//! os dos contatos. Um contato visto há pouco que não atende pelo iroh recebe por um
//! canal L2CAP com o Noise (`ble::secure`), com os mesmos frames; a caixa postal fica
//! para quando nem assim.

use std::collections::{HashMap, HashSet};
use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use iroh::address_lookup::MemoryLookup;
use iroh::endpoint::{presets, Connection, IncomingAddr, RecvStream, RelayMode, SendStream};
use iroh::{Endpoint, EndpointAddr, EndpointId, RelayMap, RelayUrl, SecretKey, TransportAddr};
use tokio::sync::{broadcast, mpsc};

use crate::ble::{self, Radio};
use crate::contacts::{self, Contact, ContactState};
use crate::discovery;
use crate::error::{CoreError, CoreResult};
use crate::files;
use crate::invite::{Invite, InviteMailbox};
use crate::mailbox::{self, proto as mproto, PairLink};
use crate::messages::{self, Effect};
use crate::network;
use crate::session::{self, InviteKind};
use crate::store::Store;
use crate::wire::{self, Body, Peer};

pub const ALPN: &[u8] = b"chirp/1";
const HANDSHAKE_TIMEOUT: Duration = Duration::from_secs(20);
const MAX_FRAMES: usize = 4;
/// Quantas conexões que chegam ao mesmo tempo; as de além esperam.
const MAX_INCOMING: usize = 16;
/// Para conectar a um contato na rede local, e pela internet (o furo pelo
/// retransmissor leva mais).
const CONNECT_TIMEOUT: Duration = Duration::from_secs(5);
const INTERNET_CONNECT_TIMEOUT: Duration = Duration::from_secs(12);
/// De quanto em quanto tempo os endereços são conferidos, para avisar os contatos.
const ADDRS_CHECK: Duration = Duration::from_secs(15);
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
/// De quanto em quanto tempo a caixa postal deste aparelho é lida.
const MAILBOX_INTERVAL: Duration = Duration::from_secs(60);
/// Quanto um convite novo espera a caixa postal publicar as prekeys dele.
const PUBLISH_TIMEOUT: Duration = Duration::from_secs(5);

/// O que muda no núcleo sem a UI pedir.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NodeEvent {
    /// Um contato novo ou mudado (o id).
    ContactChanged(i64),
    /// A conversa com o contato mudou: chegou mensagem, recibo, edição.
    MessagesChanged(i64),
    /// O contato está digitando.
    Typing(i64),
    /// A rede foi desligada de propósito: quem escuta os eventos para (o processo
    /// pode sair). Religar por causa dos ajustes não manda isto.
    Closed,
}

/// Por onde o contato foi alcançado da última vez.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Reach {
    /// Ainda não tentou.
    #[default]
    Unknown,
    /// Direto, na rede local.
    Lan,
    /// Direto, pela internet.
    Direct,
    /// Pelo retransmissor.
    Relay,
    /// Não alcançou.
    Unreachable,
    /// Pelo Bluetooth, perto.
    Bluetooth,
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
    /// A internet e os retransmissores, como estavam ao ligar.
    settings: network::Settings,
    /// Por onde cada contato foi alcançado da última vez.
    reach: Mutex<HashMap<i64, Reach>>,
    /// Acorda os downloads (um arquivo novo, um pedido de quem usa).
    fetch: mpsc::UnboundedSender<()>,
    /// Onde ficam os blobs.
    files_dir: std::path::PathBuf,
    /// Acorda a leitura da caixa postal (ligou agora, um contato novo).
    mailbox_wake: tokio::sync::Notify,
    /// Acorda as apresentações entre membros de grupos (um grupo mudou).
    intro_wake: tokio::sync::Notify,
    /// Se a última leitura da caixa postal deu certo (nada: ainda não tentou).
    mailbox_ok: Mutex<Option<bool>>,
    /// O rádio Bluetooth, se ligado e se o sistema tem um.
    radio: Option<Arc<dyn Radio>>,
    /// O rádio não abriu o canal ou a procura.
    ble_failed: std::sync::atomic::AtomicBool,
    /// Os contatos vistos pelo Bluetooth há pouco.
    nearby: Mutex<ble::Nearby>,
}

/// Um endereço da rede local: IPv4 privado (RFC 1918) ou IPv6 local único (fc00::/7).
/// O link-local do IPv6 fica de fora, porque sem a interface não se usa.
pub(crate) fn is_local(addr: &SocketAddr) -> bool {
    match addr.ip() {
        std::net::IpAddr::V4(ip) => ip.is_private(),
        std::net::IpAddr::V6(ip) => (ip.segments()[0] & 0xfe00) == 0xfc00,
    }
}

/// Um endereço que não serve fora do aparelho ou do enlace.
fn is_unroutable(addr: &SocketAddr) -> bool {
    match addr.ip() {
        std::net::IpAddr::V4(ip) => ip.is_loopback() || ip.is_link_local() || ip.is_unspecified(),
        std::net::IpAddr::V6(ip) => {
            ip.is_loopback() || ip.is_unspecified() || (ip.segments()[0] & 0xffc0) == 0xfe80
        }
    }
}

/// O que um envelope da caixa postal fez.
enum Opened {
    Nothing,
    /// Uma mensagem de um contato: o efeito, e o id para o "entregue".
    Message(i64, Effect, Option<Vec<u8>>),
    /// O Hello de um convite publicado: o contato novo, com o Welcome na caixa de saída.
    NewContact(i64),
    /// O Welcome de quem convidou: o contato pendente ficou estabelecido.
    Established(i64),
}

/// Abre um envelope da caixa postal pela ficha com que chegou: a de um contato, a de
/// um contato pendente (o Welcome) ou a de um convite publicado (o Hello).
fn open_item(s: &mut Store, item: &mailbox::proto::Item, me: Peer) -> CoreResult<Opened> {
    let (prekey, bytes) = match wire::decode_frame(&item.envelope) {
        Ok(Body::Message(bytes)) => (false, bytes),
        Ok(Body::PreKeyMessage(bytes)) => (true, bytes),
        _ => return Ok(Opened::Nothing),
    };
    if let Some(contact) = mailbox::contact_by_drop(s.conn(), &item.drop)? {
        if contact.state == ContactState::Pending {
            let remote: [u8; 32] = contact
                .endpoint_id
                .as_slice()
                .try_into()
                .map_err(|_| CoreError::Storage)?;
            if prekey {
                return Ok(Opened::Nothing);
            }
            let contact = session::accept_welcome(s, contact.id, &remote, &bytes)?;
            return Ok(Opened::Established(contact.id));
        }
        let (effect, shown) = messages::receive_from(s, &contact, prekey, &bytes)?;
        return Ok(Opened::Message(contact.id, effect, shown));
    }
    if !prekey || !session::invite_has_drop(s.conn(), &item.drop)? {
        return Ok(Opened::Nothing);
    }
    let (contact, welcome, theirs) =
        session::accept_hello(s, session::HelloFrom::Mailbox(item.stored_at), &bytes, me)?;
    messages::queue_raw(s.conn(), contact.id, &welcome)?;
    if let Some(Ok(theirs)) = theirs.map(mailbox::theirs_from_info) {
        mailbox::set_theirs(s.conn(), contact.id, theirs.as_ref())?;
    }
    Ok(Opened::NewContact(contact.id))
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
    pub async fn start(
        store: SharedStore,
        events: broadcast::Sender<NodeEvent>,
    ) -> CoreResult<Arc<Node>> {
        let bluetooth = with_store(&store, |s| network::get(s.conn()))
            .await?
            .bluetooth;
        let radio = if bluetooth {
            Self::system_radio().await
        } else {
            None
        };
        Self::start_with(store, events, radio, true).await
    }

    /// O rádio do sistema, se houver um ligado.
    async fn system_radio() -> Option<Arc<dyn Radio>> {
        #[cfg(target_os = "linux")]
        {
            ble::bluez::BlueZ::open()
                .await
                .ok()
                .map(|r| Arc::new(r) as Arc<dyn Radio>)
        }
        #[cfg(not(target_os = "linux"))]
        {
            None
        }
    }

    async fn start_with(
        store: SharedStore,
        events: broadcast::Sender<NodeEvent>,
        radio: Option<Arc<dyn Radio>>,
        mdns: bool,
    ) -> CoreResult<Arc<Node>> {
        let (keys, port, settings, files_dir) = with_store(&store, |s| {
            let keys = session::local_keys(s.conn())?;
            let port: u16 =
                s.conn()
                    .query_row("SELECT port FROM local_keys WHERE id = 1", [], |r| r.get(0))?;
            // Os blobs de arquivos apagados (ou de um envio que caiu) saem.
            files::sweep(s.conn(), s.files_dir())?;
            Ok((
                keys,
                port,
                network::get(s.conn())?,
                s.files_dir().to_path_buf(),
            ))
        })
        .await?;
        let lookup = MemoryLookup::new();
        let relays = settings.relay_urls();
        let builder = |port: u16| -> CoreResult<iroh::endpoint::Builder> {
            let relay_mode = if relays.is_empty() {
                RelayMode::Disabled
            } else {
                RelayMode::Custom(relays.iter().cloned().collect::<RelayMap>())
            };
            let builder = Endpoint::builder(presets::Minimal)
                .relay_mode(relay_mode)
                .clear_address_lookup()
                .address_lookup(lookup.clone())
                .secret_key(SecretKey::from_bytes(&keys.endpoint_secret))
                .alpns(vec![ALPN.to_vec()]);
            // Os retransmissores dos testes têm certificado próprio.
            #[cfg(test)]
            let builder = builder.ca_tls_config(iroh::tls::CaTlsConfig::insecure_skip_verify());
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
        let (wake, woken) = mpsc::unbounded_channel();
        let (fetch, fetching) = mpsc::unbounded_channel();
        let node = Arc::new(Node {
            endpoint,
            lookup,
            store,
            events,
            discovery_key: keys.discovery_key.to_vec(),
            wake,
            flushing: Mutex::new((HashSet::new(), HashSet::new())),
            seen: Mutex::new(HashMap::new()),
            mdns: mdns.then(|| mdns_sd::ServiceDaemon::new().ok()).flatten(),
            announced: Mutex::new(None),
            settings,
            reach: Mutex::new(HashMap::new()),
            fetch,
            files_dir,
            mailbox_wake: tokio::sync::Notify::new(),
            intro_wake: tokio::sync::Notify::new(),
            mailbox_ok: Mutex::new(None),
            radio,
            ble_failed: std::sync::atomic::AtomicBool::new(false),
            nearby: Mutex::new(ble::Nearby::default()),
        });
        tokio::spawn(node.clone().accept_loop());
        tokio::spawn(node.clone().delivery_loop(woken));
        tokio::spawn(node.clone().announce());
        tokio::spawn(node.clone().discovery_loop());
        tokio::spawn(node.clone().addrs_loop());
        tokio::spawn(node.clone().download_loop(fetching));
        tokio::spawn(node.clone().mailbox_loop());
        tokio::spawn(node.clone().ble_loop());
        tokio::spawn(node.clone().intro_loop());
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
        // O mDNS só leva os da rede local, mesmo com a internet ligada.
        let addrs: Vec<SocketAddr> = self
            .addrs()
            .into_iter()
            .filter(|a| is_local(a) || a.ip().is_loopback())
            .collect();
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
        let theirs = with_store(&self.store, move |s| {
            messages::drop_ephemeral(s.conn(), Some(contact_id))?;
            mailbox::theirs(s.conn(), contact_id)
        })
        .await;
        match (result, theirs) {
            // Não atendeu, e tem caixa postal: o resto fica lá.
            (Err(CoreError::Unreachable), Ok(Some(theirs))) => {
                self.deposit(contact_id, theirs).await
            }
            (result, _) => result,
        }
    }

    /// Deixa na caixa postal do contato o que está na caixa de saída, na ordem. Cada
    /// envelope sai daqui quando a caixa diz que guardou.
    async fn deposit(&self, contact_id: i64, theirs: mailbox::Theirs) -> CoreResult<()> {
        let conn = self
            .dial(&theirs.endpoint_id, &theirs.addrs, mproto::ALPN)
            .await?;
        let result = self.deposit_on(&conn, contact_id, &theirs.drop).await;
        conn.close(0u32.into(), b"");
        result
    }

    async fn deposit_on(
        &self,
        conn: &Connection,
        contact_id: i64,
        drop: &[u8; 32],
    ) -> CoreResult<()> {
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
            let envelope = prost::Message::encode_to_vec(&wire::frame(body));
            let deposit = mproto::Body::Deposit(mproto::Deposit {
                drop: drop.to_vec(),
                envelope,
            });
            mproto::write(&mut send, deposit)
                .await
                .map_err(|_| CoreError::Unreachable)?;
            match Self::mailbox_reply(&mut recv).await? {
                mproto::Body::Done(_) => {
                    let id = out.id;
                    if with_store(&self.store, move |s| mailbox::deposited(s.conn(), id)).await? {
                        self.emit(NodeEvent::MessagesChanged(contact_id));
                    }
                }
                // Cheia, ou a ficha não vale mais: fica na caixa de saída.
                _ => return Err(CoreError::Unreachable),
            }
        }
        let _ = send.finish();
        Ok(())
    }

    async fn mailbox_reply(recv: &mut RecvStream) -> CoreResult<mproto::Body> {
        tokio::time::timeout(IDLE_TIMEOUT, mproto::read(recv))
            .await
            .map_err(|_| CoreError::Unreachable)?
            .map_err(|_| CoreError::Unreachable)
    }

    async fn deliver_to(&self, contact: &Contact) -> CoreResult<()> {
        let conn = match self.connect(contact).await {
            Ok(conn) => conn,
            // Não atendeu pela rede: se está perto, pelo Bluetooth.
            Err(CoreError::Unreachable) if self.near(contact.id).is_some() => {
                return self.deliver_by_ble(contact).await;
            }
            Err(e) => return Err(e),
        };
        self.saw(contact.id);
        let result = self.send_all(&conn, contact.id).await;
        conn.close(0u32.into(), b"");
        result
    }

    /// Conecta a um nó pelos endereços que este nó pode usar agora.
    async fn dial(
        &self,
        endpoint_id: &[u8],
        addrs: &[String],
        alpn: &[u8],
    ) -> CoreResult<Connection> {
        let remote =
            EndpointId::from_bytes(endpoint_id.try_into().map_err(|_| CoreError::Storage)?)
                .map_err(|_| CoreError::Storage)?;
        let usable = self.usable(addrs);
        if usable.is_empty() {
            return Err(CoreError::Unreachable);
        }
        let addr = EndpointAddr::from_parts(remote, usable);
        self.lookup.add_endpoint_info(addr.clone());
        tokio::time::timeout(self.connect_timeout(), self.endpoint.connect(addr, alpn))
            .await
            .map_err(|_| CoreError::Unreachable)
            .and_then(|r| r.map_err(|_| CoreError::Unreachable))
    }

    async fn connect(&self, contact: &Contact) -> CoreResult<Connection> {
        let result = self.dial(&contact.endpoint_id, &contact.addrs, ALPN).await;
        match &result {
            Ok(conn) => self.reached(contact.id, Self::path_of(conn)),
            Err(_) => self.reached(contact.id, Reach::Unreachable),
        }
        result
    }

    fn connect_timeout(&self) -> Duration {
        if self.settings.internet {
            INTERNET_CONNECT_TIMEOUT
        } else {
            CONNECT_TIMEOUT
        }
    }

    /// Os endereços de um contato que este nó pode usar agora: com a internet
    /// desligada, só os da rede local (nada de IP público nem retransmissor).
    fn usable(&self, addrs: &[String]) -> Vec<TransportAddr> {
        let internet = self.settings.internet;
        addrs
            .iter()
            .filter_map(|a| {
                if let Ok(ip) = a.parse::<SocketAddr>() {
                    (internet || is_local(&ip) || ip.ip().is_loopback())
                        .then_some(TransportAddr::Ip(ip))
                } else if internet {
                    a.parse::<RelayUrl>().ok().map(TransportAddr::Relay)
                } else {
                    None
                }
            })
            .collect()
    }

    /// O caminho que a conexão usa agora.
    fn path_of(conn: &Connection) -> Reach {
        let paths = conn.paths();
        let Some(path) = paths
            .iter()
            .find(|p| p.is_selected())
            .or_else(|| paths.iter().next())
        else {
            return Reach::Unknown;
        };
        if path.is_relay() {
            return Reach::Relay;
        }
        match path.remote_addr() {
            TransportAddr::Ip(ip) if is_local(ip) || ip.ip().is_loopback() => Reach::Lan,
            _ => Reach::Direct,
        }
    }

    /// Guarda por onde o contato foi alcançado; avisa a UI quando muda.
    fn reached(&self, contact_id: i64, reach: Reach) {
        let changed = self
            .reach
            .lock()
            .map(|mut all| all.insert(contact_id, reach) != Some(reach))
            .unwrap_or(false);
        if changed {
            self.emit(NodeEvent::ContactChanged(contact_id));
        }
    }

    /// Por onde o contato foi alcançado da última vez.
    pub fn reach(&self, contact_id: i64) -> Reach {
        self.reach
            .lock()
            .ok()
            .and_then(|all| all.get(&contact_id).copied())
            .unwrap_or_default()
    }

    /// A internet ligada, e se algum retransmissor respondeu (o nó tem um).
    pub fn internet(&self) -> (bool, bool) {
        (
            self.settings.internet,
            self.endpoint.addr().relay_urls().next().is_some(),
        )
    }

    async fn send_all(&self, conn: &Connection, contact_id: i64) -> CoreResult<()> {
        let (mut send, mut recv) = conn.open_bi().await.map_err(|_| CoreError::Unreachable)?;
        self.send_over(&mut send, &mut recv, contact_id).await?;
        let _ = send.finish();
        Ok(())
    }

    /// Manda a caixa de saída do contato por um fluxo, na ordem, cada envelope
    /// esperando o `Ack`.
    async fn send_over<W, R>(&self, send: &mut W, recv: &mut R, contact_id: i64) -> CoreResult<()>
    where
        W: tokio::io::AsyncWrite + Unpin,
        R: tokio::io::AsyncRead + Unpin,
    {
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
            wire::write_frame(send, &wire::frame(body)).await?;
            tokio::io::AsyncWriteExt::flush(send)
                .await
                .map_err(|_| CoreError::Unreachable)?;
            let reply = tokio::time::timeout(IDLE_TIMEOUT, wire::read_frame(recv))
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
        Ok(())
    }

    pub fn id(&self) -> [u8; 32] {
        *self.endpoint.id().as_bytes()
    }

    /// Os eventos (a UI assina o canal do `ChirpStore`, que sobrevive ao nó).
    #[cfg(test)]
    pub fn subscribe(&self) -> broadcast::Receiver<NodeEvent> {
        self.events.subscribe()
    }

    /// Os endereços de agora, para o convite e para os contatos: os da rede local
    /// primeiro e, com a internet ligada, os públicos (os da interface e o que o
    /// retransmissor viu). Com ela desligada, um link mandado por outro canal não leva
    /// o IP público de ninguém. Sem nenhum, o loopback, que só serve no mesmo aparelho.
    pub fn addrs(&self) -> Vec<SocketAddr> {
        let all: Vec<SocketAddr> = self.endpoint.addr().ip_addrs().copied().collect();
        let internet = self.settings.internet;
        let mut addrs: Vec<SocketAddr> = all
            .iter()
            .copied()
            .filter(|a| is_local(a) || (internet && !is_unroutable(a)))
            .collect();
        if addrs.is_empty() {
            addrs = all.into_iter().filter(|a| a.ip().is_loopback()).collect();
        }
        addrs.sort_by_key(|a| (!is_local(a), a.is_ipv6()));
        addrs.dedup();
        addrs.truncate(8);
        addrs
    }

    /// O retransmissor deste nó (o que respondeu primeiro), se houver.
    pub fn relay(&self) -> Option<String> {
        self.endpoint
            .addr()
            .relay_urls()
            .next()
            .map(|u| u.to_string())
    }

    /// Os endereços que os contatos recebem: os IPs e o retransmissor.
    fn advertised(&self) -> Vec<String> {
        let mut addrs: Vec<String> = self.addrs().iter().map(|a| a.to_string()).collect();
        addrs.extend(self.relay());
        addrs
    }

    fn me(&self) -> Peer {
        Peer {
            endpoint_id: self.id().to_vec(),
            addrs: self.advertised(),
            discovery_key: self.discovery_key.clone(),
        }
    }

    pub async fn create_invite(&self, kind: InviteKind) -> CoreResult<Invite> {
        let (id, addrs, relay) = (self.id(), self.addrs(), self.relay());
        let mut invite = with_store(&self.store, move |s| {
            session::create_invite(s, kind, id, addrs, relay)
        })
        .await?;
        // Com a caixa postal, as prekeys ficam lá também: quem ler o convite com este
        // aparelho desligado deixa o pedido nela. Sem resposta logo, vai sem.
        invite.mailbox = tokio::time::timeout(PUBLISH_TIMEOUT, self.publish_invite(&invite))
            .await
            .ok()
            .flatten();
        Ok(invite)
    }

    /// Publica as prekeys do convite na caixa postal deste aparelho.
    async fn publish_invite(&self, invite: &Invite) -> Option<InviteMailbox> {
        let token = invite.token;
        let drop_hash = mproto::hash(&mproto::invite_drop(&token));
        let (paired, bundle) = with_store(&self.store, move |s| {
            let Some(paired) = mailbox::get(s.conn())? else {
                return Ok(None);
            };
            session::set_invite_drop(s.conn(), &token, &drop_hash)?;
            Ok(Some((paired, session::bundle_for(s, &token)?)))
        })
        .await
        .ok()
        .flatten()?;
        let conn = self
            .dial(&paired.endpoint_id, &paired.addrs, mproto::ALPN)
            .await
            .ok()?;
        let published = async {
            let (mut send, mut recv) = conn.open_bi().await.ok()?;
            let publish = mproto::Publish {
                lookup: mproto::invite_lookup(&token).to_vec(),
                bundle: prost::Message::encode_to_vec(&bundle),
                drop: drop_hash.to_vec(),
                expires_at: Self::now_secs() + session::INVITE_TTL.as_secs(),
            };
            mproto::write(&mut send, mproto::Body::Publish(publish))
                .await
                .ok()?;
            let reply = Self::mailbox_reply(&mut recv).await.ok()?;
            let _ = send.finish();
            matches!(reply, mproto::Body::Done(_)).then_some(())
        }
        .await;
        conn.close(0u32.into(), b"");
        published?;
        let (ips, relay): (Vec<&String>, Vec<&String>) = paired
            .addrs
            .iter()
            .partition(|a| a.parse::<SocketAddr>().is_ok());
        Some(InviteMailbox {
            endpoint_id: paired.endpoint_id,
            addrs: ips.iter().filter_map(|a| a.parse().ok()).collect(),
            relay: relay.first().map(|r| (*r).clone()),
        })
    }

    /// Avisa os contatos, pela sessão, quando os endereços mudam (a rede trocou, o
    /// retransmissor respondeu). Só manda o que ficou igual por duas conferências
    /// seguidas, para uma rede que pisca não gastar mensagens.
    async fn addrs_loop(self: Arc<Self>) {
        let mut tick = tokio::time::interval(ADDRS_CHECK);
        let mut candidate: Option<Vec<String>> = None;
        loop {
            tick.tick().await;
            if self.endpoint.is_closed() {
                return;
            }
            let now = self.advertised();
            let Ok(sent) = with_store(&self.store, |s| network::announced(s.conn())).await else {
                continue;
            };
            if now.is_empty() || now == sent {
                candidate = None;
                continue;
            }
            if candidate.as_ref() != Some(&now) {
                candidate = Some(now);
                continue;
            }
            candidate = None;
            let to = with_store(&self.store, move |s| messages::send_addrs(s, &now)).await;
            for id in to.unwrap_or_default() {
                self.flush(id);
            }
        }
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
        let mut addrs: Vec<String> = invite.addrs.iter().map(|a| a.to_string()).collect();
        addrs.extend(invite.relay.clone());
        let addr = EndpointAddr::from_parts(remote, self.usable(&addrs));
        self.lookup.add_endpoint_info(addr.clone());
        // Com a caixa postal no convite, não vale esperar muito por quem convidou.
        let wait = if invite.mailbox.is_some() {
            self.connect_timeout()
        } else {
            HANDSHAKE_TIMEOUT
        };
        let conn = match tokio::time::timeout(wait, self.endpoint.connect(addr, ALPN)).await {
            Ok(Ok(conn)) => conn,
            _ => {
                return match invite.mailbox.clone() {
                    Some(mailbox) => self.join_by_mailbox(invite, mailbox, verified).await,
                    None => Err(CoreError::Unreachable),
                };
            }
        };
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
            session::join(s, &invite, &bundle, me, verified, None)
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
                // O contato novo fica sabendo da caixa postal, se houver.
                self.check_mailbox();
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

    /// O primeiro contato com quem convidou e está desligado: as prekeys vêm da caixa
    /// postal dele, e o Hello fica lá. O contato fica pendente até o Welcome, que vem
    /// direto ou pela caixa postal deste aparelho, se houver.
    async fn join_by_mailbox(
        &self,
        invite: Invite,
        mailbox: InviteMailbox,
        verified: bool,
    ) -> CoreResult<Contact> {
        let conn = self
            .dial(&mailbox.endpoint_id, &mailbox.addr_strings(), mproto::ALPN)
            .await?;
        let result = tokio::time::timeout(
            HANDSHAKE_TIMEOUT,
            self.join_on_mailbox(&conn, invite, verified),
        )
        .await
        .unwrap_or(Err(CoreError::Unreachable));
        conn.close(0u32.into(), b"");
        result
    }

    async fn join_on_mailbox(
        &self,
        conn: &Connection,
        invite: Invite,
        verified: bool,
    ) -> CoreResult<Contact> {
        let (mut send, mut recv) = conn.open_bi().await.map_err(|_| CoreError::Unreachable)?;
        let token = invite.token;
        let get = mproto::Body::GetBundle(mproto::GetBundle {
            lookup: mproto::invite_lookup(&token).to_vec(),
        });
        mproto::write(&mut send, get)
            .await
            .map_err(|_| CoreError::Unreachable)?;
        let bundle = match Self::mailbox_reply(&mut recv).await? {
            mproto::Body::Bundle(b) => {
                <wire::Bundle as prost::Message>::decode(b.bundle.as_slice())
                    .map_err(|_| CoreError::Protocol)?
            }
            _ => return Err(CoreError::InviteRefused),
        };
        // A caixa deste aparelho vai no Hello, com a ficha de quem convidou.
        let drop_token = *crate::random::secret_bytes::<32>()?;
        let me = self.me();
        let pending = with_store(&self.store, move |s| {
            let mine = mailbox::get(s.conn())?;
            let info = mine.as_ref().map(|p| wire::MailboxInfo {
                endpoint_id: p.endpoint_id.to_vec(),
                addrs: p.addrs.clone(),
                drop: drop_token.to_vec(),
            });
            let (pending, hello) = session::join(s, &invite, &bundle, me, verified, info)?;
            if let Some(paired) = mine {
                mailbox::set_drop_token(s.conn(), pending.id, &drop_token)?;
                mailbox::set_told(s.conn(), pending.id, Some(paired.endpoint_id.as_slice()))?;
            }
            Ok((pending, hello))
        })
        .await;
        let (pending, hello) = pending?;
        let deposit = mproto::Body::Deposit(mproto::Deposit {
            drop: mproto::invite_drop(&token).to_vec(),
            envelope: prost::Message::encode_to_vec(&wire::frame(Body::PreKeyMessage(hello))),
        });
        let left = async {
            mproto::write(&mut send, deposit)
                .await
                .map_err(|_| CoreError::Unreachable)?;
            match Self::mailbox_reply(&mut recv).await? {
                mproto::Body::Done(_) => Ok(()),
                _ => Err(CoreError::InviteRefused),
            }
        }
        .await;
        let _ = send.finish();
        if let Err(error) = left {
            let id = pending.id;
            let _ = with_store(&self.store, move |s| session::forget(s, id)).await;
            return Err(error);
        }
        self.emit(NodeEvent::ContactChanged(pending.id));
        // A caixa deste aparelho passa a aceitar a ficha de quem convidou.
        self.check_mailbox();
        Ok(pending)
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
            match contacts::by_endpoint(s.conn(), &remote)? {
                Some(contact) => Ok(Some(contact)),
                // Um contato pendente pela caixa postal: o Welcome vem por aqui.
                None => contacts::pending_by_endpoint(s.conn(), &remote),
            }
        })
        .await?;
        match contact {
            Some(contact) => {
                self.saw(contact.id);
                self.reached(contact.id, Self::path_of(conn));
                // O contato falou daqui: é o endereço mais provável dele agora (um
                // público, só com a internet ligada).
                let internet = self.settings.internet;
                if let Some(addr) = from.filter(|a| {
                    is_local(a) || a.ip().is_loopback() || (internet && !is_unroutable(a))
                }) {
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
        if let Some(request) = self.receive_over(&mut send, &mut recv, remote).await? {
            return self.serve_file(conn, send, remote, request).await;
        }
        let _ = send.finish();
        let _ = tokio::time::timeout(Duration::from_secs(2), conn.closed()).await;
        Ok(())
    }

    /// Recebe as mensagens de um contato por um fluxo, até ele terminar. Um pedido de
    /// arquivo vem sozinho, no começo, e volta para quem chamou atender.
    async fn receive_over<W, R>(
        &self,
        send: &mut W,
        recv: &mut R,
        remote: [u8; 32],
    ) -> CoreResult<Option<wire::FileRequest>>
    where
        W: tokio::io::AsyncWrite + Unpin,
        R: tokio::io::AsyncRead + Unpin,
    {
        for count in 0..MAX_MESSAGES {
            let frame = match tokio::time::timeout(IDLE_TIMEOUT, wire::read_frame(recv)).await {
                Ok(Ok(frame)) => frame,
                // O outro lado terminou (ou sumiu).
                _ => break,
            };
            if let (0, Body::FileRequest(request)) = (count, &frame) {
                return Ok(Some(request.clone()));
            }
            let (prekey, bytes) = match frame {
                Body::Message(bytes) => (false, bytes),
                Body::PreKeyMessage(bytes) => (true, bytes),
                _ => return Err(CoreError::Protocol),
            };
            let result = with_store(&self.store, move |s| {
                if contacts::by_endpoint(s.conn(), &remote)?.is_some() {
                    return messages::receive(s, &remote, prekey, &bytes);
                }
                match contacts::pending_by_endpoint(s.conn(), &remote)? {
                    Some(pending) if !prekey => {
                        session::accept_welcome(s, pending.id, &remote, &bytes)
                            .map(|c| Effect::Contact(c.id))
                    }
                    _ => Err(CoreError::UnknownContact),
                }
            })
            .await;
            let reply = match result {
                Ok(effect) => {
                    self.saw_effect(effect);
                    Body::Ack(wire::Ack {})
                }
                Err(_) => Body::Refused(wire::Refused {}),
            };
            wire::write_frame(send, &wire::frame(reply)).await?;
            tokio::io::AsyncWriteExt::flush(send)
                .await
                .map_err(|_| CoreError::Unreachable)?;
        }
        Ok(None)
    }

    /// Manda as fatias de um arquivo que oferecemos a esse contato, a partir de onde
    /// ele parou. De outro contato, ou um que não existe: recusado, sem dizer por quê.
    async fn serve_file(
        &self,
        conn: &Connection,
        mut send: SendStream,
        remote: [u8; 32],
        request: wire::FileRequest,
    ) -> CoreResult<()> {
        let row = with_store(&self.store, move |s| {
            let Some(contact) = contacts::by_endpoint(s.conn(), &remote)? else {
                return Ok(None);
            };
            files::offered_to(s.conn(), &request.file_id, contact.id)
        })
        .await?;
        let Some(row) = row else {
            wire::write_frame(&mut send, &wire::frame(Body::Refused(wire::Refused {}))).await?;
            let _ = send.finish();
            // Fechar já descartaria a recusa no caminho: espera o outro lado ler.
            let _ = tokio::time::timeout(Duration::from_secs(5), conn.closed()).await;
            return Ok(());
        };
        let blob = files::blob_path(&self.files_dir, &row.file_id);
        for index in request.from..row.chunks {
            let (blob, size) = (blob.clone(), row.size);
            let data = tokio::task::spawn_blocking(move || files::read_chunk(&blob, size, index))
                .await
                .map_err(|_| CoreError::Storage)??;
            let chunk = Body::FileChunk(wire::FileChunk { index, data });
            wire::write_frame(&mut send, &wire::frame(chunk)).await?;
        }
        let _ = send.finish();
        let _ = tokio::time::timeout(Duration::from_secs(5), conn.closed()).await;
        Ok(())
    }

    /// Acorda os downloads.
    pub fn fetch(&self) {
        let _ = self.fetch.send(());
    }

    /// Baixa os arquivos pedidos, um de cada vez: quando acordado e a cada
    /// `RETRY_INTERVAL` (o contato pode ter aparecido).
    async fn download_loop(self: Arc<Self>, mut fetching: mpsc::UnboundedReceiver<()>) {
        let mut tick = tokio::time::interval(RETRY_INTERVAL);
        loop {
            tokio::select! {
                woke = fetching.recv() => if woke.is_none() { return },
                _ = tick.tick() => {}
            }
            // Vários avisos juntos viram uma rodada só.
            while fetching.try_recv().is_ok() {}
            if self.endpoint.is_closed() {
                return;
            }
            let Ok(wanted) = with_store(&self.store, |s| files::wanted(s.conn())).await else {
                continue;
            };
            for (contact_id, row) in wanted {
                let _ = self.download(contact_id, row).await;
            }
        }
    }

    async fn download(&self, contact_id: i64, row: files::FileRow) -> CoreResult<()> {
        let contact =
            with_store(&self.store, move |s| contacts::by_id(s.conn(), contact_id)).await?;
        if contact.state != ContactState::Established {
            return Ok(());
        }
        let conn = self.connect(&contact).await?;
        let result = self.download_on(&conn, contact_id, &row).await;
        conn.close(0u32.into(), b"");
        result
    }

    async fn download_on(
        &self,
        conn: &Connection,
        contact_id: i64,
        row: &files::FileRow,
    ) -> CoreResult<()> {
        let (mut send, mut recv) = conn.open_bi().await.map_err(|_| CoreError::Unreachable)?;
        let request = Body::FileRequest(wire::FileRequest {
            file_id: row.file_id.clone(),
            from: row.received,
        });
        wire::write_frame(&mut send, &wire::frame(request)).await?;
        let _ = send.finish();
        let blob = files::blob_path(&self.files_dir, &row.file_id);
        std::fs::create_dir_all(&self.files_dir)?;
        let message = row.message;
        for index in row.received..row.chunks {
            let frame = tokio::time::timeout(IDLE_TIMEOUT, wire::read_frame(&mut recv))
                .await
                .map_err(|_| CoreError::Unreachable)??;
            let chunk = match frame {
                Body::FileChunk(chunk) => chunk,
                Body::Refused(_) => return Err(CoreError::UnknownMessage),
                _ => return Err(CoreError::Protocol),
            };
            let last = index + 1 == row.chunks;
            // Cada fatia é conferida ao chegar: uma errada não é gravada.
            if chunk.index != index
                || chunk.data.len() != files::sealed_len(row.size, index)
                || files::open_chunk(&row.key, &row.file_id, index, last, &chunk.data).is_err()
            {
                return Err(CoreError::Protocol);
            }
            let path = blob.clone();
            tokio::task::spawn_blocking(move || files::write_chunk(&path, index, &chunk.data))
                .await
                .map_err(|_| CoreError::Storage)??;
            let received = index + 1;
            with_store(&self.store, move |s| {
                files::set_received(s.conn(), message, received)
            })
            .await?;
            if received % 16 == 0 || last {
                self.emit(NodeEvent::MessagesChanged(contact_id));
            }
        }
        // Inteiro: confere o hash do arquivo todo.
        let (path, checked) = (blob.clone(), row.clone());
        let ok = tokio::task::spawn_blocking(move || files::verify(&path, &checked))
            .await
            .unwrap_or(false);
        with_store(&self.store, move |s| {
            if ok {
                files::set_state(s.conn(), message, files::State::Done)
            } else {
                files::set_received(s.conn(), message, 0)?;
                files::set_state(s.conn(), message, files::State::Failed)
            }
        })
        .await?;
        if !ok {
            let _ = std::fs::remove_file(&blob);
        }
        self.emit(NodeEvent::MessagesChanged(contact_id));
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
                        session::accept_hello(s, session::HelloFrom::Node(&remote), &hello, me)
                    })
                    .await
                    {
                        Ok((contact, welcome, _)) => {
                            wire::write_frame(&mut send, &wire::frame(Body::Message(welcome)))
                                .await?;
                            let _ = send.finish();
                            self.emit(NodeEvent::ContactChanged(contact.id));
                            self.check_mailbox();
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

    /// Pede uma leitura da caixa postal agora (e o aviso aos contatos que faltam).
    pub fn check_mailbox(&self) {
        self.mailbox_wake.notify_one();
    }

    /// Se a última leitura da caixa postal deu certo.
    pub fn mailbox_ok(&self) -> Option<bool> {
        self.mailbox_ok.lock().ok().and_then(|ok| *ok)
    }

    /// Apresenta os membros dos grupos entre si (fase 9, parte 2), ao ligar, a cada
    /// `MAILBOX_INTERVAL` e quando um grupo muda.
    async fn intro_loop(self: Arc<Self>) {
        let mut tick = tokio::time::interval(MAILBOX_INTERVAL);
        loop {
            tokio::select! {
                _ = tick.tick() => {}
                _ = self.intro_wake.notified() => {}
            }
            if self.endpoint.is_closed() {
                return;
            }
            let _ = self.intro_round().await;
        }
    }

    /// Manda ao admin um convite para cada membro que eu devo apresentar, e entra nos
    /// convites que o admin repassou. Um convite cuja chave não é a do membro, ou que
    /// o outro lado recusa, sai; um que não alcança fica para a próxima.
    async fn intro_round(&self) -> CoreResult<()> {
        let due = with_store(&self.store, |s| {
            let me = session::me(s)?;
            crate::groups::intros_due(s.conn(), &me.public())
        })
        .await?;
        for (group, member) in due {
            let invite = self.create_invite(InviteKind::Link).await?;
            let link = invite.to_link();
            let admin = with_store(&self.store, move |s| {
                crate::groups::send_intro(s, group, &member, &link)
            })
            .await?;
            self.flush(admin);
        }
        let pending = with_store(&self.store, |s| crate::groups::intros_pending(s.conn())).await?;
        for (group, member, link) in pending {
            let invite = match Invite::from_link(&link) {
                Ok(invite) if invite.identity_key[..] == member[..] => invite,
                _ => {
                    with_store(&self.store, move |s| {
                        crate::groups::drop_intro(s.conn(), group, &member)
                    })
                    .await?;
                    continue;
                }
            };
            let joined = match self.join(invite, false).await {
                Ok(contact) => Some(contact.id),
                // Não alcançou: fica para a próxima volta.
                Err(CoreError::Unreachable) => continue,
                // Recusado, já contato, do próprio aparelho: não adianta tentar de novo.
                Err(_) => None,
            };
            with_store(&self.store, move |s| {
                crate::groups::drop_intro(s.conn(), group, &member)?;
                match joined {
                    Some(id) => crate::groups::mark_via_group(s.conn(), id),
                    None => Ok(()),
                }
            })
            .await?;
            if let Some(id) = joined {
                self.emit(NodeEvent::ContactChanged(id));
            }
        }
        Ok(())
    }

    async fn mailbox_loop(self: Arc<Self>) {
        let mut tick = tokio::time::interval(MAILBOX_INTERVAL);
        loop {
            tokio::select! {
                _ = tick.tick() => {}
                _ = self.mailbox_wake.notified() => {}
            }
            if self.endpoint.is_closed() {
                return;
            }
            let result = self.mailbox_round().await;
            if let Ok(mut ok) = self.mailbox_ok.lock() {
                *ok = match result {
                    Ok(true) => Some(true),
                    Ok(false) => None,
                    Err(_) => Some(false),
                };
            }
        }
    }

    /// Avisa os contatos que ainda não sabem da caixa, manda as fichas que mudaram e
    /// busca o que chegou. Devolve se há caixa.
    async fn mailbox_round(&self) -> CoreResult<bool> {
        let (paired, told) = with_store(&self.store, |s| {
            let mut told = messages::send_mailbox(s)?;
            // A foto do perfil também: um contato novo, ou um que perdeu a vez.
            told.extend(messages::send_photos(s)?);
            Ok((mailbox::get(s.conn())?, told))
        })
        .await?;
        for id in told {
            self.flush(id);
        }
        let Some(paired) = paired else {
            return Ok(false);
        };
        let conn = self
            .dial(&paired.endpoint_id, &paired.addrs, mproto::ALPN)
            .await?;
        let result = self.fetch_mailbox(&conn, paired.synced).await;
        conn.close(0u32.into(), b"");
        result.map(|_| true)
    }

    async fn fetch_mailbox(&self, conn: &Connection, synced: Option<Vec<u8>>) -> CoreResult<()> {
        let (mut send, mut recv) = conn.open_bi().await.map_err(|_| CoreError::Unreachable)?;
        let hashes = with_store(&self.store, |s| mailbox::drops(s.conn())).await?;
        let digest = mailbox::digest(&hashes);
        if synced.as_ref() != Some(&digest) {
            mproto::write(
                &mut send,
                mproto::Body::SetDrops(mproto::SetDrops { hashes }),
            )
            .await
            .map_err(|_| CoreError::Unreachable)?;
            let mproto::Body::Done(_) = Self::mailbox_reply(&mut recv).await? else {
                // A caixa não nos conhece mais (desligada do outro lado).
                return Err(CoreError::Protocol);
            };
            with_store(&self.store, move |s| mailbox::set_synced(s.conn(), &digest)).await?;
        }
        let mut after = 0;
        loop {
            mproto::write(&mut send, mproto::Body::Fetch(mproto::Fetch { after }))
                .await
                .map_err(|_| CoreError::Unreachable)?;
            let mut items = Vec::new();
            loop {
                match Self::mailbox_reply(&mut recv).await? {
                    mproto::Body::Item(item) if items.len() < mproto::FETCH_BATCH => {
                        items.push(item)
                    }
                    mproto::Body::Done(_) => break,
                    _ => return Err(CoreError::Protocol),
                }
            }
            let full = items.len() == mproto::FETCH_BATCH;
            let Some(read) = self.open_items(items).await? else {
                break;
            };
            mproto::write(
                &mut send,
                mproto::Body::Remove(mproto::Remove { up_to: read }),
            )
            .await
            .map_err(|_| CoreError::Unreachable)?;
            let mproto::Body::Done(_) = Self::mailbox_reply(&mut recv).await? else {
                return Err(CoreError::Protocol);
            };
            after = read;
            if !full {
                break;
            }
        }
        let _ = send.finish();
        let now = Self::now_secs() as i64;
        with_store(&self.store, move |s| mailbox::set_last_fetch(s.conn(), now)).await
    }

    /// Abre o que veio da caixa, como se tivesse chegado direto, e devolve até onde leu
    /// (o que não decifra também conta: é jogado fora). Uma falha do banco para antes.
    async fn open_items(&self, items: Vec<mproto::Item>) -> CoreResult<Option<u64>> {
        let mut read = None;
        let mut delivered: HashMap<i64, Vec<Vec<u8>>> = HashMap::new();
        for item in items {
            let (seq, me) = (item.seq, self.me());
            let result = with_store(&self.store, move |s| match open_item(s, &item, me) {
                Err(CoreError::Storage) => Err(CoreError::Storage),
                Err(_) => Ok(Opened::Nothing),
                opened => opened,
            })
            .await;
            match result {
                Ok(Opened::Message(contact_id, effect, shown)) => {
                    self.saw_effect(effect);
                    delivered.entry(contact_id).or_default().extend(shown);
                }
                Ok(Opened::NewContact(contact_id)) => {
                    self.emit(NodeEvent::ContactChanged(contact_id));
                    // O Welcome sai já, e o contato novo fica sabendo da caixa.
                    self.flush(contact_id);
                    self.check_mailbox();
                }
                Ok(Opened::Established(contact_id)) => {
                    self.emit(NodeEvent::ContactChanged(contact_id));
                }
                Ok(Opened::Nothing) => {}
                Err(_) => break,
            }
            read = Some(seq);
        }
        for (contact_id, ids) in delivered {
            let sent = with_store(&self.store, move |s| {
                messages::send_delivered(s, contact_id, &ids)
            })
            .await;
            if sent.is_ok() {
                self.flush(contact_id);
            }
        }
        Ok(read)
    }

    /// Avisa a UI do que mudou com uma mensagem que chegou.
    fn saw_effect(&self, effect: Effect) {
        match effect {
            Effect::Messages(id) => {
                self.emit(NodeEvent::MessagesChanged(id));
                // Pode ser um arquivo novo para baixar.
                self.fetch();
            }
            Effect::Typing(id) => self.emit(NodeEvent::Typing(id)),
            Effect::Contact(id) => {
                self.emit(NodeEvent::ContactChanged(id));
                // Pode ser um grupo novo, ou mudado: talvez haja membros a apresentar.
                self.intro_wake.notify_one();
            }
            Effect::Nothing => {}
        }
    }

    /// Liga este aparelho à caixa do código e avisa os contatos. Uma caixa anterior é
    /// desligada antes.
    pub async fn pair_mailbox(&self, link: PairLink) -> CoreResult<()> {
        let addrs = mailbox::link_addrs(&link);
        let conn = self.dial(&link.endpoint_id, &addrs, mproto::ALPN).await?;
        let result = async {
            let (mut send, mut recv) = conn.open_bi().await.map_err(|_| CoreError::Unreachable)?;
            mproto::write(
                &mut send,
                mproto::Body::Pair(mproto::Pair {
                    token: link.token.to_vec(),
                }),
            )
            .await
            .map_err(|_| CoreError::Unreachable)?;
            let reply = Self::mailbox_reply(&mut recv).await?;
            let _ = send.finish();
            Ok::<_, CoreError>(reply)
        }
        .await;
        conn.close(0u32.into(), b"");
        let mproto::Body::Done(_) = result? else {
            return Err(CoreError::MailboxRefused);
        };
        let old = with_store(&self.store, |s| mailbox::get(s.conn())).await?;
        if let Some(old) = old.filter(|o| o.endpoint_id != link.endpoint_id) {
            self.say_unpair(&old).await;
        }
        let now = Self::now_secs() as i64;
        with_store(&self.store, move |s| {
            mailbox::set(s.conn(), &link.endpoint_id, &addrs, now)
        })
        .await?;
        if let Ok(mut ok) = self.mailbox_ok.lock() {
            *ok = Some(true);
        }
        self.check_mailbox();
        Ok(())
    }

    /// Desliga a caixa (o que estava guardado nela se perde) e avisa os contatos.
    pub async fn unpair_mailbox(&self) -> CoreResult<()> {
        let old = with_store(&self.store, |s| mailbox::get(s.conn())).await?;
        if let Some(old) = old {
            self.say_unpair(&old).await;
        }
        with_store(&self.store, |s| mailbox::clear(s.conn())).await?;
        if let Ok(mut ok) = self.mailbox_ok.lock() {
            *ok = None;
        }
        self.check_mailbox();
        Ok(())
    }

    /// Pede à caixa que esqueça este aparelho, se ela atender. Se não, ela esquece
    /// sozinha o que guardava, no prazo dela.
    async fn say_unpair(&self, paired: &mailbox::Paired) {
        let Ok(conn) = self
            .dial(&paired.endpoint_id, &paired.addrs, mproto::ALPN)
            .await
        else {
            return;
        };
        if let Ok((mut send, mut recv)) = conn.open_bi().await {
            if mproto::write(&mut send, mproto::Body::Unpair(mproto::Unpair {}))
                .await
                .is_ok()
            {
                let _ = Self::mailbox_reply(&mut recv).await;
            }
            let _ = send.finish();
        }
        conn.close(0u32.into(), b"");
    }

    pub async fn close(&self) {
        if let Some(daemon) = self.mdns.as_ref() {
            if let Ok(Some((fullname, _, _))) = self.announced.lock().map(|mut a| a.take()) {
                let _ = daemon.unregister(&fullname);
            }
            let _ = daemon.shutdown();
        }
        if let Some(radio) = self.radio.as_ref() {
            radio.stop().await;
        }
        self.endpoint.close().await;
    }

    /// Se o Bluetooth está ligado e funcionando: nada se desligado nos ajustes, falso
    /// se o sistema não deixou (sem adaptador, desligado, sem o BlueZ).
    pub fn bluetooth(&self) -> Option<bool> {
        if !self.settings.bluetooth {
            return None;
        }
        Some(self.radio.is_some() && !self.ble_failed.load(std::sync::atomic::Ordering::Relaxed))
    }

    /// Onde o contato foi visto pelo Bluetooth, se há pouco.
    fn near(&self, contact_id: i64) -> Option<(String, u16)> {
        self.radio.as_ref()?;
        self.nearby.lock().ok()?.get(contact_id)
    }

    /// Anuncia, procura e atende pelo Bluetooth, enquanto o nó estiver ligado.
    async fn ble_loop(self: Arc<Self>) {
        let Some(radio) = self.radio.clone() else {
            return;
        };
        let failed = || {
            self.ble_failed
                .store(true, std::sync::atomic::Ordering::Relaxed)
        };
        let Ok((psm, mut incoming)) = radio.listen().await else {
            return failed();
        };
        let Ok(mut sightings) = radio.scan().await else {
            return failed();
        };
        let mut tick = tokio::time::interval(ANNOUNCE_CHECK);
        let mut advertised: Option<ble::Token> = None;
        loop {
            tokio::select! {
                _ = tick.tick() => {
                    if self.endpoint.is_closed() {
                        return;
                    }
                    let token = ble::token(
                        &self.discovery_key,
                        discovery::epoch(Self::now_secs()),
                    );
                    if advertised != Some(token)
                        && radio.advertise(ble::advert(&token, psm)).await.is_ok()
                    {
                        advertised = Some(token);
                    }
                }
                sighting = sightings.recv() => match sighting {
                    Some(sighting) => {
                        let _ = self.sighted(sighting).await;
                    }
                    None => return,
                },
                link = incoming.recv() => match link {
                    Some(link) => {
                        let node = self.clone();
                        tokio::spawn(async move {
                            let _ = node.serve_ble(link).await;
                        });
                    }
                    None => return,
                },
            }
        }
    }

    /// Um anúncio do Chirp: se o token é de um contato, ele está perto, e o que
    /// esperava por ele pode sair.
    async fn sighted(&self, sighting: ble::Sighting) -> CoreResult<()> {
        let Some((token, psm)) = ble::parse_advert(&sighting.data) else {
            return Ok(());
        };
        let now = Self::now_secs();
        let contact = with_store(&self.store, move |s| {
            let contacts = contacts::list(s.conn())?;
            Ok(ble::owner(
                contacts
                    .iter()
                    .filter(|c| c.state == ContactState::Established)
                    .map(|c| (c.id, c.discovery_key.as_slice())),
                &token,
                now,
            ))
        })
        .await?;
        let Some(id) = contact else {
            return Ok(());
        };
        let fresh = {
            let Ok(mut nearby) = self.nearby.lock() else {
                return Ok(());
            };
            let fresh = nearby.get(id).is_none();
            nearby.saw(id, sighting.peer, psm);
            fresh
        };
        // Visto agora: entrega o que esperava (um anúncio repetido não refaz).
        if fresh {
            self.flush(id);
        }
        Ok(())
    }

    /// Entrega pelo Bluetooth: conecta, confere que do outro lado está o contato e
    /// manda a caixa de saída.
    async fn deliver_by_ble(&self, contact: &Contact) -> CoreResult<()> {
        let (Some(radio), Some((peer, psm))) = (self.radio.as_ref(), self.near(contact.id)) else {
            return Err(CoreError::Unreachable);
        };
        let link = match radio.connect(&peer, psm).await {
            Ok(link) => link,
            Err(e) => {
                if let Ok(mut nearby) = self.nearby.lock() {
                    nearby.forget(contact.id);
                }
                return Err(e);
            }
        };
        let (channel, remote) = ble::secure::initiate(link, self.endpoint.secret_key()).await?;
        if remote[..] != contact.endpoint_id[..] {
            // Outro aparelho com o token do contato (um anúncio repetido): não é ele.
            return Err(CoreError::Unreachable);
        }
        self.reached(contact.id, Reach::Bluetooth);
        self.saw(contact.id);
        let (mut recv, mut send) = tokio::io::split(channel);
        let result = self.send_over(&mut send, &mut recv, contact.id).await;
        let _ = tokio::io::AsyncWriteExt::shutdown(&mut send).await;
        result
    }

    /// Uma conexão pelo Bluetooth: só de contatos, e só mensagens (os arquivos ficam
    /// para a rede).
    async fn serve_ble(&self, link: ble::Link) -> CoreResult<()> {
        let (channel, remote) = ble::secure::respond(link, self.endpoint.secret_key()).await?;
        let contact = with_store(&self.store, move |s| {
            contacts::by_endpoint(s.conn(), &remote)
        })
        .await?
        .ok_or(CoreError::UnknownContact)?;
        self.saw(contact.id);
        self.reached(contact.id, Reach::Bluetooth);
        let (mut recv, mut send) = tokio::io::split(channel);
        let result = self.receive_over(&mut send, &mut recv, remote).await;
        let _ = tokio::io::AsyncWriteExt::shutdown(&mut send).await;
        self.flush(contact.id);
        match result? {
            Some(_) => Err(CoreError::Protocol),
            None => Ok(()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    impl Node {
        async fn start_test(store: SharedStore) -> CoreResult<Arc<Node>> {
            Node::start(store, broadcast::channel(256).0).await
        }
    }

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
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
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
        let carol = Node::start_test(device("Carol")).await.unwrap();
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
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
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
    async fn a_file_goes_downloads_resumes_and_is_refused_to_others() {
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        let (bob_at_alice, alice_at_bob) = befriend(&alice_store, &alice, &bob).await;

        // Um arquivo de três fatias e um pouco.
        let tmp = tempfile::tempdir().unwrap();
        let src = tmp.path().join("notas.txt");
        let plain: Vec<u8> = (0..3 * files::CHUNK + 123)
            .map(|i| (i % 251) as u8)
            .collect();
        std::fs::write(&src, &plain).unwrap();
        let dir = alice_store.lock().unwrap().files_dir().to_path_buf();
        let prepared = files::prepare(&dir, &src).unwrap();
        crate::messages::send_file(&mut alice_store.lock().unwrap(), bob_at_alice, prepared)
            .unwrap();
        alice.flush(bob_at_alice);

        let done = |store: &SharedStore| {
            let s = store.lock().unwrap();
            crate::messages::list(s.conn(), alice_at_bob, None, 10)
                .unwrap()
                .first()
                .and_then(|m| files::by_message(s.conn(), m.id).unwrap())
                .filter(|f| f.state == files::State::Done)
        };
        until("Bob has the whole file", || done(&bob_store).is_some()).await;
        let row = done(&bob_store).unwrap();
        assert_eq!(row.name, "notas.txt");
        let blob = files::blob_path(bob_store.lock().unwrap().files_dir(), &row.file_id);
        let mut out = Vec::new();
        files::export(&blob, &row, &mut out).unwrap();
        assert_eq!(out, plain);

        // Cortado depois da primeira fatia: volta a baixar só o resto.
        {
            let s = bob_store.lock().unwrap();
            files::set_received(s.conn(), row.message, 1).unwrap();
            files::set_state(s.conn(), row.message, files::State::Downloading).unwrap();
        }
        let first = files::read_chunk(&blob, row.size, 0).unwrap();
        let file = std::fs::OpenOptions::new().write(true).open(&blob).unwrap();
        file.set_len(first.len() as u64).unwrap();
        drop(file);
        bob.fetch();
        until("Bob resumes", || done(&bob_store).is_some()).await;
        assert!(files::verify(&blob, &row));

        // Um arquivo que Alice não ofereceu a Bob: recusado.
        let mut forged = row.clone();
        forged.file_id = vec![9; 16];
        forged.received = 0;
        assert_eq!(
            bob.download(alice_at_bob, forged).await,
            Err(CoreError::UnknownMessage)
        );
        alice.close().await;
        bob.close().await;
    }

    /// Um aparelho com a internet ligada e o retransmissor dado.
    fn online_device(name: &str, relay: &str) -> SharedStore {
        let store = device(name);
        network::set(
            store.lock().unwrap().conn(),
            &network::Settings {
                internet: true,
                relays: vec![relay.to_owned()],
                ..Default::default()
            },
        )
        .unwrap();
        store
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn the_relay_joins_two_nodes_that_know_no_address() {
        use crate::messages::{self, Status};
        let (_map, url, _server) = iroh::test_utils::run_relay_server().await.unwrap();
        let relay = url.to_string();
        let (alice_store, bob_store) =
            (online_device("Alice", &relay), online_device("Bob", &relay));
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        tokio::time::timeout(Duration::from_secs(10), alice.endpoint.online())
            .await
            .unwrap();
        assert_eq!(alice.internet(), (true, true));
        assert_eq!(alice.relay().as_deref(), Some(relay.as_str()));

        // O convite só com o retransmissor, como entre duas casas atrás de NAT.
        let mut events = alice.subscribe();
        let mut invite = alice.create_invite(InviteKind::Link).await.unwrap();
        assert_eq!(invite.relay.as_deref(), Some(relay.as_str()));
        invite.addrs.clear();
        let invite = Invite::from_link(&invite.to_link()).unwrap();
        let at_bob = bob.join(invite, false).await.unwrap();
        let bob_at_alice = loop {
            if let Ok(Ok(NodeEvent::ContactChanged(id))) =
                tokio::time::timeout(Duration::from_secs(5), events.recv()).await
            {
                break id;
            }
        };
        // Os dois ficaram com o retransmissor do outro.
        assert!(
            crate::contacts::by_id(bob_store.lock().unwrap().conn(), at_bob.id)
                .unwrap()
                .addrs
                .contains(&relay)
        );

        // Só pelo retransmissor, a mensagem chega e volta o "entregue".
        crate::contacts::set_addrs(
            bob_store.lock().unwrap().conn(),
            at_bob.id,
            std::slice::from_ref(&relay),
        )
        .unwrap();
        messages::send_text(
            &mut bob_store.lock().unwrap(),
            at_bob.id,
            "oi pela rede",
            None,
        )
        .unwrap();
        bob.flush(at_bob.id);
        until("Bob's message is delivered", || {
            texts(&bob_store, at_bob.id) == [("oi pela rede".to_owned(), Status::Delivered)]
        })
        .await;
        assert_eq!(texts(&alice_store, bob_at_alice).len(), 1);
        assert_ne!(bob.reach(at_bob.id), Reach::Unreachable);
        assert_ne!(bob.reach(at_bob.id), Reach::Unknown);
        alice.close().await;
        bob.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn with_the_internet_off_a_public_address_is_not_tried() {
        use crate::messages;
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        let (_, alice_at_bob) = befriend(&alice_store, &alice, &bob).await;
        alice.close().await;
        // Alice "foi para outra rede": só um IP público e um retransmissor.
        crate::contacts::set_addrs(
            bob_store.lock().unwrap().conn(),
            alice_at_bob,
            &[
                "203.0.113.9:4000".to_owned(),
                "https://relay.example.org/".to_owned(),
            ],
        )
        .unwrap();
        assert!(bob
            .usable(&[
                "203.0.113.9:4000".into(),
                "https://relay.example.org/".into()
            ])
            .is_empty());
        messages::send_text(&mut bob_store.lock().unwrap(), alice_at_bob, "oi", None).unwrap();
        bob.flush(alice_at_bob);
        until("Bob gives up on Alice", || {
            bob.reach(alice_at_bob) == Reach::Unreachable
        })
        .await;
        // A internet desligada não manda os endereços públicos a ninguém.
        assert!(bob
            .addrs()
            .iter()
            .all(|a| is_local(a) || a.ip().is_loopback()));
        assert_eq!(bob.relay(), None);
        bob.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn messages_wait_for_a_contact_that_was_off() {
        use crate::messages::{self, Status};
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
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
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
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
    async fn a_message_waits_in_the_mailbox_while_the_contact_is_off() {
        use crate::messages::{self, Status};
        use chirp_mailbox::server::{self, Config, Server};
        let dir = tempfile::tempdir().unwrap();
        let mailbox_server = Server::start(Config {
            dir: dir.path().to_path_buf(),
            port: 0,
            public: vec![],
            relay: None,
            limits: Default::default(),
        })
        .await
        .unwrap();
        chirp_mailbox::store::create_pairing(dir.path(), [4; 32], server::now()).unwrap();
        let link = PairLink {
            endpoint_id: *mailbox_server.endpoint.id().as_bytes(),
            token: [4; 32],
            addrs: mailbox_server.endpoint.addr().ip_addrs().copied().collect(),
            relay: None,
        };

        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        let (bob_at_alice, alice_at_bob) = befriend(&alice_store, &alice, &bob).await;
        let alice_knows = |store: &SharedStore| {
            mailbox::theirs(store.lock().unwrap().conn(), bob_at_alice)
                .unwrap()
                .is_some()
        };

        // O código serve uma vez só.
        bob.pair_mailbox(link.clone()).await.unwrap();
        assert_eq!(
            alice.pair_mailbox(link).await.err(),
            Some(CoreError::MailboxRefused)
        );
        until("Alice learns about Bob's mailbox", || {
            alice_knows(&alice_store)
        })
        .await;
        bob.close().await;

        messages::send_text(
            &mut alice_store.lock().unwrap(),
            bob_at_alice,
            "na caixa",
            None,
        )
        .unwrap();
        alice.flush(bob_at_alice);
        until("the message waits in the mailbox", || {
            let list =
                messages::list(alice_store.lock().unwrap().conn(), bob_at_alice, None, 10).unwrap();
            list.last()
                .is_some_and(|m| m.in_mailbox && m.status == Status::Pending)
        })
        .await;

        // Bob volta: busca na caixa, e o "entregue" chega a Alice.
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        until("Bob reads the mailbox", || {
            texts(&bob_store, alice_at_bob)
                .iter()
                .map(|(t, _)| t.as_str())
                .collect::<Vec<_>>()
                == ["na caixa"]
        })
        .await;
        until("Alice sees it delivered", || {
            let list =
                messages::list(alice_store.lock().unwrap().conn(), bob_at_alice, None, 10).unwrap();
            list.last()
                .is_some_and(|m| !m.in_mailbox && m.status == Status::Delivered)
        })
        .await;
        assert_eq!(bob.mailbox_ok(), Some(true));

        // Bob desliga: Alice esquece a caixa.
        bob.unpair_mailbox().await.unwrap();
        until("Alice forgets the mailbox", || !alice_knows(&alice_store)).await;
        for node in [alice, bob] {
            node.close().await;
        }
        mailbox_server.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn first_contact_through_the_mailboxes_with_nobody_online_together() {
        use crate::messages;
        use chirp_mailbox::server::{self, Config, Server};
        let dir = tempfile::tempdir().unwrap();
        // Uma caixa de verdade, com Bob e Alice como donos.
        let mailbox_server = Server::start(Config {
            dir: dir.path().to_path_buf(),
            port: 0,
            public: vec![],
            relay: None,
            limits: Default::default(),
        })
        .await
        .unwrap();
        let link = |code: u8| {
            chirp_mailbox::store::create_pairing(dir.path(), [code; 32], server::now()).unwrap();
            PairLink {
                endpoint_id: *mailbox_server.endpoint.id().as_bytes(),
                token: [code; 32],
                addrs: mailbox_server.endpoint.addr().ip_addrs().copied().collect(),
                relay: None,
            }
        };
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        bob.pair_mailbox(link(1)).await.unwrap();
        alice.pair_mailbox(link(2)).await.unwrap();

        // Bob manda o link e desliga.
        let invite = bob.create_invite(InviteKind::Link).await.unwrap();
        assert!(invite.mailbox.is_some(), "as prekeys foram para a caixa");
        let invite = Invite::from_link(&invite.to_link()).unwrap();
        bob.close().await;

        // Alice lê com Bob desligado: o pedido fica na caixa dele.
        let pending = alice.join(invite.clone(), false).await.unwrap();
        assert_eq!(pending.state, ContactState::Pending);
        assert_eq!(
            alice.join(invite, false).await.err(),
            Some(CoreError::AlreadyExists)
        );
        until("Alice's mailbox takes Bob's drop", || {
            let store = alice_store.lock().unwrap();
            let synced = mailbox::get(store.conn()).unwrap().unwrap().synced;
            synced == Some(mailbox::digest(&mailbox::drops(store.conn()).unwrap()))
        })
        .await;
        alice.close().await;

        // Bob volta: aceita o pedido, e a resposta e um "oi" vão para a caixa de Alice.
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        until("Bob gets Alice's request", || {
            contacts(&bob_store)
                .iter()
                .any(|c| c.display_name == "Alice" && c.state == ContactState::Established)
        })
        .await;
        let alice_at_bob = contacts(&bob_store)[0].id;
        messages::send_text(
            &mut bob_store.lock().unwrap(),
            alice_at_bob,
            "oi, Alice",
            None,
        )
        .unwrap();
        bob.flush(alice_at_bob);
        until("Bob's outbox goes to Alice's mailbox", || {
            messages::waiting(bob_store.lock().unwrap().conn())
                .unwrap()
                .is_empty()
        })
        .await;
        bob.close().await;

        // Alice volta: o contato fecha e o "oi" chega, sem os dois nunca juntos.
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        until("Alice gets Bob's welcome and text", || {
            let bob_at_alice = contacts(&alice_store)[0].clone();
            bob_at_alice.state == ContactState::Established
                && bob_at_alice.display_name == "Bob"
                && texts(&alice_store, bob_at_alice.id)
                    .iter()
                    .any(|(t, _)| t == "oi, Alice")
        })
        .await;
        alice.close().await;
        mailbox_server.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn discovery_finds_a_contact_that_moved() {
        use crate::messages::{self, Status};
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
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
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
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

    /// Ana conhece Bia e Caio, que não se conhecem. Ana faz um grupo com os dois: o
    /// grupo apresenta Bia e Caio (um convite repassado por Ana), e a mensagem de Bia
    /// chega a Caio. O contato novo fica fora da lista de conversas.
    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn a_group_introduces_members_who_did_not_know_each_other() {
        use crate::messages;
        let (ana_store, bia_store, caio_store) = (device("Ana"), device("Bia"), device("Caio"));
        let ana = Node::start_test(ana_store.clone()).await.unwrap();
        let bia = Node::start_test(bia_store.clone()).await.unwrap();
        let caio = Node::start_test(caio_store.clone()).await.unwrap();
        for other in [&bia, &caio] {
            let invite = ana.create_invite(InviteKind::Qr).await.unwrap();
            other.join(invite, true).await.unwrap();
        }
        until("Ana knows both", || {
            contacts(&ana_store)
                .iter()
                .filter(|c| c.state == ContactState::Established)
                .count()
                == 2
        })
        .await;
        let ids: Vec<i64> = contacts(&ana_store).iter().map(|c| c.id).collect();
        let group = crate::groups::create(&mut ana_store.lock().unwrap(), "Bando", &ids).unwrap();
        for id in &ids {
            ana.flush(*id);
        }
        let key =
            |store: &SharedStore| crate::session::me(&store.lock().unwrap()).unwrap().public();
        let (bia_key, caio_key) = (key(&bia_store), key(&caio_store));
        let knows = |store: &SharedStore, other: &[u8]| {
            crate::contacts::by_identity(store.lock().unwrap().conn(), other)
                .unwrap()
                .is_some_and(|c| c.state == ContactState::Established)
        };
        until("Bia and Caio meet through the group", || {
            knows(&bia_store, &caio_key) && knows(&caio_store, &bia_key)
        })
        .await;
        // Fora da lista de conversas: só o grupo e Ana aparecem.
        for store in [&bia_store, &caio_store] {
            let listed = messages::conversations(store.lock().unwrap().conn()).unwrap();
            assert_eq!(listed.len(), 2, "Ana and the group");
        }

        let bia_group: i64 = bia_store
            .lock()
            .unwrap()
            .conn()
            .query_row("SELECT contact_id FROM groups", [], |r| r.get(0))
            .unwrap();
        messages::send_text(&mut bia_store.lock().unwrap(), bia_group, "oi, Caio", None).unwrap();
        let caio_at_bia = crate::contacts::by_identity(bia_store.lock().unwrap().conn(), &caio_key)
            .unwrap()
            .unwrap()
            .id;
        bia.flush(caio_at_bia);
        until("Caio gets Bia's group message", || {
            let conn = caio_store.lock().unwrap();
            conn.conn()
                .query_row(
                    "SELECT count(*) FROM messages WHERE body = 'oi, Caio' AND author = ?1",
                    [&bia_key],
                    |r| r.get::<_, i64>(0),
                )
                .unwrap()
                == 1
        })
        .await;
        let _ = group;
        for node in [ana, bia, caio] {
            node.close().await;
        }
    }

    /// Os dois ficam sem caminho pela rede (sem mDNS e com um endereço que não serve)
    /// e com um rádio no mesmo ar.
    async fn ble_pair(
        air: &ble::memory::Air,
    ) -> (SharedStore, SharedStore, Arc<Node>, Arc<Node>, i64, i64) {
        let (alice_store, bob_store) = (device("Alice"), device("Bob"));
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        let (bob_at_alice, alice_at_bob) = befriend(&alice_store, &alice, &bob).await;
        alice.close().await;
        bob.close().await;
        for store in [&alice_store, &bob_store] {
            store
                .lock()
                .unwrap()
                .conn()
                .execute_batch(
                    "UPDATE contacts SET addrs = '192.0.2.1:9';
                     UPDATE network SET bluetooth = 1;",
                )
                .unwrap();
        }
        let radio = |name: &str| Some(air.radio(name) as Arc<dyn Radio>);
        let events = || broadcast::channel(256).0;
        let alice = Node::start_with(alice_store.clone(), events(), radio("alice"), false)
            .await
            .unwrap();
        let bob = Node::start_with(bob_store.clone(), events(), radio("bob"), false)
            .await
            .unwrap();
        (
            alice_store,
            bob_store,
            alice,
            bob,
            bob_at_alice,
            alice_at_bob,
        )
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn messages_go_by_bluetooth_with_no_network() {
        use crate::messages::{self, Status};
        let air = ble::memory::Air::default();
        let (alice_store, bob_store, alice, bob, bob_at_alice, alice_at_bob) = ble_pair(&air).await;
        messages::send_text(
            &mut alice_store.lock().unwrap(),
            bob_at_alice,
            "perto",
            None,
        )
        .unwrap();
        alice.flush(bob_at_alice);
        until("Bob gets it by Bluetooth", || {
            texts(&bob_store, alice_at_bob)
                .iter()
                .map(|(t, _)| t.as_str())
                .eq(["perto"])
        })
        .await;
        until("Alice sees it delivered", || {
            texts(&alice_store, bob_at_alice) == [("perto".to_owned(), Status::Delivered)]
        })
        .await;
        assert_eq!(alice.reach(bob_at_alice), Reach::Bluetooth);
        assert_eq!(bob.reach(alice_at_bob), Reach::Bluetooth);
        assert_eq!(alice.bluetooth(), Some(true));

        // E de volta.
        messages::send_text(&mut bob_store.lock().unwrap(), alice_at_bob, "oi", None).unwrap();
        bob.flush(alice_at_bob);
        until("Alice gets the answer", || {
            texts(&alice_store, bob_at_alice)
                .iter()
                .any(|(t, _)| t == "oi")
        })
        .await;
        alice.close().await;
        bob.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn messages_wait_until_the_contact_comes_near() {
        use crate::messages::{self, Status};
        let air = ble::memory::Air::default();
        air.radio("bob");
        air.set_on("bob", false);
        let (alice_store, bob_store, alice, bob, bob_at_alice, alice_at_bob) = {
            let pair = ble_pair(&air).await;
            air.set_on("bob", false);
            pair
        };
        messages::send_text(
            &mut alice_store.lock().unwrap(),
            bob_at_alice,
            "longe",
            None,
        )
        .unwrap();
        alice.flush(bob_at_alice);
        tokio::time::sleep(Duration::from_millis(500)).await;
        assert_eq!(
            texts(&alice_store, bob_at_alice),
            [("longe".to_owned(), Status::Pending)]
        );
        // Bob chega perto: o anúncio dele aparece, e o que esperava sai.
        air.set_on("bob", true);
        until("Bob gets it when near", || {
            texts(&bob_store, alice_at_bob).len() == 1
        })
        .await;
        alice.close().await;
        bob.close().await;
    }

    /// Eve repete o anúncio de Bob: Alice conecta, vê que a chave não é a de Bob e não
    /// manda nada.
    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn a_copied_advert_gets_nothing() {
        use crate::messages::{self, Status};
        let air = ble::memory::Air::default();
        let (alice_store, _bob_store, alice, bob, bob_at_alice, _) = ble_pair(&air).await;
        let bob_advert = {
            let key: Vec<u8> = contacts(&alice_store)[0].discovery_key.clone();
            ble::advert(
                &ble::token(&key, discovery::epoch(Node::now_secs())),
                0x0081,
            )
        };
        bob.close().await;
        air.set_on("bob", false);

        let eve = air.radio("eve");
        let (_, mut incoming) = eve.listen().await.unwrap();
        let tried = Arc::new(std::sync::atomic::AtomicBool::new(false));
        let eve_tried = tried.clone();
        tokio::spawn(async move {
            let mut bytes = [0u8; 32];
            getrandom::fill(&mut bytes).unwrap();
            let eve_key = SecretKey::from_bytes(&bytes);
            while let Some(link) = incoming.recv().await {
                eve_tried.store(true, std::sync::atomic::Ordering::Relaxed);
                if let Ok((mut channel, _)) = ble::secure::respond(link, &eve_key).await {
                    let mut buf = Vec::new();
                    let _ = tokio::time::timeout(
                        Duration::from_secs(2),
                        tokio::io::AsyncReadExt::read_to_end(&mut channel, &mut buf),
                    )
                    .await;
                    assert!(buf.is_empty(), "nothing goes to Eve");
                }
            }
        });
        eve.advertise(bob_advert).await.unwrap();
        messages::send_text(
            &mut alice_store.lock().unwrap(),
            bob_at_alice,
            "segredo",
            None,
        )
        .unwrap();
        alice.flush(bob_at_alice);
        until("Alice tries Eve", || {
            tried.load(std::sync::atomic::Ordering::Relaxed)
        })
        .await;
        tokio::time::sleep(Duration::from_millis(500)).await;
        assert_eq!(
            texts(&alice_store, bob_at_alice),
            [("segredo".to_owned(), Status::Pending)]
        );
        assert_ne!(alice.reach(bob_at_alice), Reach::Bluetooth);
        alice.close().await;
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn an_impostor_node_cannot_take_an_invite_meant_for_another() {
        // Mallory conhece o convite (viu o QR), mas fala com a chave de nó dela: o
        // aperto de mão fecha com a identidade dela, não com a de Bob. Ninguém se passa
        // por ninguém: Alice fica com "Mallory", e Bob não ganha contato nenhum.
        let alice_store = device("Alice");
        let alice = Node::start_test(alice_store.clone()).await.unwrap();
        let mallory = Node::start_test(device("Mallory")).await.unwrap();
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
        let bob = Node::start_test(bob_store.clone()).await.unwrap();
        let alice = Node::start_test(device("Alice")).await.unwrap();
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

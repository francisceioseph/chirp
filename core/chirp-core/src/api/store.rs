//! O banco e o perfil, pela ponte. O Dart guarda a chave no cofre do sistema e a
//! entrega aqui; sem cofre, entrega a senha, e a chave é derivada aqui dentro.
//!
//! Os arquivos ficam na pasta que o Dart passa (a pasta de suporte do app):
//! `chirp.db`, o banco cifrado, e `chirp.salt`, só quando a chave vem de uma senha.

use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock};

use flutter_rust_bridge::frb;
use zeroize::Zeroizing;

use crate::appearance;
use crate::contacts::{Contact, ContactState};
pub use crate::error::CoreError;
use crate::error::CoreResult;
use crate::frb_generated::StreamSink;
use crate::identity::{avatar_seed, fingerprint};
use crate::invite::Invite;
use crate::messages::{self, Kind, Message, Status};
use crate::network;
use crate::node::{Node, NodeEvent, Reach};
use crate::notifications;
use crate::passphrase;
use crate::profile::StoredProfile;
use crate::random::secret_bytes;
use crate::session::{self, InviteKind};
use crate::store::Store;

const DB_FILE: &str = "chirp.db";
const SALT_FILE: &str = "chirp.salt";
/// O que o SQLite pode deixar ao lado do banco.
const DB_SIDE_FILES: &[&str] = &["chirp.db-journal", "chirp.db-wal", "chirp.db-shm"];

/// Como abrir o banco desta pasta.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StoreState {
    /// Ainda não existe: é a primeira abertura.
    Missing,
    /// A chave está no cofre do sistema.
    KeyInVault,
    /// A chave vem de uma senha.
    Passphrase,
}

/// O perfil como a UI mostra.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Profile {
    pub display_name: String,
    pub version: u32,
    /// A impressão digital da identidade: 30 dígitos em 6 grupos de 5.
    pub fingerprint: String,
    /// A semente do avatar gerado.
    pub avatar_seed: u32,
}

impl From<StoredProfile> for Profile {
    fn from(stored: StoredProfile) -> Self {
        Self {
            fingerprint: fingerprint(&stored.public_key),
            avatar_seed: avatar_seed(&stored.public_key),
            display_name: stored.display_name,
            version: stored.version,
        }
    }
}

#[frb(sync)]
pub fn store_state(dir: String) -> StoreState {
    let dir = PathBuf::from(dir);
    if !dir.join(DB_FILE).exists() {
        StoreState::Missing
    } else if dir.join(SALT_FILE).exists() {
        StoreState::Passphrase
    } else {
        StoreState::KeyInVault
    }
}

/// Uma chave nova para o banco, para o Dart guardar no cofre.
#[frb(sync)]
pub fn new_store_key() -> Result<Vec<u8>, CoreError> {
    Ok(secret_bytes::<32>()?.to_vec())
}

#[frb(sync)]
pub fn min_passphrase_chars() -> u32 {
    passphrase::MIN_PASSPHRASE_CHARS as u32
}

/// Apaga o banco e o sal. Sem a chave (que o Dart tira do cofre), o que sobrar no
/// disco não se lê.
pub fn wipe_store(dir: String) -> Result<(), CoreError> {
    let dir = PathBuf::from(dir);
    for name in [DB_FILE, SALT_FILE].iter().chain(DB_SIDE_FILES) {
        match std::fs::remove_file(dir.join(name)) {
            Ok(()) => {}
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
            Err(e) => return Err(e.into()),
        }
    }
    // Os arquivos cifrados também: sem o banco, ninguém mais abre, mas não ficam.
    match std::fs::remove_dir_all(dir.join("files")) {
        Ok(()) => {}
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
        Err(e) => return Err(e.into()),
    }
    Ok(())
}

/// Um contato como a UI mostra.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ContactView {
    pub id: i64,
    pub display_name: String,
    pub avatar_seed: u32,
    /// O número de segurança foi conferido (QR frente a frente, ou marcado à mão).
    pub verified: bool,
    /// O aperto de mão fechou dos dois lados.
    pub established: bool,
    /// Por onde foi alcançado da última vez, com a rede ligada.
    pub reach: ContactReach,
}

/// Por onde um contato foi alcançado da última vez.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ContactReach {
    /// Ainda não tentou (ou a rede está desligada).
    Unknown,
    /// Direto, na rede local.
    Lan,
    /// Direto, pela internet.
    Direct,
    /// Pelo servidor de retransmissão.
    Relay,
    /// Não alcançou.
    Unreachable,
}

impl From<Reach> for ContactReach {
    fn from(reach: Reach) -> Self {
        match reach {
            Reach::Unknown => ContactReach::Unknown,
            Reach::Lan => ContactReach::Lan,
            Reach::Direct => ContactReach::Direct,
            Reach::Relay => ContactReach::Relay,
            Reach::Unreachable => ContactReach::Unreachable,
        }
    }
}

/// A internet e os servidores de retransmissão (os dois desligados no começo).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NetworkSettings {
    pub internet: bool,
    /// Os endereços dos retransmissores (`https://...`), até três.
    pub relays: Vec<String>,
}

/// Como a rede está agora, para a tela de Rede.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NetworkStatus {
    /// O nó está ligado.
    pub running: bool,
    pub internet: bool,
    /// Quantos retransmissores estão configurados (e valem: com a internet ligada).
    pub relays: u32,
    /// Algum retransmissor respondeu.
    pub relay_connected: bool,
}

impl From<Contact> for ContactView {
    fn from(contact: Contact) -> Self {
        Self {
            id: contact.id,
            avatar_seed: avatar_seed(&contact.identity_key),
            display_name: contact.display_name,
            verified: contact.verified,
            established: contact.state == ContactState::Established,
            reach: ContactReach::Unknown,
        }
    }
}

/// O que muda sem a UI pedir.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EventKind {
    /// Um contato novo ou mudado. Com o id 0, a UI relê tudo (perdeu eventos).
    Contact,
    /// A conversa com o contato mudou.
    Messages,
    /// O contato está digitando.
    Typing,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CoreEvent {
    pub kind: EventKind,
    pub contact_id: i64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MessageKind {
    Text,
    /// Chamou atenção.
    Nudge,
    /// Um arquivo (o `file` da mensagem diz qual).
    File,
}

/// Em que pé está um arquivo.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FileState {
    /// Grande demais para baixar sozinho: espera quem usa pedir.
    Waiting,
    /// Baixando, ou esperando o contato aparecer.
    Downloading,
    /// Inteiro e conferido: dá para abrir e salvar.
    Done,
    /// O que chegou não bateu com o hash da oferta.
    Failed,
}

/// O arquivo de uma mensagem.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FileView {
    pub name: String,
    pub size: u64,
    pub mime: String,
    /// A miniatura em JPEG (vazia se não houver).
    pub thumbnail: Vec<u8>,
    /// Quantas fatias já estão aqui, de quantas.
    pub received: u32,
    pub chunks: u32,
    pub state: FileState,
}

impl From<crate::files::FileRow> for FileView {
    fn from(row: crate::files::FileRow) -> Self {
        Self {
            name: row.name,
            size: row.size,
            mime: row.mime,
            thumbnail: row.thumbnail.unwrap_or_default(),
            received: row.received,
            chunks: row.chunks,
            state: match row.state {
                crate::files::State::Waiting => FileState::Waiting,
                crate::files::State::Downloading => FileState::Downloading,
                crate::files::State::Done => FileState::Done,
                crate::files::State::Failed => FileState::Failed,
            },
        }
    }
}

/// Para as minhas: na fila, entregue, lida. Para as do contato: `Pending` é não lida.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MessageStatus {
    Pending,
    Delivered,
    Read,
}

/// Uma mensagem como a UI mostra.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MessageView {
    pub id: i64,
    pub contact_id: i64,
    pub outgoing: bool,
    pub kind: MessageKind,
    pub text: String,
    /// A mensagem citada, se ela existe neste aparelho.
    pub reply_to: Option<i64>,
    /// Quando foi mandada (pelo relógio de quem mandou), em milissegundos.
    pub sent_at: i64,
    /// Quando chegou aqui (ou foi escrita), em milissegundos.
    pub received_at: i64,
    pub status: MessageStatus,
    pub edited: bool,
    pub deleted: bool,
    /// As reações (0 é nenhuma, 1 a `reaction_kinds()`).
    pub my_reaction: u32,
    pub their_reaction: u32,
    /// Ainda dá para editar ou apagar para todos.
    pub can_edit: bool,
    pub can_delete_for_everyone: bool,
    /// O arquivo, se a mensagem é um.
    pub file: Option<FileView>,
}

/// A mensagem com o arquivo dela, se for um.
fn with_file(conn: &rusqlite::Connection, m: Message) -> MessageView {
    let file = if m.kind == Kind::File {
        crate::files::by_message(conn, m.id)
            .ok()
            .flatten()
            .map(FileView::from)
    } else {
        None
    };
    MessageView { file, ..m.into() }
}

impl From<Message> for MessageView {
    fn from(m: Message) -> Self {
        let age = messages::now_ms() - m.received_at;
        let own_text = m.outgoing && m.kind == Kind::Text && !m.deleted;
        let own = m.outgoing && m.kind != Kind::Nudge && !m.deleted;
        Self {
            id: m.id,
            contact_id: m.contact_id,
            outgoing: m.outgoing,
            kind: match m.kind {
                Kind::Text => MessageKind::Text,
                Kind::Nudge => MessageKind::Nudge,
                Kind::File => MessageKind::File,
            },
            text: m.body,
            reply_to: m.reply_to,
            sent_at: m.sent_at,
            received_at: m.received_at,
            status: match m.status {
                Status::Pending => MessageStatus::Pending,
                Status::Delivered => MessageStatus::Delivered,
                Status::Read => MessageStatus::Read,
            },
            edited: m.edited,
            deleted: m.deleted,
            my_reaction: m.my_reaction,
            their_reaction: m.their_reaction,
            can_edit: own_text && age <= messages::EDIT_WINDOW_MS,
            can_delete_for_everyone: own && age <= messages::DELETE_WINDOW_MS,
            file: None,
        }
    }
}

/// Uma conversa na lista.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConversationView {
    pub contact: ContactView,
    pub last: Option<MessageView>,
    pub unread: u32,
}

/// Os recibos de leitura e o "digitando": desligar vale para os dois lados.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ChatSettings {
    pub read_receipts: bool,
    pub typing: bool,
}

/// O que as notificações mostram: nada, só "Nova mensagem", o nome, ou o nome e o
/// texto.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NotificationMode {
    Off,
    Hidden,
    Sender,
    Full,
}

/// Claro, escuro ou o que o sistema disser.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ThemeBrightness {
    System,
    Light,
    Dark,
}

/// A aparência: o id do tema (uma semente da UI), o claro ou escuro e o efeito vidro.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppearanceView {
    pub theme: String,
    pub brightness: ThemeBrightness,
    pub glass: bool,
}

/// Quantos tipos de reação há (a UI desenha cada um com um ícone).
#[frb(sync)]
pub fn reaction_kinds() -> u32 {
    messages::REACTIONS
}

/// O texto mais comprido de uma mensagem, em caracteres.
#[frb(sync)]
pub fn max_message_chars() -> u32 {
    messages::MAX_TEXT_CHARS as u32
}

/// O runtime do tokio da rede, um por processo.
fn runtime() -> &'static tokio::runtime::Runtime {
    static RUNTIME: OnceLock<tokio::runtime::Runtime> = OnceLock::new();
    RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .build()
            .expect("the network runtime starts")
    })
}

/// O banco aberto, e o nó da rede depois do `start_network`. A trava serializa quem
/// chama.
#[frb(opaque)]
pub struct ChirpStore {
    inner: Arc<Mutex<Store>>,
    node: Mutex<Option<Arc<Node>>>,
    /// Os eventos do nó; ficam aqui para a UI não perder o fio quando o nó reinicia.
    events: tokio::sync::broadcast::Sender<NodeEvent>,
}

impl ChirpStore {
    /// Abre (ou cria) com a chave do cofre.
    pub fn open_with_key(dir: String, key: Vec<u8>) -> Result<ChirpStore, CoreError> {
        let key = Zeroizing::new(key);
        let key: &[u8; 32] = key.as_slice().try_into().map_err(|_| CoreError::BadKey)?;
        Self::open(&PathBuf::from(dir), key)
    }

    /// Cria o banco protegido por uma senha, na primeira abertura sem cofre.
    pub fn create_with_passphrase(
        dir: String,
        passphrase: String,
    ) -> Result<ChirpStore, CoreError> {
        let passphrase = Zeroizing::new(passphrase);
        let dir = PathBuf::from(dir);
        if dir.join(DB_FILE).exists() {
            return Err(CoreError::AlreadyExists);
        }
        std::fs::create_dir_all(&dir)?;
        let salt = dir.join(SALT_FILE);
        let key = passphrase::create(&salt, &passphrase)?;
        Self::open(&dir, &key).inspect_err(|_| {
            let _ = std::fs::remove_file(&salt);
        })
    }

    /// Abre o banco protegido por senha. A senha errada dá `WrongKey`.
    pub fn open_with_passphrase(dir: String, passphrase: String) -> Result<ChirpStore, CoreError> {
        let passphrase = Zeroizing::new(passphrase);
        let dir = PathBuf::from(dir);
        if !dir.join(DB_FILE).exists() {
            return Err(CoreError::Storage);
        }
        let key = passphrase::unlock(&dir.join(SALT_FILE), &passphrase)?;
        Self::open(&dir, &key)
    }

    fn open(dir: &Path, key: &[u8; 32]) -> CoreResult<ChirpStore> {
        std::fs::create_dir_all(dir)?;
        Ok(ChirpStore {
            inner: Arc::new(Mutex::new(Store::open(&dir.join(DB_FILE), key)?)),
            node: Mutex::new(None),
            events: tokio::sync::broadcast::channel(256).0,
        })
    }

    pub fn profile(&self) -> Result<Option<Profile>, CoreError> {
        Ok(self.lock()?.profile()?.map(Profile::from))
    }

    pub fn create_profile(&self, name: String) -> Result<Profile, CoreError> {
        Ok(self.lock()?.create_profile(&name)?.into())
    }

    /// Troca o nome e manda o perfil novo a cada contato.
    pub fn rename(&self, name: String) -> Result<Profile, CoreError> {
        let (profile, contacts) = {
            let mut store = self.lock()?;
            let profile = store.rename(&name)?;
            // O nome já mudou aqui; se não der para avisar agora, avisa na próxima.
            (
                profile,
                messages::send_profile(&mut store).unwrap_or_default(),
            )
        };
        for id in contacts {
            self.flush(id);
        }
        Ok(profile.into())
    }

    /// Pede a entrega ao contato, se a rede está ligada. Sem ela, fica na caixa de
    /// saída até ligar.
    fn flush(&self, contact_id: i64) {
        if let Ok(slot) = self.node.lock() {
            if let Some(node) = slot.as_ref() {
                node.flush(contact_id);
            }
        }
    }

    fn lock(&self) -> CoreResult<std::sync::MutexGuard<'_, Store>> {
        self.inner.lock().map_err(|_| CoreError::Storage)
    }

    fn running(&self) -> Option<Arc<Node>> {
        self.node.lock().ok().and_then(|slot| slot.clone())
    }

    /// O contato como a UI mostra, com o caminho de agora.
    fn view(&self, contact: Contact) -> ContactView {
        let reach = self
            .running()
            .map(|n| n.reach(contact.id).into())
            .unwrap_or(ContactReach::Unknown);
        ContactView {
            reach,
            ..contact.into()
        }
    }

    pub fn network_settings(&self) -> Result<NetworkSettings, CoreError> {
        let s = network::get(self.lock()?.conn())?;
        Ok(NetworkSettings {
            internet: s.internet,
            relays: s.relays,
        })
    }

    /// Grava a internet e os retransmissores (conferidos) e, se o nó está ligado,
    /// religa com eles. Devolve o que ficou gravado.
    pub fn set_network_settings(
        &self,
        settings: NetworkSettings,
    ) -> Result<NetworkSettings, CoreError> {
        let saved = network::set(
            self.lock()?.conn(),
            &network::Settings {
                internet: settings.internet,
                relays: settings.relays,
            },
        )?;
        if self.running().is_some() {
            self.stop_node()?;
            self.started()?;
            // A UI relê tudo: os caminhos de antes não valem mais.
            let _ = self.events.send(NodeEvent::ContactChanged(0));
        }
        Ok(NetworkSettings {
            internet: saved.internet,
            relays: saved.relays,
        })
    }

    pub fn network_status(&self) -> Result<NetworkStatus, CoreError> {
        let settings = network::get(self.lock()?.conn())?;
        let node = self.running();
        let (_, relay_connected) = node.as_ref().map(|n| n.internet()).unwrap_or_default();
        Ok(NetworkStatus {
            running: node.is_some(),
            internet: settings.internet,
            relays: settings.relay_urls().len() as u32,
            relay_connected,
        })
    }

    /// Liga o nó da rede local. Pede o perfil (a identidade); chamar de novo não faz
    /// nada.
    pub fn start_network(&self) -> Result<(), CoreError> {
        self.started().map(|_| ())
    }

    /// Desliga o nó (antes de apagar tudo, por exemplo) e fecha o fluxo de eventos.
    pub fn stop_network(&self) -> Result<(), CoreError> {
        self.stop_node()?;
        let _ = self.events.send(NodeEvent::Closed);
        Ok(())
    }

    /// Desliga só o nó: o fluxo de eventos continua (religar com outros ajustes).
    fn stop_node(&self) -> CoreResult<()> {
        let node = self.node.lock().map_err(|_| CoreError::Storage)?.take();
        if let Some(node) = node {
            runtime().block_on(node.close());
        }
        Ok(())
    }

    fn started(&self) -> CoreResult<Arc<Node>> {
        let mut slot = self.node.lock().map_err(|_| CoreError::Storage)?;
        if let Some(node) = slot.as_ref() {
            return Ok(node.clone());
        }
        if self.lock()?.profile()?.is_none() {
            return Err(CoreError::NoProfile);
        }
        let node = runtime().block_on(Node::start(self.inner.clone(), self.events.clone()))?;
        *slot = Some(node.clone());
        Ok(node)
    }

    /// Um convite novo, como link. [qr] diz se vai ser mostrado como QR (frente a
    /// frente: o contato nasce verificado) ou mandado como link.
    pub fn create_invite(&self, qr: bool) -> Result<String, CoreError> {
        let node = self.started()?;
        let kind = if qr { InviteKind::Qr } else { InviteKind::Link };
        Ok(runtime().block_on(node.create_invite(kind))?.to_link())
    }

    /// Lê um convite e faz o aperto de mão. [scanned]: veio de um QR lido frente a
    /// frente.
    pub fn add_contact(&self, link: String, scanned: bool) -> Result<ContactView, CoreError> {
        let invite = Invite::from_link(&link)?;
        let node = self.started()?;
        Ok(runtime().block_on(node.join(invite, scanned))?.into())
    }

    pub fn contacts(&self) -> Result<Vec<ContactView>, CoreError> {
        Ok(crate::contacts::list(self.lock()?.conn())?
            .into_iter()
            .map(|c| self.view(c))
            .collect())
    }

    /// O número de segurança com um contato: 60 dígitos, igual nos dois aparelhos.
    pub fn safety_number(&self, contact_id: i64) -> Result<String, CoreError> {
        let store = self.lock()?;
        let contact = crate::contacts::by_id(store.conn(), contact_id)?;
        let own = session::identity_pair(&store)?;
        session::safety_number(&own.identity_key().serialize(), &contact.identity_key)
    }

    pub fn set_verified(&self, contact_id: i64, verified: bool) -> Result<ContactView, CoreError> {
        Ok(crate::contacts::set_verified(self.lock()?.conn(), contact_id, verified)?.into())
    }

    /// Avisa a UI do que muda sem ela pedir: alguém leu um convite nosso, chegou
    /// mensagem, o contato está digitando.
    pub fn watch_events(&self, sink: StreamSink<CoreEvent>) -> Result<(), CoreError> {
        self.started()?;
        let mut events = self.events.subscribe();
        runtime().spawn(async move {
            loop {
                let event = match events.recv().await {
                    Ok(NodeEvent::ContactChanged(id)) => CoreEvent {
                        kind: EventKind::Contact,
                        contact_id: id,
                    },
                    Ok(NodeEvent::MessagesChanged(id)) => CoreEvent {
                        kind: EventKind::Messages,
                        contact_id: id,
                    },
                    Ok(NodeEvent::Typing(id)) => CoreEvent {
                        kind: EventKind::Typing,
                        contact_id: id,
                    },
                    // A rede desligou: o fluxo fecha, como fechava com o nó.
                    Ok(NodeEvent::Closed) => break,
                    // Perdeu eventos: o id 0 faz a UI reler tudo.
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => CoreEvent {
                        kind: EventKind::Contact,
                        contact_id: 0,
                    },
                    Err(_) => break,
                };
                if sink.add(event).is_err() {
                    break;
                }
            }
        });
        Ok(())
    }

    /// As conversas, a mais recente primeiro.
    pub fn conversations(&self) -> Result<Vec<ConversationView>, CoreError> {
        Ok(messages::conversations(self.lock()?.conn())?
            .into_iter()
            .map(|c| ConversationView {
                contact: self.view(c.contact),
                last: c.last.map(MessageView::from),
                unread: c.unread,
            })
            .collect())
    }

    /// As últimas [limit] mensagens da conversa, em ordem; antes de [before] (o id de
    /// uma mensagem) para carregar as anteriores.
    pub fn messages(
        &self,
        contact_id: i64,
        before: Option<i64>,
        limit: u32,
    ) -> Result<Vec<MessageView>, CoreError> {
        let store = self.lock()?;
        Ok(messages::list(store.conn(), contact_id, before, limit)?
            .into_iter()
            .map(|m| with_file(store.conn(), m))
            .collect())
    }

    pub fn send_text(
        &self,
        contact_id: i64,
        text: String,
        reply_to: Option<i64>,
    ) -> Result<MessageView, CoreError> {
        let message = messages::send_text(&mut *self.lock()?, contact_id, &text, reply_to)?;
        self.flush(contact_id);
        Ok(message.into())
    }

    /// Chama a atenção do contato. Uma vez a cada 10 segundos (`TooSoon`).
    pub fn send_nudge(&self, contact_id: i64) -> Result<MessageView, CoreError> {
        let message = messages::send_nudge(&mut *self.lock()?, contact_id)?;
        self.flush(contact_id);
        Ok(message.into())
    }

    pub fn edit_message(&self, id: i64, text: String) -> Result<MessageView, CoreError> {
        let message = messages::edit(&mut *self.lock()?, id, &text)?;
        self.flush(message.contact_id);
        Ok(message.into())
    }

    pub fn delete_for_everyone(&self, id: i64) -> Result<MessageView, CoreError> {
        let mut store = self.lock()?;
        let message = messages::delete_for_everyone(&mut store, id)?;
        // O blob de um arquivo apagado sai já.
        crate::files::sweep(store.conn(), store.files_dir())?;
        drop(store);
        self.flush(message.contact_id);
        Ok(message.into())
    }

    pub fn delete_for_me(&self, id: i64) -> Result<(), CoreError> {
        let mut store = self.lock()?;
        messages::delete_for_me(&mut store, id)?;
        crate::files::sweep(store.conn(), store.files_dir())
    }

    /// Reage a uma mensagem ([kind] 0 tira a reação).
    pub fn react(&self, id: i64, kind: u32) -> Result<MessageView, CoreError> {
        let message = messages::react(&mut *self.lock()?, id, kind)?;
        self.flush(message.contact_id);
        Ok(message.into())
    }

    /// Estou digitando para o contato (a UI chama de tempos em tempos enquanto digita).
    /// Só sai se o contato está online agora.
    pub fn typing(&self, contact_id: i64) -> Result<(), CoreError> {
        let online = self
            .node
            .lock()
            .ok()
            .and_then(|slot| slot.as_ref().map(|n| n.is_online(contact_id)))
            .unwrap_or(false);
        if online && messages::typing(&mut *self.lock()?, contact_id)? {
            self.flush(contact_id);
        }
        Ok(())
    }

    /// Li a conversa: marca e manda o recibo, se ligado.
    pub fn mark_read(&self, contact_id: i64) -> Result<(), CoreError> {
        if messages::mark_read(&mut *self.lock()?, contact_id)? {
            self.flush(contact_id);
        }
        Ok(())
    }

    /// A busca no histórico de todas as conversas.
    pub fn search(&self, query: String) -> Result<Vec<MessageView>, CoreError> {
        let store = self.lock()?;
        Ok(messages::search(store.conn(), &query, 100)?
            .into_iter()
            .map(|m| with_file(store.conn(), m))
            .collect())
    }

    /// Manda o arquivo em [path] ao contato. Uma foto sai sem os metadados (o EXIF),
    /// e uma que não dá para limpar não sai.
    pub fn send_file(&self, contact_id: i64, path: String) -> Result<MessageView, CoreError> {
        let dir = self.lock()?.files_dir().to_path_buf();
        // Cifrar leva tempo num arquivo grande: o banco fica livre enquanto isso.
        let prepared = crate::files::prepare(&dir, std::path::Path::new(&path))?;
        let blob = crate::files::blob_path(&dir, &prepared.file_id);
        let mut store = self.lock()?;
        let message = match messages::send_file(&mut store, contact_id, prepared) {
            Ok(message) => message,
            Err(error) => {
                let _ = std::fs::remove_file(&blob);
                return Err(error);
            }
        };
        let view = with_file(store.conn(), message);
        drop(store);
        self.flush(contact_id);
        Ok(view)
    }

    /// Baixa (ou volta a baixar) o arquivo de uma mensagem do contato.
    pub fn download_file(&self, message_id: i64) -> Result<(), CoreError> {
        {
            let store = self.lock()?;
            let row = crate::files::by_message(store.conn(), message_id)?
                .ok_or(CoreError::UnknownMessage)?;
            if row.state == crate::files::State::Done {
                return Ok(());
            }
            if row.state == crate::files::State::Failed {
                crate::files::set_received(store.conn(), message_id, 0)?;
            }
            crate::files::set_state(store.conn(), message_id, crate::files::State::Downloading)?;
        }
        if let Some(node) = self.running() {
            node.fetch();
        }
        Ok(())
    }

    /// Salva uma cópia em claro do arquivo em [path] (o "Salvar em..."). Escreve ao
    /// lado e troca no fim, para não deixar um arquivo pela metade.
    pub fn save_file(&self, message_id: i64, path: String) -> Result<(), CoreError> {
        let (row, blob) = self.done_file(message_id)?;
        let dst = std::path::PathBuf::from(path);
        let part = dst.with_extension("chirp-part");
        let result = (|| {
            let mut out = std::io::BufWriter::new(std::fs::File::create(&part)?);
            crate::files::export(&blob, &row, &mut out)?;
            std::io::Write::flush(&mut out)?;
            drop(out);
            std::fs::rename(&part, &dst)?;
            Ok(())
        })();
        if result.is_err() {
            let _ = std::fs::remove_file(&part);
        }
        result
    }

    /// O arquivo em claro, na memória, para mostrar uma foto (até 32 MiB).
    pub fn file_bytes(&self, message_id: i64) -> Result<Vec<u8>, CoreError> {
        let (row, blob) = self.done_file(message_id)?;
        if row.size > crate::files::AUTO_DOWNLOAD {
            return Err(CoreError::InvalidFile);
        }
        let mut out = Vec::with_capacity(row.size as usize);
        crate::files::export(&blob, &row, &mut out)?;
        Ok(out)
    }

    fn done_file(
        &self,
        message_id: i64,
    ) -> CoreResult<(crate::files::FileRow, std::path::PathBuf)> {
        let store = self.lock()?;
        let row = crate::files::by_message(store.conn(), message_id)?
            .filter(|r| r.state == crate::files::State::Done)
            .ok_or(CoreError::UnknownMessage)?;
        let blob = crate::files::blob_path(store.files_dir(), &row.file_id);
        Ok((row, blob))
    }

    pub fn chat_settings(&self) -> Result<ChatSettings, CoreError> {
        let s = messages::settings(self.lock()?.conn())?;
        Ok(ChatSettings {
            read_receipts: s.read_receipts,
            typing: s.typing,
        })
    }

    pub fn set_chat_settings(&self, settings: ChatSettings) -> Result<(), CoreError> {
        messages::set_settings(
            self.lock()?.conn(),
            messages::Settings {
                read_receipts: settings.read_receipts,
                typing: settings.typing,
            },
        )
    }

    pub fn notification_mode(&self) -> Result<NotificationMode, CoreError> {
        Ok(match notifications::get(self.lock()?.conn())? {
            notifications::Mode::Off => NotificationMode::Off,
            notifications::Mode::Hidden => NotificationMode::Hidden,
            notifications::Mode::Sender => NotificationMode::Sender,
            notifications::Mode::Full => NotificationMode::Full,
        })
    }

    pub fn set_notification_mode(&self, mode: NotificationMode) -> Result<(), CoreError> {
        notifications::set(
            self.lock()?.conn(),
            match mode {
                NotificationMode::Off => notifications::Mode::Off,
                NotificationMode::Hidden => notifications::Mode::Hidden,
                NotificationMode::Sender => notifications::Mode::Sender,
                NotificationMode::Full => notifications::Mode::Full,
            },
        )
    }

    pub fn appearance(&self) -> Result<AppearanceView, CoreError> {
        let a = appearance::get(self.lock()?.conn())?;
        Ok(AppearanceView {
            theme: a.theme,
            brightness: match a.brightness {
                appearance::Brightness::System => ThemeBrightness::System,
                appearance::Brightness::Light => ThemeBrightness::Light,
                appearance::Brightness::Dark => ThemeBrightness::Dark,
            },
            glass: a.glass,
        })
    }

    pub fn set_appearance(&self, appearance: AppearanceView) -> Result<(), CoreError> {
        appearance::set(
            self.lock()?.conn(),
            &appearance::Appearance {
                theme: appearance.theme,
                brightness: match appearance.brightness {
                    ThemeBrightness::System => appearance::Brightness::System,
                    ThemeBrightness::Light => appearance::Brightness::Light,
                    ThemeBrightness::Dark => appearance::Brightness::Dark,
                },
                glass: appearance.glass,
            },
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    fn dir() -> (tempfile::TempDir, String) {
        let tmp = tempfile::tempdir().unwrap();
        let path = tmp.path().join("data").to_string_lossy().into_owned();
        (tmp, path)
    }

    #[test]
    fn the_vault_path_creates_and_reopens() {
        let (_tmp, dir) = dir();
        assert_eq!(store_state(dir.clone()), StoreState::Missing);
        let key = new_store_key().unwrap();
        let store = ChirpStore::open_with_key(dir.clone(), key.clone()).unwrap();
        let profile = store.create_profile("Lutino".into()).unwrap();
        drop(store);
        assert_eq!(store_state(dir.clone()), StoreState::KeyInVault);
        let store = ChirpStore::open_with_key(dir.clone(), key).unwrap();
        assert_eq!(store.profile().unwrap(), Some(profile));
        let other = new_store_key().unwrap();
        assert!(matches!(
            ChirpStore::open_with_key(dir, other),
            Err(CoreError::WrongKey)
        ));
    }

    #[test]
    fn changing_the_network_restarts_the_node() {
        let (_tmp, dir) = dir();
        let store = ChirpStore::open_with_key(dir, vec![9; 32]).unwrap();
        store.create_profile("Lutino".into()).unwrap();
        assert_eq!(
            store.network_status().unwrap(),
            NetworkStatus {
                running: false,
                internet: false,
                relays: 0,
                relay_connected: false,
            }
        );
        store.start_network().unwrap();
        let mut events = store.events.subscribe();
        let saved = store
            .set_network_settings(NetworkSettings {
                internet: true,
                // No loopback: o teste não procura nenhum servidor de verdade.
                relays: vec![" http://127.0.0.1:9 ".into()],
            })
            .unwrap();
        assert_eq!(saved.relays, ["http://127.0.0.1:9/"]);
        let status = store.network_status().unwrap();
        assert!(status.running && status.internet);
        assert_eq!(status.relays, 1);
        // A UI relê tudo, e o canal continua o mesmo depois de religar.
        assert_eq!(events.try_recv(), Ok(NodeEvent::ContactChanged(0)));

        // Um retransmissor ruim não muda nada.
        assert_eq!(
            store.set_network_settings(NetworkSettings {
                internet: true,
                relays: vec!["ftp://x".into()],
            }),
            Err(CoreError::InvalidRelay)
        );
        assert_eq!(store.network_settings().unwrap(), saved);
        // Religar não fecha o fluxo; desligar de propósito fecha (e o app pode sair).
        assert!(events.try_recv().is_err());
        store.stop_network().unwrap();
        assert_eq!(events.try_recv(), Ok(NodeEvent::Closed));
    }

    /// O caminho do teste de integração, pela API, com prazo: um travamento entre as
    /// travas do banco e do nó apareceria aqui.
    #[test]
    fn two_stores_talk_through_the_api() {
        let (tmp, _) = dir();
        let done = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(false));
        let flag = done.clone();
        let base = tmp.path().to_path_buf();
        let worker = std::thread::spawn(move || {
            let open = |name: &str| {
                let store = ChirpStore::open_with_key(
                    base.join(name).to_string_lossy().into(),
                    vec![3; 32],
                )
                .unwrap();
                store.create_profile(name.into()).unwrap();
                store.start_network().unwrap();
                store
            };
            let (alice, bob) = (open("Alice"), open("Bob"));
            let link = alice.create_invite(false).unwrap();
            let at_bob = bob.add_contact(link, false).unwrap();
            let mut at_alice = None;
            for _ in 0..100 {
                if let Some(c) = alice.conversations().unwrap().first() {
                    at_alice = Some(c.contact.id);
                    break;
                }
                std::thread::sleep(Duration::from_millis(100));
            }
            let at_alice = at_alice.expect("Alice sees Bob");
            bob.send_text(at_bob.id, "oi".into(), None).unwrap();
            for _ in 0..100 {
                let got = alice.messages(at_alice, None, 10).unwrap();
                let _ = bob.contacts().unwrap();
                if !got.is_empty() {
                    flag.store(true, std::sync::atomic::Ordering::SeqCst);
                    return;
                }
                std::thread::sleep(Duration::from_millis(100));
            }
        });
        for _ in 0..300 {
            if done.load(std::sync::atomic::Ordering::SeqCst) || worker.is_finished() {
                break;
            }
            std::thread::sleep(Duration::from_millis(100));
        }
        assert!(
            done.load(std::sync::atomic::Ordering::SeqCst),
            "stuck or failed"
        );
    }

    #[test]
    fn a_short_key_is_refused() {
        let (_tmp, dir) = dir();
        assert!(matches!(
            ChirpStore::open_with_key(dir, vec![1; 16]),
            Err(CoreError::BadKey)
        ));
    }

    #[test]
    fn the_passphrase_path_creates_and_reopens() {
        let (_tmp, dir) = dir();
        let store =
            ChirpStore::create_with_passphrase(dir.clone(), "calopsita lutino".into()).unwrap();
        store.create_profile("Lutino".into()).unwrap();
        drop(store);
        assert_eq!(store_state(dir.clone()), StoreState::Passphrase);
        assert!(matches!(
            ChirpStore::open_with_passphrase(dir.clone(), "outra senha".into()),
            Err(CoreError::WrongKey)
        ));
        let store =
            ChirpStore::open_with_passphrase(dir.clone(), "calopsita lutino".into()).unwrap();
        assert_eq!(store.profile().unwrap().unwrap().display_name, "Lutino");
        assert!(matches!(
            ChirpStore::create_with_passphrase(dir, "calopsita lutino".into()),
            Err(CoreError::AlreadyExists)
        ));
    }

    #[test]
    fn a_weak_passphrase_leaves_nothing_behind() {
        let (_tmp, dir) = dir();
        std::fs::create_dir_all(&dir).unwrap();
        assert!(matches!(
            ChirpStore::create_with_passphrase(dir.clone(), "curta".into()),
            Err(CoreError::WeakPassphrase)
        ));
        assert_eq!(store_state(dir), StoreState::Missing);
    }

    #[test]
    fn wiping_removes_everything() {
        let (_tmp, dir) = dir();
        ChirpStore::create_with_passphrase(dir.clone(), "calopsita lutino".into())
            .unwrap()
            .create_profile("Lutino".into())
            .unwrap();
        wipe_store(dir.clone()).unwrap();
        assert_eq!(store_state(dir.clone()), StoreState::Missing);
        assert_eq!(std::fs::read_dir(&dir).unwrap().count(), 0);
        wipe_store(dir).unwrap();
    }
}

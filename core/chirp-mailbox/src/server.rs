//! O servidor da caixa postal: um endpoint do iroh no ALPN `chirp-mailbox/1`.
//!
//! Sem descoberta por servidor (o preset `Minimal`): os donos e os contatos chegam
//! pelos endereços do código de ligação, que o dono repassa aos contatos pela sessão.
//! Com um retransmissor escolhido, a caixa fica alcançável por ele também.

use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::Duration;

use iroh::endpoint::{presets, Connection, RelayMode};
use iroh::{Endpoint, RelayMap, RelayUrl, SecretKey};

use crate::proto::{self, Body, ProtoError};
use crate::store::{Boxes, Limits};

/// Uma conexão sem nada por esse tempo é fechada.
const IDLE: Duration = Duration::from_secs(30);
/// Quantos frames numa conexão.
const MAX_FRAMES: usize = 4096;
/// Quantas conexões ao mesmo tempo; as de além esperam.
const MAX_INCOMING: usize = 64;
/// De quanto em quanto tempo o que venceu sai.
const SWEEP: Duration = Duration::from_secs(60 * 60);

pub struct Config {
    pub dir: PathBuf,
    pub port: u16,
    /// Endereços a mais para o código de ligação (o IP público de um encaminhamento
    /// de porta, por exemplo).
    pub public: Vec<SocketAddr>,
    pub relay: Option<RelayUrl>,
    pub limits: Limits,
}

pub fn now() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

/// A chave do nó, criada na primeira vez (só quem roda o processo lê).
pub fn secret_key(dir: &Path) -> std::io::Result<SecretKey> {
    let path = dir.join("key");
    if let Ok(bytes) = std::fs::read(&path) {
        if let Ok(bytes) = <[u8; 32]>::try_from(bytes.as_slice()) {
            return Ok(SecretKey::from_bytes(&bytes));
        }
    }
    std::fs::create_dir_all(dir)?;
    let mut bytes = [0u8; 32];
    getrandom::fill(&mut bytes).map_err(std::io::Error::other)?;
    let mut options = std::fs::OpenOptions::new();
    options.write(true).create_new(true);
    #[cfg(unix)]
    std::os::unix::fs::OpenOptionsExt::mode(&mut options, 0o600);
    std::io::Write::write_all(&mut options.open(&path)?, &bytes)?;
    Ok(SecretKey::from_bytes(&bytes))
}

pub struct Server {
    pub endpoint: Endpoint,
    boxes: Arc<Mutex<Boxes>>,
}

impl Server {
    pub async fn start(config: Config) -> std::io::Result<Arc<Server>> {
        let key = secret_key(&config.dir)?;
        let boxes = Boxes::open(&config.dir, config.limits)?;
        let relay_mode = match &config.relay {
            Some(url) => RelayMode::Custom([url.clone()].into_iter().collect::<RelayMap>()),
            None => RelayMode::Disabled,
        };
        let mut builder = Endpoint::builder(presets::Minimal)
            .relay_mode(relay_mode)
            .clear_address_lookup()
            .secret_key(key)
            .alpns(vec![proto::ALPN.to_vec()]);
        if config.port != 0 {
            builder = builder
                .clear_ip_transports()
                .bind_addr(SocketAddr::from(([0, 0, 0, 0], config.port)))
                .and_then(|b| b.bind_addr(SocketAddr::from(([0u16; 8], config.port))))
                .map_err(std::io::Error::other)?;
        }
        let endpoint = builder.bind().await.map_err(std::io::Error::other)?;
        let server = Arc::new(Server {
            endpoint,
            boxes: Arc::new(Mutex::new(boxes)),
        });
        tokio::spawn(server.clone().accept_loop());
        tokio::spawn(server.clone().sweep_loop());
        Ok(server)
    }

    /// Os endereços para o código de ligação: os das interfaces (sem loopback nem
    /// link-local), mais os públicos dados na linha de comando.
    pub fn addrs(&self, public: &[SocketAddr]) -> Vec<SocketAddr> {
        let mut addrs: Vec<SocketAddr> = public.to_vec();
        addrs.extend(
            self.endpoint
                .addr()
                .ip_addrs()
                .copied()
                .filter(|a| match a.ip() {
                    std::net::IpAddr::V4(ip) => !ip.is_loopback() && !ip.is_link_local(),
                    std::net::IpAddr::V6(ip) => {
                        !ip.is_loopback() && (ip.segments()[0] & 0xffc0) != 0xfe80
                    }
                }),
        );
        addrs.dedup();
        addrs.truncate(crate::link::MAX_ADDRS);
        addrs
    }

    pub fn relay(&self) -> Option<String> {
        self.endpoint
            .addr()
            .relay_urls()
            .next()
            .map(|u| u.to_string())
    }

    pub fn usage(&self) -> Vec<(usize, u64)> {
        self.boxes.lock().map(|b| b.usage()).unwrap_or_default()
    }

    async fn sweep_loop(self: Arc<Self>) {
        let mut tick = tokio::time::interval(SWEEP);
        loop {
            tick.tick().await;
            if self.endpoint.is_closed() {
                return;
            }
            if let Ok(mut boxes) = self.boxes.lock() {
                let _ = boxes.sweep(now());
            }
        }
    }

    async fn accept_loop(self: Arc<Self>) {
        let slots = Arc::new(tokio::sync::Semaphore::new(MAX_INCOMING));
        while let Some(incoming) = self.endpoint.accept().await {
            let Ok(slot) = slots.clone().acquire_owned().await else {
                return;
            };
            let server = self.clone();
            tokio::spawn(async move {
                let _slot = slot;
                let Ok(conn) = incoming.await else { return };
                let _ = server.serve(&conn).await;
                conn.close(0u32.into(), b"");
            });
        }
    }

    fn with<T>(
        &self,
        work: impl FnOnce(&mut Boxes) -> std::io::Result<T>,
    ) -> Result<T, ProtoError> {
        let mut boxes = self.boxes.lock().map_err(|_| ProtoError::Closed)?;
        work(&mut boxes).map_err(|_| ProtoError::Closed)
    }

    async fn serve(&self, conn: &Connection) -> Result<(), ProtoError> {
        let remote = *conn.remote_id().as_bytes();
        let (mut send, mut recv) = tokio::time::timeout(IDLE, conn.accept_bi())
            .await
            .map_err(|_| ProtoError::Closed)?
            .map_err(|_| ProtoError::Closed)?;
        for _ in 0..MAX_FRAMES {
            let body = match tokio::time::timeout(IDLE, proto::read(&mut recv)).await {
                Ok(Ok(body)) => body,
                // O outro lado terminou (ou sumiu, ou mandou lixo).
                _ => break,
            };
            let owner = self.with(|b| Ok(b.is_owner(&remote)))?;
            let ok = match body {
                Body::Pair(pair) => self.with(|b| b.pair(&pair.token, remote, now()))?,
                Body::Deposit(deposit) => {
                    self.with(|b| b.deposit(&deposit.drop, &deposit.envelope, now()))?
                }
                Body::SetDrops(drops) if owner => {
                    self.with(|b| b.set_drops(&remote, &drops.hashes))?
                }
                Body::Fetch(fetch) if owner => {
                    let items = self.with(|b| b.fetch(&remote, fetch.after))?;
                    for item in items {
                        proto::write(&mut send, Body::Item(item)).await?;
                    }
                    true
                }
                Body::Remove(remove) if owner => {
                    self.with(|b| b.remove(&remote, remove.up_to))?;
                    true
                }
                Body::Unpair(_) if owner => {
                    self.with(|b| b.unpair(&remote))?;
                    true
                }
                Body::Publish(publish) if owner => {
                    self.with(|b| b.publish(&remote, &publish, now()))?
                }
                Body::GetBundle(get) => match self.with(|b| b.bundle(&get.lookup, now()))? {
                    Some(bundle) => {
                        proto::write(&mut send, Body::Bundle(proto::Bundle { bundle })).await?;
                        continue;
                    }
                    None => false,
                },
                _ => false,
            };
            let reply = if ok {
                Body::Done(proto::Done {})
            } else {
                Body::Refused(proto::Refused {})
            };
            proto::write(&mut send, reply).await?;
        }
        let _ = send.finish();
        let _ = tokio::time::timeout(Duration::from_secs(2), conn.closed()).await;
        Ok(())
    }

    pub async fn close(&self) {
        self.endpoint.close().await;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::store::create_pairing;
    use iroh::EndpointAddr;

    async fn client() -> Endpoint {
        Endpoint::builder(presets::Minimal)
            .relay_mode(RelayMode::Disabled)
            .clear_address_lookup()
            .bind()
            .await
            .unwrap()
    }

    async fn talk(client: &Endpoint, server: &Server, frames: Vec<Body>) -> Vec<Body> {
        let addr = EndpointAddr::from_parts(
            server.endpoint.id(),
            server
                .endpoint
                .addr()
                .ip_addrs()
                .map(|a| iroh::TransportAddr::Ip(*a)),
        );
        let conn = client.connect(addr, proto::ALPN).await.unwrap();
        let (mut send, mut recv) = conn.open_bi().await.unwrap();
        let mut out = Vec::new();
        for frame in frames {
            let fetch = matches!(frame, Body::Fetch(_));
            proto::write(&mut send, frame).await.unwrap();
            loop {
                let reply = proto::read(&mut recv).await.unwrap();
                let end = !matches!(reply, Body::Item(_)) || !fetch;
                out.push(reply);
                if end {
                    break;
                }
            }
        }
        let _ = send.finish();
        conn.close(0u32.into(), b"");
        out
    }

    fn done() -> Body {
        Body::Done(proto::Done {})
    }

    fn refused() -> Body {
        Body::Refused(proto::Refused {})
    }

    #[tokio::test]
    async fn an_owner_pairs_a_contact_deposits_and_the_owner_fetches() {
        let dir = tempfile::tempdir().unwrap();
        let server = Server::start(Config {
            dir: dir.path().to_path_buf(),
            port: 0,
            public: vec![],
            relay: None,
            limits: Limits::default(),
        })
        .await
        .unwrap();
        create_pairing(dir.path(), [5; 32], now()).unwrap();
        let (owner, contact) = (client().await, client().await);

        // Antes de ligar, o dono não é dono.
        let drops = Body::SetDrops(proto::SetDrops {
            hashes: vec![proto::hash(&[7; 32]).to_vec()],
        });
        assert_eq!(
            talk(&owner, &server, vec![drops.clone()]).await,
            vec![refused()]
        );
        let replies = talk(
            &owner,
            &server,
            vec![Body::Pair(proto::Pair { token: vec![5; 32] }), drops],
        )
        .await;
        assert_eq!(replies, vec![done(), done()]);

        let deposit = |drop: u8, n: u8| {
            Body::Deposit(proto::Deposit {
                drop: vec![drop; 32],
                envelope: vec![n; 100],
            })
        };
        let replies = talk(
            &contact,
            &server,
            vec![deposit(7, 1), deposit(7, 2), deposit(8, 3)],
        )
        .await;
        assert_eq!(replies, vec![done(), done(), refused()]);
        // O contato não lê a caixa.
        let fetch = Body::Fetch(proto::Fetch { after: 0 });
        assert_eq!(
            talk(&contact, &server, vec![fetch.clone()]).await,
            vec![refused()]
        );

        let replies = talk(&owner, &server, vec![fetch.clone()]).await;
        assert_eq!(replies.len(), 3);
        let Body::Item(last) = &replies[1] else {
            panic!("um item");
        };
        assert_eq!(last.envelope, vec![2; 100]);
        let replies = talk(
            &owner,
            &server,
            vec![Body::Remove(proto::Remove { up_to: last.seq }), fetch],
        )
        .await;
        assert_eq!(replies, vec![done(), done()]);
        server.close().await;
    }
}

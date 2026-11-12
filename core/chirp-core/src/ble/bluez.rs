//! O rádio no Linux: o BlueZ pelo D-Bus (anunciar e procurar) e os soquetes L2CAP do
//! kernel (o canal). Precisa do `bluetoothd` rodando e do adaptador ligado; sem eles,
//! o nó segue sem Bluetooth.

use std::collections::{BTreeMap, BTreeSet, HashSet};
use std::str::FromStr;

use async_trait::async_trait;
use bluer::adv::{Advertisement, AdvertisementHandle, Type};
use bluer::l2cap::{SocketAddr, StreamListener};
use bluer::{
    Adapter, AdapterEvent, Address, AddressType, DiscoveryFilter, DiscoveryTransport, Uuid,
};
use futures::StreamExt;
use tokio::sync::{mpsc, Mutex};

use super::{Link, Radio, Sighting, SERVICE_UUID};
use crate::error::{CoreError, CoreResult};

pub struct BlueZ {
    // A sessão do D-Bus precisa ficar viva enquanto o adaptador for usado.
    _session: bluer::Session,
    adapter: Adapter,
    advert: Mutex<Option<AdvertisementHandle>>,
}

fn uuid() -> Uuid {
    Uuid::from_u128(SERVICE_UUID)
}

impl BlueZ {
    /// O adaptador padrão, se houver um ligado.
    pub async fn open() -> CoreResult<Self> {
        let session = bluer::Session::new()
            .await
            .map_err(|_| CoreError::Unreachable)?;
        let adapter = session
            .default_adapter()
            .await
            .map_err(|_| CoreError::Unreachable)?;
        if !adapter.is_powered().await.unwrap_or(false) {
            return Err(CoreError::Unreachable);
        }
        Ok(Self {
            _session: session,
            adapter,
            advert: Mutex::new(None),
        })
    }
}

/// O aparelho visto, como o rádio entende: `AA:BB:CC:DD:EE:FF/random`.
fn peer_name(addr: Address, kind: AddressType) -> String {
    let kind = match kind {
        AddressType::LePublic => "public",
        _ => "random",
    };
    format!("{addr}/{kind}")
}

fn parse_peer(peer: &str) -> Option<(Address, AddressType)> {
    let (addr, kind) = peer.split_once('/')?;
    let kind = match kind {
        "public" => AddressType::LePublic,
        "random" => AddressType::LeRandom,
        _ => return None,
    };
    Some((Address::from_str(addr).ok()?, kind))
}

#[async_trait]
impl Radio for BlueZ {
    async fn listen(&self) -> CoreResult<(u16, mpsc::Receiver<Link>)> {
        let listener = StreamListener::bind(SocketAddr::any_le())
            .await
            .map_err(|_| CoreError::Unreachable)?;
        let psm = listener
            .as_ref()
            .local_addr()
            .map_err(|_| CoreError::Unreachable)?
            .psm;
        let (tx, rx) = mpsc::channel(8);
        tokio::spawn(async move {
            loop {
                let Ok((stream, _)) = listener.accept().await else {
                    return;
                };
                if tx.send(Box::new(stream) as Link).await.is_err() {
                    return;
                }
            }
        });
        Ok((psm, rx))
    }

    async fn advertise(&self, data: Vec<u8>) -> CoreResult<()> {
        let mut current = self.advert.lock().await;
        // O de antes sai primeiro: o adaptador tem poucos lugares de anúncio.
        current.take();
        let advert = Advertisement {
            advertisement_type: Type::Peripheral,
            service_data: BTreeMap::from([(uuid(), data)]),
            service_uuids: BTreeSet::new(),
            discoverable: Some(false),
            local_name: None,
            ..Default::default()
        };
        let handle = self
            .adapter
            .advertise(advert)
            .await
            .map_err(|_| CoreError::Unreachable)?;
        *current = Some(handle);
        Ok(())
    }

    async fn scan(&self) -> CoreResult<mpsc::Receiver<Sighting>> {
        self.adapter
            .set_discovery_filter(DiscoveryFilter {
                uuids: HashSet::from([uuid()]),
                transport: DiscoveryTransport::Le,
                duplicate_data: true,
                ..Default::default()
            })
            .await
            .map_err(|_| CoreError::Unreachable)?;
        let events = self
            .adapter
            .discover_devices_with_changes()
            .await
            .map_err(|_| CoreError::Unreachable)?;
        let adapter = self.adapter.clone();
        let (tx, rx) = mpsc::channel(64);
        tokio::spawn(async move {
            futures::pin_mut!(events);
            while let Some(event) = events.next().await {
                let AdapterEvent::DeviceAdded(addr) = event else {
                    continue;
                };
                let Ok(device) = adapter.device(addr) else {
                    continue;
                };
                let Ok(Some(mut data)) = device.service_data().await else {
                    continue;
                };
                let Some(data) = data.remove(&uuid()) else {
                    continue;
                };
                let kind = device.address_type().await.unwrap_or(AddressType::LeRandom);
                let sighting = Sighting {
                    peer: peer_name(addr, kind),
                    data,
                };
                if tx.send(sighting).await.is_err() {
                    return;
                }
            }
        });
        Ok(rx)
    }

    async fn connect(&self, peer: &str, psm: u16) -> CoreResult<Link> {
        let (addr, kind) = parse_peer(peer).ok_or(CoreError::Unreachable)?;
        let stream = bluer::l2cap::Stream::connect(SocketAddr::new(addr, kind, psm))
            .await
            .map_err(|_| CoreError::Unreachable)?;
        Ok(Box::new(stream))
    }

    async fn stop(&self) {
        self.advert.lock().await.take();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// No adaptador de verdade (fora do CI, que não tem Bluetooth):
    /// `cargo test -p chirp_core -- --ignored bluez`.
    #[tokio::test]
    #[ignore]
    async fn bluez_listens_advertises_and_scans() {
        let radio = BlueZ::open().await.expect("a powered adapter");
        let (psm, _incoming) = radio.listen().await.expect("an L2CAP port");
        assert!(psm >= 0x80, "a dynamic LE port");
        radio
            .advertise(crate::ble::advert(&[1; 8], psm))
            .await
            .expect("advertising");
        let mut found = radio.scan().await.expect("scanning");
        let _ = tokio::time::timeout(std::time::Duration::from_secs(5), found.recv()).await;
        radio.stop().await;
    }

    #[test]
    fn a_peer_name_goes_and_comes_back() {
        let addr = Address::new([1, 2, 3, 4, 5, 6]);
        for kind in [AddressType::LePublic, AddressType::LeRandom] {
            assert_eq!(parse_peer(&peer_name(addr, kind)), Some((addr, kind)));
        }
        assert_eq!(parse_peer("01:02:03:04:05:06"), None);
        assert_eq!(parse_peer("nope/random"), None);
        assert_eq!(parse_peer("01:02:03:04:05:06/bredr"), None);
    }
}

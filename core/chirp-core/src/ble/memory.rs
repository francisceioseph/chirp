//! Um rádio na memória, para os testes: os aparelhos no mesmo [`Air`] se veem e se
//! conectam por um `tokio::io::duplex`. Desligar um (`off`) faz ele sumir do ar.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use async_trait::async_trait;
use tokio::sync::mpsc;

use super::{Link, Radio, Sighting};
use crate::error::{CoreError, CoreResult};

#[derive(Default)]
struct Device {
    advert: Option<Vec<u8>>,
    psm: u16,
    incoming: Option<mpsc::Sender<Link>>,
    scanners: Vec<mpsc::Sender<Sighting>>,
    on: bool,
}

/// O ar em volta: quem está nele se vê.
#[derive(Clone, Default)]
pub struct Air(Arc<Mutex<HashMap<String, Device>>>);

impl Air {
    pub fn radio(&self, name: &str) -> Arc<MemoryRadio> {
        self.0.lock().unwrap().insert(
            name.to_owned(),
            Device {
                on: true,
                ..Default::default()
            },
        );
        Arc::new(MemoryRadio {
            air: self.clone(),
            name: name.to_owned(),
        })
    }

    /// Liga ou desliga o rádio de um aparelho.
    pub fn set_on(&self, name: &str, on: bool) {
        let sightings = {
            let mut air = self.0.lock().unwrap();
            if let Some(device) = air.get_mut(name) {
                device.on = on;
            }
            if on {
                Self::sightings_of(&air, name)
            } else {
                vec![]
            }
        };
        for (to, sighting) in sightings {
            let _ = to.try_send(sighting);
        }
    }

    /// Quem deve ver o anúncio de `name` agora.
    fn sightings_of(
        air: &HashMap<String, Device>,
        name: &str,
    ) -> Vec<(mpsc::Sender<Sighting>, Sighting)> {
        let Some(device) = air.get(name).filter(|d| d.on) else {
            return vec![];
        };
        let Some(data) = device.advert.clone() else {
            return vec![];
        };
        air.iter()
            .filter(|(other, d)| *other != name && d.on)
            .flat_map(|(_, d)| d.scanners.iter().cloned())
            .map(|to| {
                (
                    to,
                    Sighting {
                        peer: name.to_owned(),
                        data: data.clone(),
                    },
                )
            })
            .collect()
    }
}

pub struct MemoryRadio {
    air: Air,
    name: String,
}

#[async_trait]
impl Radio for MemoryRadio {
    async fn listen(&self) -> CoreResult<(u16, mpsc::Receiver<Link>)> {
        let (tx, rx) = mpsc::channel(8);
        let mut air = self.air.0.lock().unwrap();
        let device = air.get_mut(&self.name).ok_or(CoreError::Unreachable)?;
        device.psm = 0x0081;
        device.incoming = Some(tx);
        Ok((device.psm, rx))
    }

    async fn advertise(&self, data: Vec<u8>) -> CoreResult<()> {
        let sightings = {
            let mut air = self.air.0.lock().unwrap();
            air.get_mut(&self.name)
                .ok_or(CoreError::Unreachable)?
                .advert = Some(data);
            Air::sightings_of(&air, &self.name)
        };
        for (to, sighting) in sightings {
            let _ = to.try_send(sighting);
        }
        Ok(())
    }

    async fn scan(&self) -> CoreResult<mpsc::Receiver<Sighting>> {
        let (tx, rx) = mpsc::channel(64);
        let mut air = self.air.0.lock().unwrap();
        air.get_mut(&self.name)
            .ok_or(CoreError::Unreachable)?
            .scanners
            .push(tx.clone());
        // Quem já anunciava aparece logo.
        for (name, device) in air.iter() {
            if *name != self.name && device.on {
                if let Some(data) = device.advert.clone() {
                    let _ = tx.try_send(Sighting {
                        peer: name.clone(),
                        data,
                    });
                }
            }
        }
        Ok(rx)
    }

    async fn connect(&self, peer: &str, psm: u16) -> CoreResult<Link> {
        let incoming = {
            let air = self.air.0.lock().unwrap();
            let me_on = air.get(&self.name).is_some_and(|d| d.on);
            match air.get(peer) {
                Some(d) if d.on && me_on && d.psm == psm => d.incoming.clone(),
                _ => None,
            }
        }
        .ok_or(CoreError::Unreachable)?;
        let (mine, theirs) = tokio::io::duplex(16 * 1024);
        incoming
            .send(Box::new(theirs))
            .await
            .map_err(|_| CoreError::Unreachable)?;
        Ok(Box::new(mine))
    }

    async fn stop(&self) {
        if let Some(device) = self.air.0.lock().unwrap().get_mut(&self.name) {
            device.advert = None;
        }
    }
}

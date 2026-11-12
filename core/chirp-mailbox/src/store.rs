//! Onde a caixa guarda as coisas: arquivos numa pasta, sem banco.
//!
//! ```text
//! <pasta>/key                     a chave do nó (32 bytes, só o dono do processo lê)
//! <pasta>/addrs                   os endereços de agora, para o `pair` montar o código
//! <pasta>/pairing/<hash>          um código de ligação vivo: o SHA-256 dele no nome e
//!                                 o vencimento (segundos desde 1970) dentro
//! <pasta>/owners/<nó>/drops       o SHA-256 das fichas, 32 bytes cada
//! <pasta>/owners/<nó>/items/<seq> ficha (32) || guardado em (u64) || envelope
//! ```
//!
//! O que está aqui já chega cifrado para o dono, e as fichas ficam só como hash. A
//! caixa sabe quantos envelopes cada ficha deixou, quando e de que IP, e mais nada.

use std::collections::{BTreeMap, HashMap, HashSet};
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use crate::proto::{self, Item};

/// O que a caixa aceita guardar.
#[derive(Debug, Clone, Copy)]
pub struct Limits {
    /// Itens por dono.
    pub items: usize,
    /// Bytes por dono.
    pub bytes: u64,
    /// Itens por ficha (um contato não enche a caixa sozinho).
    pub per_drop: usize,
    /// Quanto tempo um item fica, em segundos.
    pub keep_secs: u64,
}

impl Default for Limits {
    fn default() -> Self {
        Self {
            items: 20_000,
            bytes: 256 * 1024 * 1024,
            per_drop: 2_000,
            keep_secs: 30 * 24 * 60 * 60,
        }
    }
}

/// O código de ligação vale por um dia.
pub const PAIRING_SECS: u64 = 24 * 60 * 60;

type Hash = [u8; 32];

struct Meta {
    drop: Hash,
    len: u64,
    stored_at: u64,
}

struct OwnerBox {
    dir: PathBuf,
    drops: HashSet<Hash>,
    next_seq: u64,
    items: BTreeMap<u64, Meta>,
}

impl OwnerBox {
    fn bytes(&self) -> u64 {
        self.items.values().map(|m| m.len).sum()
    }

    fn per_drop(&self, drop: &Hash) -> usize {
        self.items.values().filter(|m| &m.drop == drop).count()
    }
}

pub struct Boxes {
    dir: PathBuf,
    limits: Limits,
    owners: HashMap<Hash, OwnerBox>,
    /// De que dono é cada ficha.
    drops: HashMap<Hash, Hash>,
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

fn unhex(text: &str) -> Option<Hash> {
    if text.len() != 64 {
        return None;
    }
    let mut out = [0u8; 32];
    for (i, byte) in out.iter_mut().enumerate() {
        *byte = u8::from_str_radix(text.get(i * 2..i * 2 + 2)?, 16).ok()?;
    }
    Some(out)
}

/// Grava num arquivo ao lado e troca de nome: um arquivo pela metade nunca aparece.
fn write_atomic(path: &Path, bytes: &[u8]) -> std::io::Result<()> {
    let tmp = path.with_extension("tmp");
    let mut file = fs::File::create(&tmp)?;
    file.write_all(bytes)?;
    file.sync_all()?;
    fs::rename(&tmp, path)
}

/// Cria um código de ligação novo (o subcomando `pair`). Devolve o código.
pub fn create_pairing(dir: &Path, token: [u8; 32], now: u64) -> std::io::Result<[u8; 32]> {
    let pairing = dir.join("pairing");
    fs::create_dir_all(&pairing)?;
    write_atomic(
        &pairing.join(hex(&proto::hash(&token))),
        (now + PAIRING_SECS).to_string().as_bytes(),
    )?;
    Ok(token)
}

impl Boxes {
    /// Abre a pasta, lendo o cabeçalho de cada item.
    pub fn open(dir: &Path, limits: Limits) -> std::io::Result<Self> {
        let owners_dir = dir.join("owners");
        fs::create_dir_all(&owners_dir)?;
        let mut boxes = Self {
            dir: dir.to_path_buf(),
            limits,
            owners: HashMap::new(),
            drops: HashMap::new(),
        };
        for entry in fs::read_dir(&owners_dir)? {
            let entry = entry?;
            let Some(owner) = entry.file_name().to_str().and_then(unhex) else {
                continue;
            };
            let owner_box = Self::load(&entry.path())?;
            for drop in &owner_box.drops {
                boxes.drops.insert(*drop, owner);
            }
            boxes.owners.insert(owner, owner_box);
        }
        Ok(boxes)
    }

    fn load(dir: &Path) -> std::io::Result<OwnerBox> {
        let drops = fs::read(dir.join("drops"))
            .unwrap_or_default()
            .as_chunks::<32>()
            .0
            .iter()
            .copied()
            .collect();
        let items_dir = dir.join("items");
        fs::create_dir_all(&items_dir)?;
        let mut items = BTreeMap::new();
        for entry in fs::read_dir(&items_dir)? {
            let entry = entry?;
            let Some(seq) = entry
                .file_name()
                .to_str()
                .and_then(|n| n.parse::<u64>().ok())
            else {
                // Um `.tmp` de uma gravação que caiu no meio.
                let _ = fs::remove_file(entry.path());
                continue;
            };
            let bytes = fs::read(entry.path())?;
            if bytes.len() < 40 {
                let _ = fs::remove_file(entry.path());
                continue;
            }
            let drop: Hash = bytes[..32].try_into().unwrap_or_default();
            let stored_at = u64::from_be_bytes(bytes[32..40].try_into().unwrap_or_default());
            items.insert(
                seq,
                Meta {
                    drop,
                    len: (bytes.len() - 40) as u64,
                    stored_at,
                },
            );
        }
        let next_seq = items.keys().next_back().map_or(1, |s| s + 1);
        Ok(OwnerBox {
            dir: dir.to_path_buf(),
            drops,
            next_seq,
            items,
        })
    }

    pub fn is_owner(&self, node: &Hash) -> bool {
        self.owners.contains_key(node)
    }

    /// Gasta um código de ligação vivo e faz do nó um dono. Um dono que liga de novo
    /// continua com o que tinha.
    pub fn pair(&mut self, token: &[u8], owner: Hash, now: u64) -> std::io::Result<bool> {
        if token.len() != 32 {
            return Ok(false);
        }
        let path = self.dir.join("pairing").join(hex(&proto::hash(token)));
        let Ok(expires) = fs::read_to_string(&path) else {
            return Ok(false);
        };
        fs::remove_file(&path)?;
        if expires.trim().parse::<u64>().map_or(true, |e| e < now) {
            return Ok(false);
        }
        if !self.owners.contains_key(&owner) {
            let dir = self.dir.join("owners").join(hex(&owner));
            fs::create_dir_all(dir.join("items"))?;
            self.owners.insert(owner, Self::load(&dir)?);
        }
        Ok(true)
    }

    /// Troca as fichas do dono. Uma que já é de outro dono fica de fora.
    pub fn set_drops(&mut self, owner: &Hash, hashes: &[Vec<u8>]) -> std::io::Result<bool> {
        if hashes.len() > proto::MAX_DROPS {
            return Ok(false);
        }
        let Some(owner_box) = self.owners.get_mut(owner) else {
            return Ok(false);
        };
        let new: HashSet<Hash> = hashes
            .iter()
            .filter_map(|h| <Hash>::try_from(h.as_slice()).ok())
            .filter(|h| self.drops.get(h).is_none_or(|o| o == owner))
            .collect();
        for old in owner_box.drops.difference(&new) {
            self.drops.remove(old);
        }
        for drop in &new {
            self.drops.insert(*drop, *owner);
        }
        let bytes: Vec<u8> = new.iter().flatten().copied().collect();
        write_atomic(&owner_box.dir.join("drops"), &bytes)?;
        owner_box.drops = new;
        Ok(true)
    }

    /// Guarda um envelope para o dono da ficha, dentro dos limites.
    pub fn deposit(
        &mut self,
        drop_token: &[u8],
        envelope: &[u8],
        now: u64,
    ) -> std::io::Result<bool> {
        if drop_token.len() != 32 || envelope.is_empty() || envelope.len() > proto::MAX_ENVELOPE {
            return Ok(false);
        }
        let drop = proto::hash(drop_token);
        let Some(owner) = self.drops.get(&drop) else {
            return Ok(false);
        };
        let Some(owner_box) = self.owners.get_mut(owner) else {
            return Ok(false);
        };
        let limits = self.limits;
        if owner_box.items.len() >= limits.items
            || owner_box.bytes() + envelope.len() as u64 > limits.bytes
            || owner_box.per_drop(&drop) >= limits.per_drop
        {
            return Ok(false);
        }
        let seq = owner_box.next_seq;
        let mut bytes = Vec::with_capacity(40 + envelope.len());
        bytes.extend_from_slice(&drop);
        bytes.extend_from_slice(&now.to_be_bytes());
        bytes.extend_from_slice(envelope);
        write_atomic(
            &owner_box.dir.join("items").join(format!("{seq:020}")),
            &bytes,
        )?;
        owner_box.next_seq += 1;
        owner_box.items.insert(
            seq,
            Meta {
                drop,
                len: envelope.len() as u64,
                stored_at: now,
            },
        );
        Ok(true)
    }

    /// O que chegou depois de `after`, até `FETCH_BATCH` itens.
    pub fn fetch(&self, owner: &Hash, after: u64) -> std::io::Result<Vec<Item>> {
        let Some(owner_box) = self.owners.get(owner) else {
            return Ok(vec![]);
        };
        let mut out = Vec::new();
        for (seq, meta) in owner_box
            .items
            .range(after.saturating_add(1)..)
            .take(proto::FETCH_BATCH)
        {
            let bytes = fs::read(owner_box.dir.join("items").join(format!("{seq:020}")))?;
            out.push(Item {
                seq: *seq,
                drop: meta.drop.to_vec(),
                envelope: bytes.get(40..).unwrap_or_default().to_vec(),
                stored_at: meta.stored_at,
            });
        }
        Ok(out)
    }

    /// Apaga o que o dono já leu.
    pub fn remove(&mut self, owner: &Hash, up_to: u64) -> std::io::Result<()> {
        let Some(owner_box) = self.owners.get_mut(owner) else {
            return Ok(());
        };
        let gone: Vec<u64> = owner_box.items.range(..=up_to).map(|(s, _)| *s).collect();
        for seq in gone {
            owner_box.items.remove(&seq);
            let _ = fs::remove_file(owner_box.dir.join("items").join(format!("{seq:020}")));
        }
        Ok(())
    }

    /// Desliga o dono: as fichas e tudo o que estava guardado saem.
    pub fn unpair(&mut self, owner: &Hash) -> std::io::Result<()> {
        if let Some(owner_box) = self.owners.remove(owner) {
            for drop in &owner_box.drops {
                self.drops.remove(drop);
            }
            fs::remove_dir_all(&owner_box.dir)?;
        }
        Ok(())
    }

    /// Joga fora o que passou do prazo, e os códigos de ligação vencidos.
    pub fn sweep(&mut self, now: u64) -> std::io::Result<()> {
        let keep = self.limits.keep_secs;
        for owner_box in self.owners.values_mut() {
            let old: Vec<u64> = owner_box
                .items
                .iter()
                .filter(|(_, m)| m.stored_at.saturating_add(keep) < now)
                .map(|(s, _)| *s)
                .collect();
            for seq in old {
                owner_box.items.remove(&seq);
                let _ = fs::remove_file(owner_box.dir.join("items").join(format!("{seq:020}")));
            }
        }
        if let Ok(entries) = fs::read_dir(self.dir.join("pairing")) {
            for entry in entries.flatten() {
                let expired = fs::read_to_string(entry.path())
                    .ok()
                    .and_then(|e| e.trim().parse::<u64>().ok())
                    .is_none_or(|e| e < now);
                if expired {
                    let _ = fs::remove_file(entry.path());
                }
            }
        }
        Ok(())
    }

    /// Quantos itens e bytes cada dono tem, para o `status`.
    pub fn usage(&self) -> Vec<(usize, u64)> {
        self.owners
            .values()
            .map(|o| (o.items.len(), o.bytes()))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const OWNER: Hash = [1; 32];
    const OTHER: Hash = [2; 32];

    fn paired(dir: &Path, limits: Limits) -> Boxes {
        let mut boxes = Boxes::open(dir, limits).unwrap();
        create_pairing(dir, [5; 32], 100).unwrap();
        assert!(boxes.pair(&[5; 32], OWNER, 100).unwrap());
        boxes
            .set_drops(&OWNER, &[proto::hash(&[7; 32]).to_vec()])
            .unwrap();
        boxes
    }

    #[test]
    fn a_pairing_code_works_once_and_expires() {
        let dir = tempfile::tempdir().unwrap();
        let mut boxes = Boxes::open(dir.path(), Limits::default()).unwrap();
        create_pairing(dir.path(), [5; 32], 100).unwrap();
        assert!(!boxes.pair(&[6; 32], OWNER, 100).unwrap());
        assert!(boxes.pair(&[5; 32], OWNER, 100).unwrap());
        assert!(!boxes.pair(&[5; 32], OTHER, 100).unwrap(), "uso único");
        create_pairing(dir.path(), [8; 32], 100).unwrap();
        assert!(!boxes.pair(&[8; 32], OTHER, 100 + PAIRING_SECS + 1).unwrap());
        assert!(boxes.is_owner(&OWNER) && !boxes.is_owner(&OTHER));
    }

    #[test]
    fn deposits_need_a_drop_and_come_back_in_order() {
        let dir = tempfile::tempdir().unwrap();
        let mut boxes = paired(dir.path(), Limits::default());
        assert!(
            !boxes.deposit(&[9; 32], b"x", 200).unwrap(),
            "ficha desconhecida"
        );
        assert!(!boxes.deposit(&[7; 32], b"", 200).unwrap(), "vazio");
        assert!(!boxes
            .deposit(&[7; 32], &vec![0; proto::MAX_ENVELOPE + 1], 200)
            .unwrap());
        for n in 0..3u8 {
            assert!(boxes.deposit(&[7; 32], &[n; 10], 200).unwrap());
        }
        let items = boxes.fetch(&OWNER, 0).unwrap();
        assert_eq!(items.len(), 3);
        assert_eq!(items[2].envelope, vec![2; 10]);
        assert_eq!(items[0].drop, proto::hash(&[7; 32]).to_vec());
        assert!(boxes.fetch(&OTHER, 0).unwrap().is_empty());
        boxes.remove(&OWNER, items[1].seq).unwrap();
        assert_eq!(boxes.fetch(&OWNER, 0).unwrap().len(), 1);

        // Volta igual depois de reabrir, e a sequência continua.
        let mut again = Boxes::open(dir.path(), Limits::default()).unwrap();
        assert_eq!(again.fetch(&OWNER, 0).unwrap()[0].envelope, vec![2; 10]);
        assert!(again.deposit(&[7; 32], b"y", 300).unwrap());
        let seqs: Vec<u64> = again
            .fetch(&OWNER, 0)
            .unwrap()
            .iter()
            .map(|i| i.seq)
            .collect();
        assert_eq!(seqs, vec![3, 4]);
    }

    #[test]
    fn the_limits_hold() {
        let dir = tempfile::tempdir().unwrap();
        let limits = Limits {
            items: 10,
            bytes: 25,
            per_drop: 2,
            keep_secs: 50,
        };
        let mut boxes = paired(dir.path(), limits);
        assert!(boxes.deposit(&[7; 32], &[0; 10], 0).unwrap());
        assert!(boxes.deposit(&[7; 32], &[0; 10], 0).unwrap());
        assert!(!boxes.deposit(&[7; 32], &[0; 1], 0).unwrap(), "por ficha");
        boxes
            .set_drops(
                &OWNER,
                &[
                    proto::hash(&[7; 32]).to_vec(),
                    proto::hash(&[8; 32]).to_vec(),
                ],
            )
            .unwrap();
        assert!(!boxes.deposit(&[8; 32], &[0; 10], 0).unwrap(), "bytes");
        assert!(boxes.deposit(&[8; 32], &[0; 5], 0).unwrap());
        boxes.sweep(51).unwrap();
        assert!(boxes.fetch(&OWNER, 0).unwrap().is_empty(), "venceu");
    }

    #[test]
    fn a_drop_belongs_to_one_owner_and_unpair_clears_everything() {
        let dir = tempfile::tempdir().unwrap();
        let mut boxes = paired(dir.path(), Limits::default());
        create_pairing(dir.path(), [6; 32], 100).unwrap();
        assert!(boxes.pair(&[6; 32], OTHER, 100).unwrap());
        // O outro dono não toma a ficha do primeiro.
        boxes
            .set_drops(&OTHER, &[proto::hash(&[7; 32]).to_vec()])
            .unwrap();
        assert!(boxes.deposit(&[7; 32], b"x", 100).unwrap());
        assert_eq!(boxes.fetch(&OWNER, 0).unwrap().len(), 1);
        assert!(boxes.fetch(&OTHER, 0).unwrap().is_empty());
        boxes.unpair(&OWNER).unwrap();
        assert!(!boxes.is_owner(&OWNER));
        assert!(!boxes.deposit(&[7; 32], b"x", 100).unwrap());
        assert!(Boxes::open(dir.path(), Limits::default())
            .unwrap()
            .fetch(&OWNER, 0)
            .unwrap()
            .is_empty());
    }
}

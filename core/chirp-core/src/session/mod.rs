//! A sessão com cada contato, pelo libsignal (docs/PLANO.md, 4 e 6.3): PQXDH para abrir
//! (X25519 e ML-KEM/Kyber1024) e o Double Ratchet depois.
//!
//! O aperto de mão de um convite, numa conversa só pela rede:
//!
//! 1. Quem leu o convite (o "convidado") pede as prekeys, mostrando o token.
//! 2. Quem convidou confere o token (existe, não venceu, não foi usado) e manda as
//!    prekeys daquele convite, assinadas pela identidade dele.
//! 3. O convidado confere as assinaturas com a identidade que veio no convite, roda o
//!    PQXDH e manda o Hello cifrado: o token de novo, o perfil e como achá-lo na rede.
//! 4. Quem convidou decifra, confere o token dentro da sessão e o nó do transporte,
//!    gasta o convite, grava o contato e responde com o Welcome cifrado.
//! 5. O convidado decifra o Welcome, e o contato fica estabelecido dos dois lados.
//!
//! Cada passo de quem recebe roda numa transação: uma tentativa recusada não deixa
//! sessão, identidade nem contato no banco.

mod store;

use std::time::{Duration, SystemTime, UNIX_EPOCH};

use futures::executor::block_on;
use libsignal_protocol::{
    kem, message_decrypt_prekey, message_decrypt_signal, message_encrypt, process_prekey_bundle,
    CiphertextMessage, DeviceId, Fingerprint, GenericSignedPreKey, IdentityKey, IdentityKeyPair,
    KeyPair, KyberPreKeyRecord, PreKeyBundle, PreKeyRecord, PreKeySignalMessage, PrivateKey,
    ProtocolAddress, PublicKey, SignalMessage, SignedPreKeyRecord, Timestamp,
};
use prost::Message;
use rusqlite::{Connection, OptionalExtension};
use sha2::{Digest, Sha256};
use zeroize::Zeroizing;

use crate::contacts::{self, Contact, ContactState, NewContact};
use crate::error::{CoreError, CoreResult};
use crate::invite::Invite;
use crate::random::secret_bytes;
use crate::store::Store;
use crate::wire::{self, Content, ContentBody, Hello, Peer, PeerProfile, Welcome};
pub use store::ProtocolStore;

/// Quanto tempo um convite vale (docs/PLANO.md, 6.2).
pub const INVITE_TTL: Duration = Duration::from_secs(24 * 60 * 60);

/// Como o convite foi mostrado: o QR é frente a frente, e o contato nasce verificado.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InviteKind {
    Qr = 0,
    Link = 1,
}

/// As chaves locais além da identidade: o id de registro do libsignal, a chave do nó
/// do transporte (separada da identidade, para trocar sem perder contatos) e a chave
/// dos tokens de descoberta.
pub struct LocalKeys {
    pub registration_id: u32,
    pub endpoint_secret: Zeroizing<[u8; 32]>,
    pub discovery_key: Zeroizing<[u8; 32]>,
}

pub fn local_keys(conn: &Connection) -> CoreResult<LocalKeys> {
    let row: Option<(u32, Vec<u8>, Vec<u8>)> = conn
        .query_row(
            "SELECT registration_id, endpoint_secret, discovery_key FROM local_keys WHERE id = 1",
            [],
            |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
        )
        .optional()?;
    if let Some((registration_id, endpoint, discovery)) = row {
        let endpoint = Zeroizing::new(endpoint);
        let discovery = Zeroizing::new(discovery);
        return Ok(LocalKeys {
            registration_id,
            endpoint_secret: Zeroizing::new(
                endpoint
                    .as_slice()
                    .try_into()
                    .map_err(|_| CoreError::Storage)?,
            ),
            discovery_key: Zeroizing::new(
                discovery
                    .as_slice()
                    .try_into()
                    .map_err(|_| CoreError::Storage)?,
            ),
        });
    }
    let id_bytes = secret_bytes::<4>()?;
    let keys = LocalKeys {
        // O libsignal usa 14 bits, e o zero não vale.
        registration_id: (u32::from_be_bytes(*id_bytes) & 0x3fff).max(1),
        endpoint_secret: secret_bytes::<32>()?,
        discovery_key: secret_bytes::<32>()?,
    };
    conn.execute(
        "INSERT INTO local_keys (id, registration_id, endpoint_secret, discovery_key)
         VALUES (1, ?1, ?2, ?3)",
        (
            keys.registration_id,
            keys.endpoint_secret.as_slice(),
            keys.discovery_key.as_slice(),
        ),
    )?;
    Ok(keys)
}

/// A identidade do aparelho como o libsignal quer.
pub fn identity_pair(store: &Store) -> CoreResult<IdentityKeyPair> {
    let identity = store.identity()?.ok_or(CoreError::NoProfile)?;
    let private = PrivateKey::deserialize(identity.secret()).map_err(|_| CoreError::Storage)?;
    let public = private.public_key().map_err(|_| CoreError::Storage)?;
    Ok(IdentityKeyPair::new(IdentityKey::new(public), private))
}

/// O que veio do outro lado sobre como achá-lo, conferido: até 8 endereços que se
/// leem como IP e porta, e a chave de descoberta com 32 bytes.
fn sanitize(peer: Peer) -> CoreResult<Peer> {
    if peer.endpoint_id.len() != 32 || peer.discovery_key.len() != 32 {
        return Err(CoreError::Protocol);
    }
    let addrs = peer
        .addrs
        .into_iter()
        .filter(|a| a.len() <= 64 && a.parse::<std::net::SocketAddr>().is_ok())
        .take(8)
        .collect();
    Ok(Peer { addrs, ..peer })
}

/// O endereço do libsignal de um contato: a própria chave de identidade, em hex.
pub fn address_of(identity_key: &[u8]) -> ProtocolAddress {
    let name: String = identity_key.iter().map(|b| format!("{b:02x}")).collect();
    ProtocolAddress::new(name, DeviceId::new(1).expect("1 is a valid device id"))
}

/// O número de segurança de uma conversa: 60 dígitos, o mesmo nos dois aparelhos (a
/// metade de cada um é a "Sua chave" do perfil).
pub fn safety_number(local_key: &[u8], remote_key: &[u8]) -> CoreResult<String> {
    let local = IdentityKey::decode(local_key)?;
    let remote = IdentityKey::decode(remote_key)?;
    let fingerprint = Fingerprint::new(2, 5200, local_key, &local, remote_key, &remote)
        .map_err(|_| CoreError::Protocol)?;
    fingerprint
        .display_string()
        .map_err(|_| CoreError::Protocol)
}

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn token_hash(token: &[u8]) -> Vec<u8> {
    Sha256::digest(token).to_vec()
}

fn random_u32() -> CoreResult<u32> {
    Ok(u32::from_be_bytes(*secret_bytes::<4>()?) & 0x00ff_ffff)
}

fn protocol_store<'a>(conn: &'a Connection, store: &Store) -> CoreResult<ProtocolStore<'a>> {
    let keys = local_keys(store.conn())?;
    Ok(ProtocolStore::new(
        conn,
        identity_pair(store)?,
        keys.registration_id,
    ))
}

/// Cria um convite: o token e as prekeys só dele.
pub fn create_invite(
    store: &mut Store,
    kind: InviteKind,
    endpoint_id: [u8; 32],
    addrs: Vec<std::net::SocketAddr>,
) -> CoreResult<Invite> {
    let identity = identity_pair(store)?;
    local_keys(store.conn())?;
    let mut rng = rand::rng();
    let token = secret_bytes::<32>()?;
    let (prekey_id, signed_id, kyber_id) = (random_u32()?, random_u32()?, random_u32()?);
    let now = Timestamp::from_epoch_millis(now_secs() * 1000);

    let prekey = PreKeyRecord::new(prekey_id.into(), &KeyPair::generate(&mut rng));
    let signed_pair = KeyPair::generate(&mut rng);
    let signature = identity
        .private_key()
        .calculate_signature(&signed_pair.public_key.serialize(), &mut rng)
        .map_err(|_| CoreError::Protocol)?;
    let signed = SignedPreKeyRecord::new(signed_id.into(), now, &signed_pair, &signature);
    let kyber = KyberPreKeyRecord::generate(
        kem::KeyType::Kyber1024,
        kyber_id.into(),
        identity.private_key(),
    )?;

    let tx = store.conn_mut().transaction()?;
    forget_dead_invites(&tx)?;
    tx.execute(
        "INSERT INTO prekeys (id, record) VALUES (?1, ?2)",
        (prekey_id, prekey.serialize()?),
    )?;
    tx.execute(
        "INSERT INTO signed_prekeys (id, record) VALUES (?1, ?2)",
        (signed_id, signed.serialize()?),
    )?;
    tx.execute(
        "INSERT INTO kyber_prekeys (id, record) VALUES (?1, ?2)",
        (kyber_id, kyber.serialize()?),
    )?;
    tx.execute(
        "INSERT INTO invites (token_hash, kind, expires_at, prekey_id, signed_prekey_id,
                              kyber_prekey_id)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        (
            token_hash(token.as_ref()),
            kind as i64,
            (now_secs() + INVITE_TTL.as_secs()) as i64,
            prekey_id,
            signed_id,
            kyber_id,
        ),
    )?;
    tx.commit()?;

    let identity_key: [u8; 33] = identity
        .identity_key()
        .serialize()
        .as_ref()
        .try_into()
        .map_err(|_| CoreError::Protocol)?;
    Ok(Invite {
        identity_key,
        endpoint_id,
        token: *token,
        addrs,
    })
}

/// Tira os convites vencidos ou usados, e as prekeys que sobraram deles.
fn forget_dead_invites(conn: &Connection) -> CoreResult<()> {
    let dead = "SELECT {col} FROM invites WHERE used = 1 OR expires_at <= ?1";
    let now = now_secs() as i64;
    for (table, col) in [
        ("prekeys", "prekey_id"),
        ("signed_prekeys", "signed_prekey_id"),
        ("kyber_prekeys", "kyber_prekey_id"),
    ] {
        conn.execute(
            &format!(
                "DELETE FROM {table} WHERE id IN ({})",
                dead.replace("{col}", col)
            ),
            [now],
        )?;
    }
    conn.execute(
        "DELETE FROM invites WHERE used = 1 OR expires_at <= ?1",
        [now],
    )?;
    Ok(())
}

struct InviteRow {
    prekey_id: u32,
    signed_id: u32,
    kyber_id: u32,
}

/// O convite vivo deste token, ou `InviteRefused`.
fn live_invite(conn: &Connection, token: &[u8]) -> CoreResult<InviteRow> {
    let row: Option<(i64, u32, u32, u32, bool)> = conn
        .query_row(
            "SELECT expires_at, prekey_id, signed_prekey_id, kyber_prekey_id, used
               FROM invites WHERE token_hash = ?1",
            [token_hash(token)],
            |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?, r.get(4)?)),
        )
        .optional()?;
    match row {
        Some((expires, prekey_id, signed_id, kyber_id, false)) if expires as u64 > now_secs() => {
            Ok(InviteRow {
                prekey_id,
                signed_id,
                kyber_id,
            })
        }
        _ => Err(CoreError::InviteRefused),
    }
}

/// Passo 2: as prekeys do convite, para quem mostrou o token.
pub fn bundle_for(store: &Store, token: &[u8]) -> CoreResult<wire::Bundle> {
    let invite = live_invite(store.conn(), token)?;
    let ps = protocol_store(store.conn(), store)?;
    block_on(async {
        use libsignal_protocol::{KyberPreKeyStore, PreKeyStore, SignedPreKeyStore};
        let prekey = ps.get_pre_key(invite.prekey_id.into()).await?;
        let signed = ps.get_signed_pre_key(invite.signed_id.into()).await?;
        let kyber = ps.get_kyber_pre_key(invite.kyber_id.into()).await?;
        Ok(wire::Bundle {
            registration_id: local_keys(store.conn())?.registration_id,
            prekey_id: invite.prekey_id,
            prekey: prekey.public_key()?.serialize().to_vec(),
            signed_prekey_id: invite.signed_id,
            signed_prekey: signed.public_key()?.serialize().to_vec(),
            signed_prekey_signature: signed.signature()?.to_vec(),
            kyber_prekey_id: invite.kyber_id,
            kyber_prekey: kyber.public_key()?.serialize().to_vec(),
            kyber_prekey_signature: kyber.signature()?.to_vec(),
        })
    })
}

fn random_message_id() -> CoreResult<Vec<u8>> {
    Ok(secret_bytes::<16>()?.to_vec())
}

/// Passo 3: confere as prekeys, abre a sessão e devolve o Hello cifrado. O contato
/// fica pendente até o Welcome.
pub fn join(
    store: &mut Store,
    invite: &Invite,
    bundle: &wire::Bundle,
    me: Peer,
    verified: bool,
) -> CoreResult<(Contact, Vec<u8>)> {
    let own = identity_pair(store)?;
    if own.identity_key().serialize().as_ref() == invite.identity_key.as_slice() {
        return Err(CoreError::OwnInvite);
    }
    if contacts::by_identity(store.conn(), &invite.identity_key)?.is_some() {
        return Err(CoreError::AlreadyExists);
    }
    let profile = store.profile()?.ok_or(CoreError::NoProfile)?;
    let their_identity = IdentityKey::decode(&invite.identity_key)?;
    let prekey_bundle = PreKeyBundle::new(
        bundle.registration_id,
        DeviceId::new(1).expect("valid"),
        Some((
            bundle.prekey_id.into(),
            PublicKey::deserialize(&bundle.prekey).map_err(|_| CoreError::Protocol)?,
        )),
        bundle.signed_prekey_id.into(),
        PublicKey::deserialize(&bundle.signed_prekey).map_err(|_| CoreError::Protocol)?,
        bundle.signed_prekey_signature.clone(),
        bundle.kyber_prekey_id.into(),
        kem::PublicKey::deserialize(&bundle.kyber_prekey)?,
        bundle.kyber_prekey_signature.clone(),
        their_identity,
    )?;
    let address = address_of(&invite.identity_key);
    let local = address_of(&own.identity_key().serialize());
    let hello = Content {
        message_id: random_message_id()?,
        body: Some(ContentBody::Hello(Hello {
            token: invite.token.to_vec(),
            profile: Some(PeerProfile {
                display_name: profile.display_name,
                version: profile.version,
            }),
            peer: Some(me),
        })),
        sent_at: 0,
        lamport: 0,
        padding: vec![],
    }
    .encode_padded();

    let keys = local_keys(store.conn())?;
    let tx = store.conn_mut().transaction()?;
    let message = {
        let mut ps = ProtocolStore::new(&tx, own, keys.registration_id);
        let mut rng = rand::rng();
        block_on(async {
            // As assinaturas das prekeys são conferidas aqui, com a identidade do convite.
            process_prekey_bundle(
                &address,
                &local,
                &mut ps.clone_view(),
                &mut ps.clone_view(),
                &prekey_bundle,
                SystemTime::now(),
                &mut rng,
            )
            .await?;
            message_encrypt(
                &hello,
                &address,
                &local,
                &mut ps.clone_view(),
                &mut ps,
                SystemTime::now(),
                &mut rng,
            )
            .await
        })?
    };
    let CiphertextMessage::PreKeySignalMessage(message) = message else {
        return Err(CoreError::Protocol);
    };
    let contact = contacts::insert(
        &tx,
        &NewContact {
            identity_key: &invite.identity_key,
            endpoint_id: &invite.endpoint_id,
            addrs: &invite
                .addrs
                .iter()
                .map(|a| a.to_string())
                .collect::<Vec<_>>(),
            discovery_key: &[],
            display_name: "",
            profile_version: 0,
            verified,
            state: ContactState::Pending,
        },
        now_secs(),
    )?;
    tx.commit()?;
    Ok((contact, message.serialized().to_vec()))
}

/// Passo 4: decifra o Hello de quem leu nosso convite, confere tudo, grava o contato e
/// devolve o Welcome cifrado.
pub fn accept_hello(
    store: &mut Store,
    remote_endpoint: &[u8; 32],
    message: &[u8],
    me: Peer,
) -> CoreResult<(Contact, Vec<u8>)> {
    let own = identity_pair(store)?;
    let profile = store.profile()?.ok_or(CoreError::NoProfile)?;
    let keys = local_keys(store.conn())?;
    let message = PreKeySignalMessage::try_from(message)?;
    let their_key = message.identity_key().serialize().to_vec();
    if contacts::by_identity(store.conn(), &their_key)?.is_some() {
        return Err(CoreError::AlreadyExists);
    }
    let address = address_of(&their_key);
    let local = address_of(&own.identity_key().serialize());

    let tx = store.conn_mut().transaction()?;
    let plain = {
        let mut ps = ProtocolStore::new(&tx, own, keys.registration_id);
        let mut rng = rand::rng();
        block_on(message_decrypt_prekey(
            &message,
            &address,
            &local,
            &mut ps.clone_view(),
            &mut ps.clone_view(),
            &mut ps.clone_view(),
            &ps.clone_view(),
            &mut ps,
            &mut rng,
        ))?
    };
    let content = Content::decode(plain.plaintext.as_slice()).map_err(|_| CoreError::Protocol)?;
    let Some(ContentBody::Hello(hello)) = content.body else {
        return Err(CoreError::Protocol);
    };
    // O token tem de ser o de um convite vivo, e as prekeys usadas as daquele convite.
    let invite = live_invite(&tx, &hello.token)?;
    if message.pre_key_id().map(u32::from) != Some(invite.prekey_id)
        || u32::from(message.signed_pre_key_id()) != invite.signed_id
    {
        return Err(CoreError::InviteRefused);
    }
    let peer = sanitize(hello.peer.ok_or(CoreError::Protocol)?)?;
    // Quem fala pela rede tem de ser o nó que o Hello diz.
    if peer.endpoint_id.as_slice() != remote_endpoint.as_slice() {
        return Err(CoreError::Protocol);
    }
    let their_profile = hello.profile.ok_or(CoreError::Protocol)?;
    let name = crate::profile::validate_name(&their_profile.display_name)
        .map_err(|_| CoreError::Protocol)?;
    tx.execute(
        "UPDATE invites SET used = 1 WHERE token_hash = ?1",
        [token_hash(&hello.token)],
    )?;
    tx.execute(
        "DELETE FROM signed_prekeys WHERE id = ?1",
        [invite.signed_id],
    )?;
    let contact = contacts::insert(
        &tx,
        &NewContact {
            identity_key: &their_key,
            endpoint_id: &peer.endpoint_id,
            addrs: &peer.addrs,
            discovery_key: &peer.discovery_key,
            display_name: &name,
            profile_version: their_profile.version,
            // Quem convidou não conferiu nada de quem leu: o QR prova a chave de quem
            // o mostra, não a de quem o lê. Verificado só depois de comparar o número.
            verified: false,
            state: ContactState::Established,
        },
        now_secs(),
    )?;
    let welcome = Content {
        message_id: random_message_id()?,
        body: Some(ContentBody::Welcome(Welcome {
            profile: Some(PeerProfile {
                display_name: profile.display_name,
                version: profile.version,
            }),
            peer: Some(me),
        })),
        sent_at: 0,
        lamport: 0,
        padding: vec![],
    }
    .encode_padded();
    let reply = {
        let mut ps = ProtocolStore::new(&tx, own, keys.registration_id);
        let mut rng = rand::rng();
        block_on(message_encrypt(
            &welcome,
            &address,
            &local,
            &mut ps.clone_view(),
            &mut ps,
            SystemTime::now(),
            &mut rng,
        ))?
    };
    tx.commit()?;
    Ok((contact, reply.serialize().to_vec()))
}

/// Passo 5: o Welcome de quem convidou fecha o contato pendente.
pub fn accept_welcome(
    store: &mut Store,
    contact_id: i64,
    remote_endpoint: &[u8; 32],
    message: &[u8],
) -> CoreResult<Contact> {
    let own = identity_pair(store)?;
    let keys = local_keys(store.conn())?;
    let contact = contacts::by_id(store.conn(), contact_id)?;
    if contact.state != ContactState::Pending
        || contact.endpoint_id.as_slice() != remote_endpoint.as_slice()
    {
        return Err(CoreError::Protocol);
    }
    let message = SignalMessage::try_from(message)?;
    let address = address_of(&contact.identity_key);
    let local = address_of(&own.identity_key().serialize());
    let tx = store.conn_mut().transaction()?;
    let plain = {
        let mut ps = ProtocolStore::new(&tx, own, keys.registration_id);
        let mut rng = rand::rng();
        block_on(message_decrypt_signal(
            &message,
            &address,
            &local,
            &mut ps.clone_view(),
            &mut ps,
            &mut rng,
        ))?
    };
    let content = Content::decode(plain.as_slice()).map_err(|_| CoreError::Protocol)?;
    let Some(ContentBody::Welcome(welcome)) = content.body else {
        return Err(CoreError::Protocol);
    };
    let profile = welcome.profile.ok_or(CoreError::Protocol)?;
    let peer = sanitize(welcome.peer.ok_or(CoreError::Protocol)?)?;
    if peer.endpoint_id.as_slice() != remote_endpoint.as_slice() {
        return Err(CoreError::Protocol);
    }
    let name =
        crate::profile::validate_name(&profile.display_name).map_err(|_| CoreError::Protocol)?;
    let contact = contacts::establish(
        &tx,
        contact.id,
        &name,
        profile.version,
        &peer.addrs,
        &peer.discovery_key,
    )?;
    tx.commit()?;
    Ok(contact)
}

/// A identidade e o id de registro, para cifrar e decifrar dentro de uma transação.
#[derive(Clone, Copy)]
pub struct Me {
    pair: IdentityKeyPair,
    registration_id: u32,
}

pub fn me(store: &Store) -> CoreResult<Me> {
    Ok(Me {
        pair: identity_pair(store)?,
        registration_id: local_keys(store.conn())?.registration_id,
    })
}

/// Cifra para um contato com a sessão aberta. Devolve se é uma mensagem de prekey (a
/// sessão ainda não foi confirmada pelo outro lado) e os bytes.
pub fn encrypt(
    conn: &Connection,
    me: &Me,
    their_key: &[u8],
    plain: &[u8],
) -> CoreResult<(bool, Vec<u8>)> {
    let address = address_of(their_key);
    let local = address_of(&me.pair.identity_key().serialize());
    let mut ps = ProtocolStore::new(conn, me.pair, me.registration_id);
    let mut rng = rand::rng();
    let message = block_on(message_encrypt(
        plain,
        &address,
        &local,
        &mut ps.clone_view(),
        &mut ps,
        SystemTime::now(),
        &mut rng,
    ))?;
    match message {
        CiphertextMessage::PreKeySignalMessage(m) => Ok((true, m.serialized().to_vec())),
        CiphertextMessage::SignalMessage(m) => Ok((false, m.serialized().to_vec())),
        _ => Err(CoreError::Protocol),
    }
}

/// Decifra o que veio de um contato. `None` quando a mensagem já foi decifrada antes
/// (o reenvio de quem não recebeu o Ack): quem chama confirma de novo e não faz nada.
pub fn decrypt(
    conn: &Connection,
    me: &Me,
    their_key: &[u8],
    prekey: bool,
    bytes: &[u8],
) -> CoreResult<Option<Vec<u8>>> {
    use libsignal_protocol::SignalProtocolError;
    let address = address_of(their_key);
    let local = address_of(&me.pair.identity_key().serialize());
    let mut ps = ProtocolStore::new(conn, me.pair, me.registration_id);
    let mut rng = rand::rng();
    let result = if prekey {
        let message = PreKeySignalMessage::try_from(bytes)?;
        // A sessão é com quem a gente já conhece: outra identidade é recusada.
        if message.identity_key().serialize().as_ref() != their_key {
            return Err(CoreError::Protocol);
        }
        block_on(message_decrypt_prekey(
            &message,
            &address,
            &local,
            &mut ps.clone_view(),
            &mut ps.clone_view(),
            &mut ps.clone_view(),
            &ps.clone_view(),
            &mut ps,
            &mut rng,
        ))
        .map(|d| d.plaintext)
    } else {
        let message = SignalMessage::try_from(bytes)?;
        block_on(message_decrypt_signal(
            &message,
            &address,
            &local,
            &mut ps.clone_view(),
            &mut ps,
            &mut rng,
        ))
    };
    match result {
        Ok(plain) => Ok(Some(plain)),
        Err(SignalProtocolError::DuplicatedMessage(..)) => Ok(None),
        Err(_) => Err(CoreError::Protocol),
    }
}

/// Esquece um contato pendente: o contato, a sessão e a identidade dele.
pub fn forget(store: &mut Store, contact_id: i64) -> CoreResult<()> {
    let contact = contacts::by_id(store.conn(), contact_id)?;
    let address = address_of(&contact.identity_key);
    let tx = store.conn_mut().transaction()?;
    tx.execute("DELETE FROM sessions WHERE address = ?1", [address.name()])?;
    tx.execute(
        "DELETE FROM identities WHERE address = ?1",
        [address.name()],
    )?;
    tx.execute("DELETE FROM contacts WHERE id = ?1", [contact_id])?;
    tx.commit()?;
    Ok(())
}

#[cfg(test)]
mod tests;

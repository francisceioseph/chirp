//! As lojas do libsignal sobre o banco cifrado: as sessões (o estado do ratchet), as
//! prekeys e as identidades dos contatos ficam no SQLCipher, como o resto.
//!
//! As funções do libsignal são `async`, mas nada aqui espera de verdade: o banco é
//! síncrono, e quem chama roda o futuro até o fim com `block_on`.

use async_trait::async_trait;
use libsignal_protocol::{
    Direction, GenericSignedPreKey, IdentityChange, IdentityKey, IdentityKeyPair, IdentityKeyStore,
    KyberPreKeyId, KyberPreKeyRecord, KyberPreKeyStore, PreKeyId, PreKeyRecord, PreKeyStore,
    ProtocolAddress, PublicKey, SessionRecord, SessionStore, SignalProtocolError, SignedPreKeyId,
    SignedPreKeyRecord, SignedPreKeyStore,
};
use rusqlite::{Connection, OptionalExtension};

type Result<T> = std::result::Result<T, SignalProtocolError>;

fn db(_: rusqlite::Error) -> SignalProtocolError {
    // Sem detalhe: o erro do SQLite pode trazer pedaços da consulta.
    SignalProtocolError::InvalidState("store", "database failure".into())
}

pub struct ProtocolStore<'a> {
    conn: &'a Connection,
    identity: IdentityKeyPair,
    registration_id: u32,
}

impl<'a> ProtocolStore<'a> {
    pub fn new(conn: &'a Connection, identity: IdentityKeyPair, registration_id: u32) -> Self {
        Self {
            conn,
            identity,
            registration_id,
        }
    }

    /// Outra alça para o mesmo banco: as funções do libsignal pedem cada loja como um
    /// `&mut` separado, e aqui todas são a mesma conexão.
    pub fn clone_view(&self) -> ProtocolStore<'a> {
        ProtocolStore {
            conn: self.conn,
            identity: self.identity,
            registration_id: self.registration_id,
        }
    }

    fn get_blob(&self, sql: &str, key: u32) -> Result<Option<Vec<u8>>> {
        self.conn
            .query_row(sql, [key], |row| row.get(0))
            .optional()
            .map_err(db)
    }

    fn put_blob(&self, sql: &str, key: u32, blob: &[u8]) -> Result<()> {
        self.conn.execute(sql, (key, blob)).map(|_| ()).map_err(db)
    }
}

#[async_trait(?Send)]
impl IdentityKeyStore for ProtocolStore<'_> {
    async fn get_identity_key_pair(&self) -> Result<IdentityKeyPair> {
        Ok(self.identity)
    }

    async fn get_local_registration_id(&self) -> Result<u32> {
        Ok(self.registration_id)
    }

    async fn save_identity(
        &mut self,
        address: &ProtocolAddress,
        identity: &IdentityKey,
    ) -> Result<IdentityChange> {
        let old = self.get_identity(address).await?;
        self.conn
            .execute(
                "INSERT INTO identities (address, identity_key) VALUES (?1, ?2)
                 ON CONFLICT (address) DO UPDATE SET identity_key = excluded.identity_key",
                (address.name(), identity.serialize().as_ref()),
            )
            .map_err(db)?;
        Ok(IdentityChange::from_changed(
            old.is_some_and(|old| old != *identity),
        ))
    }

    /// A identidade de um endereço nunca muda: o endereço é a própria chave. Uma chave
    /// diferente para o mesmo endereço é recusada, em qualquer direção.
    async fn is_trusted_identity(
        &self,
        address: &ProtocolAddress,
        identity: &IdentityKey,
        _direction: Direction,
    ) -> Result<bool> {
        Ok(match self.get_identity(address).await? {
            None => true,
            Some(known) => known == *identity,
        })
    }

    async fn get_identity(&self, address: &ProtocolAddress) -> Result<Option<IdentityKey>> {
        let bytes: Option<Vec<u8>> = self
            .conn
            .query_row(
                "SELECT identity_key FROM identities WHERE address = ?1",
                [address.name()],
                |row| row.get(0),
            )
            .optional()
            .map_err(db)?;
        bytes.map(|b| IdentityKey::decode(&b)).transpose()
    }
}

#[async_trait(?Send)]
impl PreKeyStore for ProtocolStore<'_> {
    async fn get_pre_key(&self, id: PreKeyId) -> Result<PreKeyRecord> {
        let bytes = self
            .get_blob("SELECT record FROM prekeys WHERE id = ?1", id.into())?
            .ok_or(SignalProtocolError::InvalidPreKeyId)?;
        PreKeyRecord::deserialize(&bytes)
    }

    async fn save_pre_key(&mut self, id: PreKeyId, record: &PreKeyRecord) -> Result<()> {
        self.put_blob(
            "INSERT OR REPLACE INTO prekeys (id, record) VALUES (?1, ?2)",
            id.into(),
            &record.serialize()?,
        )
    }

    async fn remove_pre_key(&mut self, id: PreKeyId) -> Result<()> {
        self.conn
            .execute("DELETE FROM prekeys WHERE id = ?1", [u32::from(id)])
            .map(|_| ())
            .map_err(db)
    }
}

#[async_trait(?Send)]
impl SignedPreKeyStore for ProtocolStore<'_> {
    async fn get_signed_pre_key(&self, id: SignedPreKeyId) -> Result<SignedPreKeyRecord> {
        let bytes = self
            .get_blob("SELECT record FROM signed_prekeys WHERE id = ?1", id.into())?
            .ok_or(SignalProtocolError::InvalidSignedPreKeyId)?;
        SignedPreKeyRecord::deserialize(&bytes)
    }

    async fn save_signed_pre_key(
        &mut self,
        id: SignedPreKeyId,
        record: &SignedPreKeyRecord,
    ) -> Result<()> {
        self.put_blob(
            "INSERT OR REPLACE INTO signed_prekeys (id, record) VALUES (?1, ?2)",
            id.into(),
            &record.serialize()?,
        )
    }
}

#[async_trait(?Send)]
impl KyberPreKeyStore for ProtocolStore<'_> {
    async fn get_kyber_pre_key(&self, id: KyberPreKeyId) -> Result<KyberPreKeyRecord> {
        let bytes = self
            .get_blob("SELECT record FROM kyber_prekeys WHERE id = ?1", id.into())?
            .ok_or(SignalProtocolError::InvalidKyberPreKeyId)?;
        KyberPreKeyRecord::deserialize(&bytes)
    }

    async fn save_kyber_pre_key(
        &mut self,
        id: KyberPreKeyId,
        record: &KyberPreKeyRecord,
    ) -> Result<()> {
        self.put_blob(
            "INSERT OR REPLACE INTO kyber_prekeys (id, record) VALUES (?1, ?2)",
            id.into(),
            &record.serialize()?,
        )
    }

    /// Cada chave Kyber do Chirp é de um convite só: usada, sai.
    async fn mark_kyber_pre_key_used(
        &mut self,
        id: KyberPreKeyId,
        _ec_prekey_id: SignedPreKeyId,
        _base_key: &PublicKey,
    ) -> Result<()> {
        self.conn
            .execute("DELETE FROM kyber_prekeys WHERE id = ?1", [u32::from(id)])
            .map(|_| ())
            .map_err(db)
    }
}

#[async_trait(?Send)]
impl SessionStore for ProtocolStore<'_> {
    async fn load_session(&self, address: &ProtocolAddress) -> Result<Option<SessionRecord>> {
        let bytes: Option<Vec<u8>> = self
            .conn
            .query_row(
                "SELECT record FROM sessions WHERE address = ?1",
                [address.name()],
                |row| row.get(0),
            )
            .optional()
            .map_err(db)?;
        bytes.map(|b| SessionRecord::deserialize(&b)).transpose()
    }

    async fn store_session(
        &mut self,
        address: &ProtocolAddress,
        record: &SessionRecord,
    ) -> Result<()> {
        self.conn
            .execute(
                "INSERT INTO sessions (address, record) VALUES (?1, ?2)
                 ON CONFLICT (address) DO UPDATE SET record = excluded.record",
                (address.name(), record.serialize()?),
            )
            .map(|_| ())
            .map_err(db)
    }
}

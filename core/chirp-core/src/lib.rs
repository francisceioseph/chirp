//! O núcleo do Psito Chirp: criptografia, rede e armazenamento, sem Flutter.
//!
//! O Flutter fala só com o módulo `api`, pela ponte gerada (`frb_generated`). O resto
//! é o domínio, que a ponte não vê (ver `docs/PLANO.md`, 5 e 11).

pub mod api;

mod appearance;
mod contacts;
mod discovery;
mod downloads;
mod error;
mod files;
mod identity;
mod invite;
mod mailbox;
mod messages;
mod network;
mod node;
mod notifications;
mod passphrase;
mod profile;
mod random;
mod session;
mod store;
mod voice;
mod wire;

#[allow(unsafe_code)]
mod frb_generated;

//! O núcleo do Psito Chirp: criptografia, rede e armazenamento, sem Flutter.
//!
//! O Flutter fala só com o módulo `api`, pela ponte gerada (`frb_generated`). O resto
//! é o domínio, que a ponte não vê (ver `docs/PLANO.md`, 5 e 11).

pub mod api;

mod error;
mod identity;
mod passphrase;
mod profile;
mod random;
mod store;

#[allow(unsafe_code)]
mod frb_generated;

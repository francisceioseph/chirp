//! O núcleo do Psito Chirp: criptografia, rede e armazenamento, sem Flutter.
//!
//! O Flutter fala só com o módulo `api`, pela ponte gerada (`frb_generated`). O resto
//! do núcleo entra nas próximas fases (ver `docs/PLANO.md`).

pub mod api;

#[allow(unsafe_code)]
mod frb_generated;

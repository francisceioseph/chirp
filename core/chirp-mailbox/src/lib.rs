//! A caixa postal do Psito Chirp (docs/PLANO.md, 7.6): um aparelho sempre ligado de
//! quem usa o app, que guarda os envelopes que os contatos deixam enquanto ele está
//! offline. Os envelopes já chegam cifrados pela sessão do Signal: a caixa não tem
//! chave de nada.
//!
//! O núcleo do app usa só o `proto` e o `link` (sem a feature `server`); o binário
//! `chirp-mailbox` é o resto.

pub mod link;
pub mod proto;

#[cfg(feature = "server")]
pub mod server;
#[cfg(feature = "server")]
pub mod store;

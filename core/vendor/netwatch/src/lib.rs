//! Networking related utilities
// Cópia do crates.io: os avisos do código de lá não são deste projeto.
#![allow(deprecated)]

pub mod interfaces;
pub mod ip;
mod ip_family;
pub mod netmon;
#[cfg(target_os = "ios")]
mod sys;
#[cfg(all(not(target_os = "ios"), not(wasm_browser)))]
#[allow(unused_imports)] // só o código dos BSD usa
use libc as sys;
#[cfg(not(wasm_browser))]
mod udp;

pub use self::ip_family::IpFamily;
#[cfg(not(wasm_browser))]
pub use self::udp::{UdpSender, UdpSocket};

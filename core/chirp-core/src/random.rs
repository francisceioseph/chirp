//! Números aleatórios, só do sistema (o `getrandom`): nada de gerador próprio.

use zeroize::Zeroizing;

use crate::error::{CoreError, CoreResult};

/// `N` bytes aleatórios, apagados da memória quando saem de uso.
pub fn secret_bytes<const N: usize>() -> CoreResult<Zeroizing<[u8; N]>> {
    let mut bytes = Zeroizing::new([0u8; N]);
    getrandom::fill(bytes.as_mut()).map_err(|_| CoreError::NoRandomness)?;
    Ok(bytes)
}

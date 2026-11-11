//! O que o núcleo diz de si.

/// A versão do protocolo no fio. Sobe só numa mudança incompatível (`docs/PLANO.md`, 6.4).
pub const PROTOCOL_VERSION: u32 = 1;

/// A versão do núcleo e a do protocolo que ele fala.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoreInfo {
    pub version: String,
    pub protocol: u32,
}

#[flutter_rust_bridge::frb(sync)]
pub fn core_info() -> CoreInfo {
    CoreInfo {
        version: env!("CARGO_PKG_VERSION").to_owned(),
        protocol: PROTOCOL_VERSION,
    }
}

/// Roda uma vez, quando o Dart abre a biblioteca.
///
/// O `setup_default_user_utils` da ponte também liga o log no console em nível `Trace`,
/// e o Chirp não escreve log sem o usuário pedir. Fica só o backtrace, e só em
/// desenvolvimento.
#[flutter_rust_bridge::frb(init)]
pub fn init_core() {
    #[cfg(debug_assertions)]
    flutter_rust_bridge::setup_backtrace();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn core_info_reports_the_crate_and_protocol_versions() {
        let info = core_info();
        assert_eq!(info.version, env!("CARGO_PKG_VERSION"));
        assert_eq!(info.protocol, PROTOCOL_VERSION);
    }
}

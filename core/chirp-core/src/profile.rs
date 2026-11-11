//! O perfil local: o nome que os contatos veem (só cifrado, só para eles, a partir da
//! fase 3), com versão.

use crate::error::{CoreError, CoreResult};

/// O máximo de caracteres de um nome.
pub const MAX_NAME_CHARS: usize = 64;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StoredProfile {
    pub display_name: String,
    pub version: u32,
    pub public_key: Vec<u8>,
}

/// Tira os espaços das pontas e recusa vazio, comprido demais ou com caracteres de
/// controle (quebra de linha, direção do texto escondida e afins).
pub fn validate_name(name: &str) -> CoreResult<String> {
    let name = name.trim();
    let chars = name.chars().count();
    if chars == 0 || chars > MAX_NAME_CHARS {
        return Err(CoreError::InvalidName);
    }
    if name.chars().any(|c| c.is_control() || is_bidi_override(c)) {
        return Err(CoreError::InvalidName);
    }
    Ok(name.to_owned())
}

fn is_bidi_override(c: char) -> bool {
    matches!(c, '\u{202A}'..='\u{202E}' | '\u{2066}'..='\u{2069}')
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn names_are_trimmed() {
        assert_eq!(validate_name("  Lutino ").unwrap(), "Lutino");
        assert_eq!(validate_name("Калопсита").unwrap(), "Калопсита");
        assert_eq!(validate_name("玄凤鹦鹉").unwrap(), "玄凤鹦鹉");
    }

    #[test]
    fn bad_names_are_refused() {
        for bad in ["", "   ", "a\nb", "a\u{0}b", "abc\u{202E}def"] {
            assert_eq!(validate_name(bad), Err(CoreError::InvalidName), "{bad:?}");
        }
        assert!(validate_name(&"a".repeat(MAX_NAME_CHARS)).is_ok());
        assert_eq!(
            validate_name(&"a".repeat(MAX_NAME_CHARS + 1)),
            Err(CoreError::InvalidName)
        );
    }
}

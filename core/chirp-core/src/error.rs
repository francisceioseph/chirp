//! Os erros do núcleo. Não falam língua nenhuma: a UI escolhe o texto (traduzido) pelo
//! tipo, e nada aqui carrega conteúdo, nome, chave ou caminho.

use thiserror::Error;

#[derive(Debug, Error, Clone, Copy, PartialEq, Eq)]
pub enum CoreError {
    /// A chave ou a senha não abre o banco (ou o arquivo não é um banco do Chirp).
    #[error("the key does not open the store")]
    WrongKey,
    /// A chave do banco não tem 32 bytes.
    #[error("the store key has the wrong size")]
    BadKey,
    /// A senha é curta demais (menos de `MIN_PASSPHRASE_CHARS` caracteres).
    #[error("the passphrase is too short")]
    WeakPassphrase,
    /// O nome está vazio, comprido demais ou tem caracteres de controle.
    #[error("the name is not valid")]
    InvalidName,
    /// Já existe um perfil, ou um banco onde ia nascer um novo.
    #[error("it already exists")]
    AlreadyExists,
    /// O banco foi gravado por uma versão mais nova do Chirp.
    #[error("the store comes from a newer version")]
    NewerStore,
    /// O sistema não deu números aleatórios.
    #[error("no randomness from the system")]
    NoRandomness,
    /// Falha de disco ou do SQLite que não é nenhuma das acima.
    #[error("storage failure")]
    Storage,
}

impl From<rusqlite::Error> for CoreError {
    fn from(error: rusqlite::Error) -> Self {
        match error.sqlite_error_code() {
            Some(rusqlite::ErrorCode::NotADatabase) => CoreError::WrongKey,
            _ => CoreError::Storage,
        }
    }
}

impl From<std::io::Error> for CoreError {
    fn from(_: std::io::Error) -> Self {
        CoreError::Storage
    }
}

pub type CoreResult<T> = Result<T, CoreError>;

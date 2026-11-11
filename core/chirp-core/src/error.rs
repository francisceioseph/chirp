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
    /// Ainda não há perfil (e, portanto, identidade) neste aparelho.
    #[error("there is no profile yet")]
    NoProfile,
    /// O convite (link ou QR) não se lê: cortado, de outra versão ou adulterado.
    #[error("the invite is not valid")]
    InvalidInvite,
    /// O outro lado recusou o convite: vencido, já usado ou desconhecido.
    #[error("the invite was refused")]
    InviteRefused,
    /// O convite é deste próprio aparelho.
    #[error("the invite is our own")]
    OwnInvite,
    /// Não deu para falar com o outro aparelho pela rede.
    #[error("the other device could not be reached")]
    Unreachable,
    /// O outro lado respondeu fora do protocolo, ou a criptografia não fechou.
    #[error("the other device broke the protocol")]
    Protocol,
    /// Não há contato com esse id.
    #[error("there is no such contact")]
    UnknownContact,
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

impl From<libsignal_protocol::SignalProtocolError> for CoreError {
    fn from(_: libsignal_protocol::SignalProtocolError) -> Self {
        CoreError::Protocol
    }
}

pub type CoreResult<T> = Result<T, CoreError>;

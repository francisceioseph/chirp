//! O baixar sozinho: até que tamanho o arquivo de um contato baixa sem quem usa pedir,
//! e se só dos contatos verificados (o código de segurança conferido). O resto espera
//! o "Baixar". O padrão é até 32 MiB, de qualquer contato.

use rusqlite::Connection;

use crate::error::CoreResult;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Limit {
    Never,
    /// Até 4 MiB: fotos e documentos pequenos.
    Small,
    /// Até 32 MiB.
    Medium,
    /// Até 256 MiB.
    Large,
}

pub const DEFAULT_LIMIT: Limit = Limit::Medium;

impl Limit {
    pub fn bytes(self) -> u64 {
        match self {
            Limit::Never => 0,
            Limit::Small => 4 << 20,
            Limit::Medium => 32 << 20,
            Limit::Large => 256 << 20,
        }
    }

    fn code(self) -> i64 {
        match self {
            Limit::Never => 0,
            Limit::Small => 1,
            Limit::Medium => 2,
            Limit::Large => 3,
        }
    }

    fn from_code(code: i64) -> Self {
        match code {
            0 => Limit::Never,
            1 => Limit::Small,
            3 => Limit::Large,
            _ => DEFAULT_LIMIT,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Policy {
    pub limit: Limit,
    pub only_verified: bool,
}

impl Policy {
    /// O arquivo, de um contato verificado ou não, baixa sozinho?
    pub fn allows(self, size: u64, verified: bool) -> bool {
        self.limit != Limit::Never
            && size <= self.limit.bytes()
            && (verified || !self.only_verified)
    }
}

pub fn get(conn: &Connection) -> CoreResult<Policy> {
    Ok(conn.query_row(
        "SELECT auto_limit, only_verified FROM downloads WHERE id = 1",
        [],
        |r| {
            Ok(Policy {
                limit: Limit::from_code(r.get(0)?),
                only_verified: r.get(1)?,
            })
        },
    )?)
}

pub fn set(conn: &Connection, policy: Policy) -> CoreResult<()> {
    conn.execute(
        "UPDATE downloads SET auto_limit = ?1, only_verified = ?2 WHERE id = 1",
        (policy.limit.code(), policy.only_verified),
    )?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn conn() -> Connection {
        let mut conn = Connection::open_in_memory().unwrap();
        crate::store::migrations::run(&mut conn).unwrap();
        conn
    }

    #[test]
    fn the_default_is_32_mib_from_anyone() {
        let policy = get(&conn()).unwrap();
        assert_eq!(
            policy,
            Policy {
                limit: Limit::Medium,
                only_verified: false
            }
        );
        assert!(policy.allows(32 << 20, false));
        assert!(!policy.allows((32 << 20) + 1, true));
    }

    #[test]
    fn keeps_what_was_chosen() {
        let conn = conn();
        for limit in [Limit::Never, Limit::Small, Limit::Large, Limit::Medium] {
            for only_verified in [true, false] {
                let policy = Policy {
                    limit,
                    only_verified,
                };
                set(&conn, policy).unwrap();
                assert_eq!(get(&conn).unwrap(), policy);
            }
        }
    }

    #[test]
    fn only_verified_and_never() {
        let strict = Policy {
            limit: Limit::Small,
            only_verified: true,
        };
        assert!(strict.allows(10, true));
        assert!(!strict.allows(10, false));
        assert!(!strict.allows((4 << 20) + 1, true));
        let never = Policy {
            limit: Limit::Never,
            only_verified: false,
        };
        assert!(!never.allows(0, true));
    }

    #[test]
    fn a_strange_code_becomes_the_default() {
        let conn = conn();
        conn.execute("UPDATE downloads SET auto_limit = 9 WHERE id = 1", [])
            .unwrap();
        assert_eq!(get(&conn).unwrap().limit, DEFAULT_LIMIT);
    }
}

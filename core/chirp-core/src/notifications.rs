//! O que as notificações mostram: nada, só "Nova mensagem", o nome de quem mandou,
//! ou o nome e o texto. O padrão é o nome sem o texto: o que a pessoa escreveu só
//! sai do app para a tela do sistema (e para a tela bloqueada) se quem usa pedir.

use rusqlite::Connection;

use crate::error::CoreResult;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    /// Nenhuma notificação.
    Off,
    /// Só "Nova mensagem", sem nome nem texto.
    Hidden,
    /// O nome de quem mandou, sem o texto.
    Sender,
    /// O nome e o texto.
    Full,
}

pub const DEFAULT: Mode = Mode::Sender;

impl Mode {
    fn code(self) -> i64 {
        match self {
            Mode::Off => 0,
            Mode::Hidden => 1,
            Mode::Sender => 2,
            Mode::Full => 3,
        }
    }

    fn from_code(code: i64) -> Self {
        match code {
            0 => Mode::Off,
            1 => Mode::Hidden,
            3 => Mode::Full,
            _ => DEFAULT,
        }
    }
}

pub fn get(conn: &Connection) -> CoreResult<Mode> {
    Ok(
        conn.query_row("SELECT mode FROM notifications WHERE id = 1", [], |r| {
            Ok(Mode::from_code(r.get(0)?))
        })?,
    )
}

pub fn set(conn: &Connection, mode: Mode) -> CoreResult<()> {
    conn.execute(
        "UPDATE notifications SET mode = ?1 WHERE id = 1",
        [mode.code()],
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
    fn starts_with_the_sender_only() {
        assert_eq!(get(&conn()).unwrap(), Mode::Sender);
    }

    #[test]
    fn keeps_what_was_chosen() {
        let conn = conn();
        for mode in [Mode::Off, Mode::Hidden, Mode::Full, Mode::Sender] {
            set(&conn, mode).unwrap();
            assert_eq!(get(&conn).unwrap(), mode);
        }
    }

    #[test]
    fn a_strange_code_becomes_the_default() {
        let conn = conn();
        conn.execute("UPDATE notifications SET mode = 9 WHERE id = 1", [])
            .unwrap();
        assert_eq!(get(&conn).unwrap(), DEFAULT);
    }
}

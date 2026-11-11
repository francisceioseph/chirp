//! A aparência escolhida: o tema (o id de uma semente da UI), o claro ou escuro e o
//! efeito vidro. Fica no banco, cifrado como o resto: até o gosto de quem usa é dele.

use rusqlite::Connection;

use crate::error::CoreResult;

/// O tema quando nada foi escolhido, ou quando o id gravado não serve.
pub const DEFAULT_THEME: &str = "lutino";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Brightness {
    System,
    Light,
    Dark,
}

impl Brightness {
    fn code(self) -> i64 {
        match self {
            Brightness::System => 0,
            Brightness::Light => 1,
            Brightness::Dark => 2,
        }
    }

    fn from_code(code: i64) -> Self {
        match code {
            1 => Brightness::Light,
            2 => Brightness::Dark,
            _ => Brightness::System,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Appearance {
    pub theme: String,
    pub brightness: Brightness,
    pub glass: bool,
}

/// Um id de tema é curto, em minúsculas ASCII e hífens; o resto vira o padrão.
fn valid_theme(theme: &str) -> bool {
    (1..=32).contains(&theme.len()) && theme.bytes().all(|b| b.is_ascii_lowercase() || b == b'-')
}

pub fn get(conn: &Connection) -> CoreResult<Appearance> {
    Ok(conn.query_row(
        "SELECT theme, brightness, glass FROM appearance WHERE id = 1",
        [],
        |r| {
            let theme: String = r.get(0)?;
            Ok(Appearance {
                theme: if valid_theme(&theme) {
                    theme
                } else {
                    DEFAULT_THEME.into()
                },
                brightness: Brightness::from_code(r.get(1)?),
                glass: r.get(2)?,
            })
        },
    )?)
}

pub fn set(conn: &Connection, appearance: &Appearance) -> CoreResult<()> {
    let theme = if valid_theme(&appearance.theme) {
        appearance.theme.as_str()
    } else {
        DEFAULT_THEME
    };
    conn.execute(
        "UPDATE appearance SET theme = ?1, brightness = ?2, glass = ?3 WHERE id = 1",
        (theme, appearance.brightness.code(), appearance.glass),
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
    fn starts_with_the_default() {
        let a = get(&conn()).unwrap();
        assert_eq!(a.theme, DEFAULT_THEME);
        assert_eq!(a.brightness, Brightness::System);
        assert!(!a.glass);
    }

    #[test]
    fn keeps_what_was_chosen() {
        let conn = conn();
        let chosen = Appearance {
            theme: "wild-grey".into(),
            brightness: Brightness::Dark,
            glass: true,
        };
        set(&conn, &chosen).unwrap();
        assert_eq!(get(&conn).unwrap(), chosen);
    }

    #[test]
    fn a_strange_theme_becomes_the_default() {
        let conn = conn();
        for theme in ["", "Lutino", "../x", &"a".repeat(33)] {
            set(
                &conn,
                &Appearance {
                    theme: theme.into(),
                    brightness: Brightness::Light,
                    glass: false,
                },
            )
            .unwrap();
            assert_eq!(get(&conn).unwrap().theme, DEFAULT_THEME);
        }
    }
}

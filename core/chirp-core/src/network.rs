//! A rede além da local (fase 5): ligar a internet e os servidores de retransmissão
//! (docs/PLANO.md, 7.3). Os dois começam desligados: sem internet, o nó só fala com
//! endereços da rede local; com ela, os contatos recebem os endereços públicos deste
//! aparelho, e com um retransmissor o iroh fura o NAT (ou repassa por ele).
//!
//! O retransmissor vê os IPs e os nós de quem conversa e repassa bytes já cifrados.
//! Nenhum é padrão: quem usa escolhe um (o próprio, ou de alguém em quem confia).

use iroh::RelayUrl;
use rusqlite::Connection;

use crate::error::{CoreError, CoreResult};

/// Quantos retransmissores, no máximo.
pub const MAX_RELAYS: usize = 3;
const MAX_URL: usize = 200;

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Settings {
    pub internet: bool,
    pub relays: Vec<String>,
    /// O Bluetooth (fase 8): anunciar e procurar os contatos por perto.
    pub bluetooth: bool,
}

impl Settings {
    /// Os retransmissores que valem agora (só com a internet ligada).
    pub fn relay_urls(&self) -> Vec<RelayUrl> {
        if !self.internet {
            return vec![];
        }
        self.relays.iter().filter_map(|r| r.parse().ok()).collect()
    }
}

/// Um endereço de retransmissor: `https://` (ou `http://`, para testar numa rede
/// própria), com host e sem nada estranho. Devolve o texto normalizado.
pub fn relay_url(text: &str) -> CoreResult<String> {
    let text = text.trim();
    if text.is_empty() || text.len() > MAX_URL || text.chars().any(char::is_control) {
        return Err(CoreError::InvalidRelay);
    }
    let url: RelayUrl = text.parse().map_err(|_| CoreError::InvalidRelay)?;
    let parsed = &*url;
    if !matches!(parsed.scheme(), "https" | "http")
        || parsed.host_str().is_none_or(str::is_empty)
        || !parsed.username().is_empty()
        || parsed.password().is_some()
        || parsed.query().is_some()
        || parsed.fragment().is_some()
    {
        return Err(CoreError::InvalidRelay);
    }
    Ok(url.to_string())
}

/// Os endereços que um contato mandou, conferidos: até 8 que se leem como IP e porta
/// e até [`MAX_RELAYS`] retransmissores válidos, na ordem em que vieram. O resto sai.
pub fn clean_addrs(addrs: Vec<String>) -> Vec<String> {
    let (mut ips, mut relays) = (0, 0);
    let mut out = Vec::new();
    for addr in addrs {
        if addr.len() <= 64 && addr.parse::<std::net::SocketAddr>().is_ok() {
            if ips < 8 && !out.contains(&addr) {
                ips += 1;
                out.push(addr);
            }
        } else if let Ok(relay) = relay_url(&addr) {
            if relays < MAX_RELAYS && !out.contains(&relay) {
                relays += 1;
                out.push(relay);
            }
        }
    }
    out
}

pub fn get(conn: &Connection) -> CoreResult<Settings> {
    Ok(conn.query_row(
        "SELECT internet, relays, bluetooth FROM network WHERE id = 1",
        [],
        |r| {
            let relays: String = r.get(1)?;
            Ok(Settings {
                internet: r.get(0)?,
                relays: relays
                    .lines()
                    .filter(|l| !l.is_empty())
                    .map(str::to_owned)
                    .collect(),
                bluetooth: r.get(2)?,
            })
        },
    )?)
}

/// Grava, conferindo cada retransmissor (repetidos saem, a ordem fica).
pub fn set(conn: &Connection, settings: &Settings) -> CoreResult<Settings> {
    let mut relays: Vec<String> = Vec::new();
    for relay in &settings.relays {
        let relay = relay_url(relay)?;
        if !relays.contains(&relay) {
            relays.push(relay);
        }
    }
    if relays.len() > MAX_RELAYS {
        return Err(CoreError::InvalidRelay);
    }
    conn.execute(
        "UPDATE network SET internet = ?1, relays = ?2, bluetooth = ?3 WHERE id = 1",
        (settings.internet, relays.join("\n"), settings.bluetooth),
    )?;
    Ok(Settings {
        internet: settings.internet,
        relays,
        bluetooth: settings.bluetooth,
    })
}

/// Os endereços que os contatos receberam por último (para só mandar quando mudam).
pub fn announced(conn: &Connection) -> CoreResult<Vec<String>> {
    let text: String = conn.query_row("SELECT announced FROM network WHERE id = 1", [], |r| {
        r.get(0)
    })?;
    Ok(text.lines().map(str::to_owned).collect())
}

pub fn set_announced(conn: &Connection, addrs: &[String]) -> CoreResult<()> {
    conn.execute(
        "UPDATE network SET announced = ?1 WHERE id = 1",
        [addrs.join("\n")],
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
    fn starts_local_only() {
        let s = get(&conn()).unwrap();
        assert_eq!(s, Settings::default());
        assert!(s.relay_urls().is_empty());
    }

    #[test]
    fn keeps_the_relays_and_drops_repeats() {
        let conn = conn();
        let saved = set(
            &conn,
            &Settings {
                internet: true,
                relays: vec![
                    " https://relay.example.org ".into(),
                    "https://relay.example.org".into(),
                    "http://192.168.0.10:3340".into(),
                ],
                bluetooth: true,
            },
        )
        .unwrap();
        assert_eq!(saved.relays.len(), 2);
        assert_eq!(get(&conn).unwrap(), saved);
        assert_eq!(saved.relay_urls().len(), 2);
    }

    #[test]
    fn relays_only_count_with_the_internet_on() {
        let s = Settings {
            internet: false,
            relays: vec!["https://relay.example.org/".into()],
            ..Default::default()
        };
        assert!(s.relay_urls().is_empty());
    }

    #[test]
    fn strange_relays_are_refused() {
        for bad in [
            "",
            "relay.example.org",
            "ftp://relay.example.org",
            "https://user:pw@relay.example.org",
            "https://relay.example.org/?track=1",
            "https://relay.example.org/#x",
            "https://relay\n.example.org",
            &format!("https://{}.org", "a".repeat(250)),
        ] {
            assert_eq!(relay_url(bad), Err(CoreError::InvalidRelay), "{bad}");
        }
    }

    #[test]
    fn at_most_three_relays() {
        let relays = (0..4)
            .map(|i| format!("https://r{i}.example.org"))
            .collect();
        assert_eq!(
            set(
                &conn(),
                &Settings {
                    internet: true,
                    relays,
                    ..Default::default()
                }
            ),
            Err(CoreError::InvalidRelay)
        );
    }

    #[test]
    fn contact_addresses_are_cleaned() {
        let mut addrs: Vec<String> = (1..=10).map(|i| format!("10.0.0.{i}:1")).collect();
        addrs.push("https://relay.example.org".into());
        addrs.push("javascript:alert(1)".into());
        addrs.push("10.0.0.1:1".into());
        let clean = clean_addrs(addrs);
        assert_eq!(clean.len(), 9);
        assert_eq!(clean.last().unwrap(), "https://relay.example.org/");
    }

    #[test]
    fn remembers_what_was_announced() {
        let conn = conn();
        assert!(announced(&conn).unwrap().is_empty());
        let addrs = vec![
            "203.0.113.5:4000".to_owned(),
            "https://r.example.org/".into(),
        ];
        set_announced(&conn, &addrs).unwrap();
        assert_eq!(announced(&conn).unwrap(), addrs);
    }
}

//! O binário da caixa postal.
//!
//! ```text
//! chirp-mailbox run    [--data PASTA] [--port N] [--public IP:PORTA]... [--relay URL]
//!                      [--keep-days N] [--quota-mb N]
//! chirp-mailbox pair   [--data PASTA]     um código de ligação novo (24 horas)
//! chirp-mailbox status [--data PASTA]     os donos e o que cada um tem guardado
//! ```
//!
//! A pasta padrão é a `$STATE_DIRECTORY` do systemd, ou `~/.local/share/chirp-mailbox`.
//! Com o pacote, a do serviço é `/var/lib/chirp-mailbox`, e o `pair` roda com `sudo`:
//! o código fica com o dono da pasta, para o serviço poder usar e apagar.
//! Nada vai para o log além do que está aqui: nenhum id, endereço ou ficha. As
//! mensagens são em inglês, como os erros do núcleo.

use std::net::SocketAddr;
use std::path::PathBuf;
use std::process::ExitCode;

use chirp_mailbox::link::PairLink;
use chirp_mailbox::server::{self, Config, Server};
use chirp_mailbox::store::{self, Boxes, Limits};

const DEFAULT_PORT: u16 = 47474;

const USAGE: &str = "usage:
  chirp-mailbox run    [--data DIR] [--port N] [--public IP:PORT]... [--relay URL]
                       [--keep-days N] [--quota-mb N]
  chirp-mailbox pair   [--data DIR]     a new pairing code (one use, 24 hours)
  chirp-mailbox status [--data DIR]     the owners and what each one has waiting";

struct Args {
    command: String,
    data: PathBuf,
    port: u16,
    public: Vec<SocketAddr>,
    relay: Option<String>,
    limits: Limits,
}

fn default_data() -> PathBuf {
    if let Some(dir) = std::env::var_os("STATE_DIRECTORY") {
        return PathBuf::from(dir);
    }
    let home = std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_default();
    home.join(".local/share/chirp-mailbox")
}

fn parse(mut raw: impl Iterator<Item = String>) -> Result<Args, String> {
    let command = raw.next().ok_or("missing command")?;
    let mut args = Args {
        command,
        data: default_data(),
        port: DEFAULT_PORT,
        public: vec![],
        relay: None,
        limits: Limits::default(),
    };
    while let Some(flag) = raw.next() {
        let mut value = || raw.next().ok_or(format!("missing value for {flag}"));
        match flag.as_str() {
            "--data" => args.data = PathBuf::from(value()?),
            "--port" => args.port = value()?.parse().map_err(|_| "invalid port")?,
            "--public" => args
                .public
                .push(value()?.parse().map_err(|_| "invalid public address")?),
            "--relay" => args.relay = Some(value()?),
            "--keep-days" => {
                let days: u64 = value()?.parse().map_err(|_| "invalid number of days")?;
                args.limits.keep_secs = days.clamp(1, 365) * 24 * 60 * 60;
            }
            "--quota-mb" => {
                let mb: u64 = value()?.parse().map_err(|_| "invalid size")?;
                args.limits.bytes = mb.max(1) * 1024 * 1024;
            }
            _ => return Err(format!("unknown option: {flag}")),
        }
    }
    Ok(args)
}

fn main() -> ExitCode {
    let args = match parse(std::env::args().skip(1)) {
        Ok(args) => args,
        Err(error) => {
            eprintln!("{error}\n{USAGE}");
            return ExitCode::from(2);
        }
    };
    let runtime = match tokio::runtime::Runtime::new() {
        Ok(runtime) => runtime,
        Err(error) => {
            eprintln!("{error}");
            return ExitCode::FAILURE;
        }
    };
    let result = match args.command.as_str() {
        "run" => runtime.block_on(run(args)),
        "pair" => pair(&args),
        "status" => status(&args),
        _ => {
            eprintln!("{USAGE}");
            return ExitCode::from(2);
        }
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{error}");
            ExitCode::FAILURE
        }
    }
}

async fn run(args: Args) -> Result<(), String> {
    let relay = match &args.relay {
        Some(url) => Some(url.parse().map_err(|_| "invalid relay URL")?),
        None => None,
    };
    let server = Server::start(Config {
        dir: args.data.clone(),
        port: args.port,
        public: args.public.clone(),
        relay,
        limits: args.limits,
    })
    .await
    .map_err(|e| format!("could not start the mailbox: {e}"))?;
    // O relay responde em alguns segundos; os endereços ficam para o `pair`.
    let save = {
        let (server, data, public) = (server.clone(), args.data.clone(), args.public.clone());
        tokio::spawn(async move {
            loop {
                let mut lines: Vec<String> = server
                    .addrs(&public)
                    .iter()
                    .map(|a| a.to_string())
                    .collect();
                lines.extend(server.relay().map(|r| format!("relay={r}")));
                let _ = std::fs::write(data.join("addrs"), lines.join("\n"));
                tokio::time::sleep(std::time::Duration::from_secs(30)).await;
            }
        })
    };
    println!(
        "mailbox running on port {}; to link the app: chirp-mailbox pair",
        args.port
    );
    stopped().await;
    save.abort();
    server.close().await;
    Ok(())
}

fn pair(args: &Args) -> Result<(), String> {
    // Antes da chave: numa pasta errada, não cria uma caixa nova por engano.
    let saved = std::fs::read_to_string(args.data.join("addrs")).map_err(|_| {
        format!(
            "no mailbox has run in {}: start it with chirp-mailbox run, or pass --data",
            args.data.display()
        )
    })?;
    let key = server::secret_key(&args.data).map_err(|e| e.to_string())?;
    let mut addrs = Vec::new();
    let mut relay = None;
    for line in saved.lines() {
        if let Some(url) = line.strip_prefix("relay=") {
            relay = Some(url.to_owned());
        } else if let Ok(addr) = line.parse() {
            addrs.push(addr);
        }
    }
    let mut token = [0u8; 32];
    getrandom::fill(&mut token).map_err(|e| e.to_string())?;
    store::create_pairing(&args.data, token, server::now()).map_err(|e| e.to_string())?;
    match_owner(&args.data);
    let link = PairLink {
        endpoint_id: *key.public().as_bytes(),
        token,
        addrs,
        relay,
    }
    .to_link();
    if let Ok(code) = qrcode::QrCode::new(link.as_bytes()) {
        let qr = code
            .render::<qrcode::render::unicode::Dense1x2>()
            .quiet_zone(true)
            .build();
        println!("{qr}");
    }
    println!(
        "{link}\n\nIn Chirp: Your profile, Mailbox, paste the code and Link. It works once, for 24 hours."
    );
    Ok(())
}

/// Até o processo ser parado: Ctrl+C, ou o `SIGTERM` do systemd e do Docker.
async fn stopped() {
    #[cfg(unix)]
    {
        use tokio::signal::unix::{signal, SignalKind};
        if let Ok(mut term) = signal(SignalKind::terminate()) {
            tokio::select! {
                _ = tokio::signal::ctrl_c() => {}
                _ = term.recv() => {}
            }
            return;
        }
    }
    let _ = tokio::signal::ctrl_c().await;
}

/// O código novo fica com o dono da pasta (o usuário do serviço), quando quem roda o
/// `pair` é o administrador: o serviço lê e apaga o código quando ele é usado.
fn match_owner(data: &std::path::Path) {
    #[cfg(unix)]
    {
        use std::os::unix::fs::MetadataExt;
        let Ok(meta) = std::fs::metadata(data) else {
            return;
        };
        let pairing = data.join("pairing");
        let mut paths = vec![pairing.clone(), data.join("key")];
        if let Ok(entries) = std::fs::read_dir(&pairing) {
            paths.extend(entries.flatten().map(|e| e.path()));
        }
        for path in paths {
            let _ = std::os::unix::fs::chown(&path, Some(meta.uid()), Some(meta.gid()));
        }
    }
}

fn status(args: &Args) -> Result<(), String> {
    let boxes = Boxes::open(&args.data, args.limits).map_err(|e| e.to_string())?;
    let usage = boxes.usage();
    println!("{} owner(s)", usage.len());
    for (n, (items, bytes)) in usage.iter().enumerate() {
        println!(
            "  {}: {items} envelope(s), {} KiB",
            n + 1,
            bytes.div_ceil(1024)
        );
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn args(text: &str) -> Result<Args, String> {
        parse(text.split_whitespace().map(str::to_owned))
    }

    #[test]
    fn the_options_are_read() {
        let a =
            args("run --data /x --port 9 --public 1.2.3.4:9 --keep-days 999 --quota-mb 0").unwrap();
        assert_eq!(a.data, PathBuf::from("/x"));
        assert_eq!(a.port, 9);
        assert_eq!(a.public, vec!["1.2.3.4:9".parse().unwrap()]);
        assert_eq!(a.limits.keep_secs, 365 * 24 * 60 * 60);
        assert_eq!(a.limits.bytes, 1024 * 1024);
        assert!(args("run --port").is_err());
        assert!(args("run --what 1").is_err());
        assert!(args("").is_err());
    }
}

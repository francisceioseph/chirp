//! Um anfitrião de convite pela linha de comando, para testar entre aparelhos de
//! verdade (o app de um lado, isto do outro), sem mexer na tela:
//!
//!   cargo run --example invite_host -- <pasta>
//!
//! Cria um perfil "Linux" na pasta (com uma chave fixa: é só para teste), imprime um
//! link de convite e espera alguém usá-lo. Então mostra o contato e o número de
//! segurança, para comparar com o da outra tela, e passa a responder: cada texto que
//! chega é lido e volta como "eco: <texto>". "tchau" encerra.

use std::collections::HashSet;
use std::time::{Duration, Instant};

use chirp_core::api::store::{ChirpStore, MessageKind};

fn main() {
    let dir = std::env::args()
        .nth(1)
        .expect("diga a pasta: cargo run --example invite_host -- <pasta>");
    let store = ChirpStore::open_with_key(dir, vec![7; 32]).expect("open the store");
    if store.profile().expect("read the profile").is_none() {
        store
            .create_profile("Linux".into())
            .expect("create the profile");
    }
    let before = store.contacts().expect("contacts").len();
    println!("{}", store.create_invite(false).expect("create the invite"));
    let deadline = Instant::now() + Duration::from_secs(600);
    let contact = loop {
        if Instant::now() > deadline {
            eprintln!("ninguém usou o convite em 10 minutos");
            return;
        }
        std::thread::sleep(Duration::from_millis(500));
        let contacts = store.contacts().expect("contacts");
        if contacts.len() > before {
            break contacts.last().expect("one contact").clone();
        }
    };
    println!(
        "contato: {} (verificado: {})",
        contact.display_name, contact.verified
    );
    println!(
        "número de segurança: {}",
        store.safety_number(contact.id).expect("safety number")
    );

    let mut seen = HashSet::new();
    let mut statuses = std::collections::HashMap::new();
    let deadline = Instant::now() + Duration::from_secs(1800);
    while Instant::now() < deadline {
        std::thread::sleep(Duration::from_millis(500));
        let messages = store.messages(contact.id, None, 200).expect("messages");
        for m in &messages {
            if m.outgoing {
                if statuses.insert(m.id, m.status) != Some(m.status) {
                    println!("  minha {}: {:?}", m.id, m.status);
                }
                continue;
            }
            if !seen.insert(m.id) {
                continue;
            }
            match m.kind {
                MessageKind::Nudge => println!("chamou atenção"),
                MessageKind::Text => {
                    println!("recebida: {}", m.text);
                    if m.text.trim() == "tchau" {
                        let _ = store.mark_read(contact.id);
                        std::thread::sleep(Duration::from_secs(3));
                        return;
                    }
                    store
                        .send_text(contact.id, format!("eco: {}", m.text), Some(m.id))
                        .expect("reply");
                }
            }
        }
        let _ = store.mark_read(contact.id);
    }
}

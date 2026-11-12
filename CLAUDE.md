# Psito Chirp

Mensageiro privado, ponto a ponto e sem servidor, em Flutter com o núcleo em Rust, para Linux, Windows, macOS, Android e iOS. Projeto independente da suíte Psito (como o Psito Player sozinho), com instaladores próprios: não é um app do Psito OS.

O plano inteiro, com o diagnóstico do protótipo, as decisões de protocolo e o roteiro por fases, está em `docs/PLANO.md`. O protótipo antigo (PeerJS, RSA, Hive) ficou na tag `prototipo-2026`.

## Layout

- `core/`: o workspace Cargo.
  - `chirp-core/`: o núcleo (criptografia, rede, armazenamento), sem Flutter. O Flutter só fala com o módulo `api/`; o `frb_generated.rs` é gerado.
    - `store/`: o banco SQLCipher (`Store`) e as migrações pela `user_version`; uma migração publicada nunca muda, a mudança vira a próxima.
    - `identity.rs` (o par Curve25519 no formato do libsignal e a impressão digital), `profile.rs`, `passphrase.rs` (Argon2id, quando não há cofre), `random.rs` (só o `getrandom`) e `error.rs` (o `CoreError`, sem texto).
    - `session/`: a sessão pelo libsignal (as lojas sobre o banco, os convites com as prekeys deles e o aperto de mão BundleRequest, Bundle, Hello e Welcome, cada passo numa transação). `invite.rs` (o QR e o link), `wire.rs` (os frames e o conteúdo em Protobuf pelo `prost`, sem `.proto`), `contacts.rs` e `node.rs` (o endpoint do iroh: a rede local e, se ligados, a internet e o retransmissor escolhido, sem descoberta por servidor; uma conexão de um contato é de mensagens, a de qualquer outro é um aperto de mão; guarda por onde alcançou cada contato e manda os endereços novos pela sessão).
    - `discovery.rs`: o mDNS (`_chirp._udp`) com o token de época, sem nome nem id fixo; o nó anuncia e procura, e um contato achado ganha o endereço novo.
    - `network.rs`: a internet e os retransmissores (desligados por padrão), a conferência dos endereços que um contato manda e os últimos anunciados.
    - `appearance.rs`: a aparência (o id do tema, claro ou escuro, o vidro), no banco como o resto.
    - `messages.rs`: as mensagens, a caixa de saída (cifrada na mesma transação do ratchet, só sai com o `ack`) e a de entrada (idempotente), os recibos, o digitando, editar, apagar, reagir, chamar atenção e a busca (FTS5).
    - `api/store.rs`: o `ChirpStore` opaco, as funções do banco, a rede (`start_network`, `create_invite`, `add_contact`, `watch_events`), as mensagens (`conversations`, `messages`, `send_text` e o resto) e o runtime do tokio. Os arquivos ficam na pasta de suporte do app: `chirp.db` e, só com senha, `chirp.salt`.
  - O protocolo no fio está em `docs/PROTOCOLO.md`: mudou o formato, muda lá também.
- `rust_builder/`: o plugin que compila o núcleo dentro do `flutter build` (cargokit, gerado pelo `flutter_rust_bridge_codegen integrate`). Aponta para `core/chirp-core`.
- `flutter_rust_bridge.yaml`: de `crate::api` para `lib/src/bridge/`.
- `lib/`
  - `main.dart`: abre o núcleo (`BridgeCore.open`) e sobe o `ChirpApp`.
  - `chirp_app.dart`: o app, recebendo o `ChirpCore` e o `KeyVault` de fora, como o `PlayerView` do Player. Os testes passam falsos em memória (`FakeCore`, `FakeVault` e o `withProfile` do `test/helpers.dart`).
  - `src/core/chirp_core.dart`: a porta para o núcleo (`ChirpCore`, `ProfileStore`, `CoreFailure`) e a implementação pela ponte (`BridgeCore`). A UI nunca importa `src/bridge/`.
  - `src/platform/key_vault.dart`: o cofre do sistema (`KeyVault`, `SystemKeyVault` pelo `flutter_secure_storage`), onde fica a chave do banco. `system_accent.dart`: a cor de destaque do sistema (`dynamic_color`), que chega ao `ChirpApp` de fora, como o cofre.
  - `src/application/`: os controllers, sem widget. O `StartupController` é a máquina de estados da abertura (núcleo, cofre ou senha, perfil); o `ContactsController` liga a rede, cuida das conversas, dos contatos e dos convites e repassa os eventos do núcleo; o `ConversationController` é uma conversa aberta (as mensagens, responder, editar, o digitando, as chamadas de atenção que chegam); o `AppearanceController` é a aparência, a padrão até o banco abrir.
  - `src/bridge/`: o gerado pelo `flutter_rust_bridge`, e só ele.
  - `src/ui/`: atomic design (`atoms/`, `molecules/`, `organisms/`, `templates/`, `pages/`) e o `theme/`: os temas são sementes com personalidade (`chirp_themes.dart`, um `ChirpThemeSpec` cada), e o formato das bolhas vem do `ChirpStyle` (a `ThemeExtension`). A tela principal usa o `ShellTemplate`: uma coluna abaixo de 840 px (a conversa abre por cima, por rota), duas a partir dele e três a partir de 1200 px (o contato ao lado). Os testes rodam em 800×600, numa coluna.
  - `src/logging.dart`: a trava dos logs em release.
  - `l10n/`: os `.arb` e o gerado ao lado, no git.

## Comandos

- `flutter run -d linux`: o app, com o núcleo compilado pelo cargokit.
- No Linux, o `libsecret-1-dev` (o cofre) além do que o Flutter pede, e o `protobuf-compiler` (o `protoc`, que o libsignal pede para compilar).
- `flutter_rust_bridge_codegen generate`: depois de mudar `core/chirp-core/src/api/`. Instalado com `cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked` (a mesma versão do `flutter_rust_bridge` no `pubspec.yaml` e no `Cargo.toml`).
- `cd core && cargo test && cargo clippy --all-targets -- -D warnings && cargo fmt --all --check`
- `flutter analyze` e `flutter test -j 2` (o host tem pouca memória: não rode sem o `-j`). Mudou a UI de propósito: `flutter test test/golden_test.dart --update-goldens`, e olhe as imagens em `test/goldens/` antes de comitar.
- `flutter test integration_test -d linux`: o app de verdade (núcleo, SQLCipher e o cofre do sistema) numa pasta temporária e com uma entrada própria no cofre, sem tocar nos dados de quem usa, e dois bancos conversando pela ponte (`messages_test.dart`). Fora do CI, porque lá não há cofre nem tela.

## Regras

- Segurança e privacidade primeiro (`docs/PLANO.md`, seção 2): nada de criptografia caseira, nenhum servidor obrigatório, nenhuma chamada de rede que não seja a conversa. Nada de fonte, avatar, prévia ou verificação de versão buscados na web. O `privacy_test` recusa pacotes que chamam a rede e URLs no código.
- O que é segredo, rede ou disco fica no núcleo em Rust, não no Dart. Segredos com `zeroize`; `unsafe_code` é negado fora do código gerado. A exceção é a chave do banco, que passa pelo Dart a caminho do cofre do sistema. Nada de chave ou senha gravada em claro: sem cofre, pede-se uma senha.
- Campos de senha e de mensagem com `enableIMEPersonalizedLearning: false` e sem sugestões.
- Logs: no Dart, `debugPrint` atrás do `logging.dart` (em release, só com o ajuste ligado); no Rust, nada de log ligado por padrão. Nunca conteúdo, nome, id, chave ou endereço, nem em desenvolvimento.
- Widgets em atomic design (`lib/src/ui/`): o que aparece em mais de um lugar sobe de camada. Os papéis de cor, as formas e os componentes estão no `docs/DESIGN.md`.
- As cores vêm do `Theme.of(context).colorScheme`, sem `Colors.x` nem `Color(0x...)` fora do `theme/` (o `privacy_test` confere). Botão principal `FilledButton`, secundário o tonal, terciário `TextButton`.
- Nenhum texto que quem usa lê fica no código: vai para os `.arb`, nos sete idiomas (en, pt, es, fr, de, ru, zh). O `l10n_test` confere as chaves e os marcadores. Em português, um plural com `=1` tem também o `=0`; no russo, `one`, `few`, `many` e `other`.
- Sem emojis em texto fixo da UI.
- Todo clique tem nome para o leitor de tela (`Semantics(label:)` ou `Tooltip`), e tudo com clique tem caminho pelo teclado.
- A janela funciona até 240×160 no desktop, e num celular de 320×568.
- Os testes rodam em português (`test/flutter_test_config.dart`).
- Trabalhe na `master`; commit e push só quando pedidos.
- Versão pelo semantic-release (`.releaserc.json`, `tool/set-version.sh`, que grava no `pubspec.yaml` e no `Cargo.toml` do núcleo): `feat` sobe o minor, `fix` o patch e `BREAKING CHANGE` o major. A contagem parte da tag `v0.2.0`, para a 1.0 ser o fim da fase 6. O CI devolve à `master` o commit da versão, então rode `git pull --rebase` antes de cada push.

# Psito Chirp

Mensageiro privado, ponto a ponto e sem servidor, em Flutter com o núcleo em Rust, para Linux, Windows, macOS, Android e iOS. Projeto independente da suíte Psito (como o Psito Player sozinho), com instaladores próprios: não é um app do Psito OS.

O plano inteiro, com o diagnóstico do protótipo, as decisões de protocolo e o roteiro por fases, está em `docs/PLANO.md`. O protótipo antigo (PeerJS, RSA, Hive) ficou na tag `prototipo-2026`.

## Layout

- `core/`: o workspace Cargo.
  - `chirp-core/`: o núcleo (criptografia, rede, armazenamento), sem Flutter. O Flutter só fala com o módulo `api/`; o `frb_generated.rs` é gerado.
- `rust_builder/`: o plugin que compila o núcleo dentro do `flutter build` (cargokit, gerado pelo `flutter_rust_bridge_codegen integrate`). Aponta para `core/chirp-core`.
- `flutter_rust_bridge.yaml`: de `crate::api` para `lib/src/bridge/`.
- `lib/`
  - `main.dart`: abre o núcleo (`BridgeCore.open`) e sobe o `ChirpApp`.
  - `chirp_app.dart`: o app, recebendo o `ChirpCore` de fora, como o `PlayerView` do Player. Os testes passam um falso (`test/helpers.dart`).
  - `src/core/chirp_core.dart`: a porta para o núcleo (`ChirpCore`) e a implementação pela ponte (`BridgeCore`). A UI nunca importa `src/bridge/`.
  - `src/bridge/`: o gerado pelo `flutter_rust_bridge`, e só ele.
  - `src/ui/`: atomic design (`atoms/`, `molecules/`, `organisms/`, `templates/`, `pages/`) e o `theme/`.
  - `src/logging.dart`: a trava dos logs em release.
  - `l10n/`: os `.arb` e o gerado ao lado, no git.

## Comandos

- `flutter run -d linux`: o app, com o núcleo compilado pelo cargokit.
- `flutter_rust_bridge_codegen generate`: depois de mudar `core/chirp-core/src/api/`. Instalado com `cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked` (a mesma versão do `flutter_rust_bridge` no `pubspec.yaml` e no `Cargo.toml`).
- `cd core && cargo test && cargo clippy --all-targets -- -D warnings && cargo fmt --all --check`
- `flutter analyze` e `flutter test -j 2` (o host tem pouca memória: não rode sem o `-j`).

## Regras

- Segurança e privacidade primeiro (`docs/PLANO.md`, seção 2): nada de criptografia caseira, nenhum servidor obrigatório, nenhuma chamada de rede que não seja a conversa. Nada de fonte, avatar, prévia ou verificação de versão buscados na web. O `privacy_test` recusa pacotes que chamam a rede e URLs no código.
- O que é segredo, rede ou disco fica no núcleo em Rust, não no Dart. Segredos com `zeroize`; `unsafe_code` é negado fora do código gerado.
- Logs: no Dart, `debugPrint` atrás do `logging.dart` (em release, só com o ajuste ligado); no Rust, nada de log ligado por padrão. Nunca conteúdo, nome, id, chave ou endereço, nem em desenvolvimento.
- Widgets em atomic design (`lib/src/ui/`): o que aparece em mais de um lugar sobe de camada.
- As cores vêm do `Theme.of(context).colorScheme`, sem `Colors.x` nem `Color(0x...)` fora do `theme/` (o `privacy_test` confere). Botão principal `FilledButton`, secundário o tonal, terciário `TextButton`.
- Nenhum texto que quem usa lê fica no código: vai para os `.arb`, nos sete idiomas (en, pt, es, fr, de, ru, zh). O `l10n_test` confere as chaves e os marcadores. Em português, um plural com `=1` tem também o `=0`; no russo, `one`, `few`, `many` e `other`.
- Sem emojis em texto fixo da UI.
- Todo clique tem nome para o leitor de tela (`Semantics(label:)` ou `Tooltip`), e tudo com clique tem caminho pelo teclado.
- A janela funciona até 240×160 no desktop, e num celular de 320×568.
- Os testes rodam em português (`test/flutter_test_config.dart`).
- Trabalhe na `master`; commit e push só quando pedidos.
- Versão pelo semantic-release (`.releaserc.json`, `tool/set-version.sh`, que grava no `pubspec.yaml` e no `Cargo.toml` do núcleo): `feat` sobe o minor, `fix` o patch e `BREAKING CHANGE` o major. A contagem parte da tag `v0.2.0`, para a 1.0 ser o fim da fase 6. O CI devolve à `master` o commit da versão, então rode `git pull --rebase` antes de cada push.

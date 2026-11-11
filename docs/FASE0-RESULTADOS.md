# Fase 0: resultados

A fundação da reconstrução (`docs/PLANO.md`, seção 13).

## Feito

- O protótipo ficou na tag `prototipo-2026` (local; sobe com o próximo push de tags). O código antigo saiu da `master`: `lib/`, `test/`, `web/`, o `peerdart`, o `crypton`, o `encrypt`, o Hive, o `google_fonts`, o `shared_preferences`, o `get_it`, o `provider` e o `freezed`.
- Identificadores: `org.psito.chirp` no Android, iOS, macOS e Linux; o binário é `psito_chirp`, e o nome que aparece é "Psito Chirp". O pacote Dart é `psito_chirp`.
- Núcleo em Rust: workspace `core/` com o `chirp_core` (licença GPL-3.0-or-later no `Cargo.toml`), ligado pelo `flutter_rust_bridge` 2.13.0 com o cargokit (`rust_builder/`). A primeira API é o `core_info()` (versão do núcleo e do protocolo). O `setup_default_user_utils` da ponte não é chamado, porque liga log em nível `Trace`: fica só o backtrace em desenvolvimento.
- App: `ChirpApp` recebendo o `ChirpCore` de fora, `BridgeCore` que não derruba o app se a biblioteca nativa faltar, tema Material 3 pela semente Lutino, a tela de boas-vindas da fase, os sete idiomas e a trava de logs do Player.
- Testes: 24 no Flutter (boas-vindas, núcleo ausente, janela mínima nos dois temas, contraste e rótulos, os idiomas, privacidade e design) e 1 no Rust.
- CI (`.github/workflows/ci.yml`): o núcleo (fmt, clippy, testes), o app no Linux (análise, testes, build) e o build de Windows, macOS, Android e iOS, cada um com o app nos artefatos.
- `CLAUDE.md` e o `README.md` novos.

## Conferido

- `cargo test`, `cargo clippy -D warnings` e `cargo fmt --check` no `core/`.
- `flutter analyze` sem problemas e `flutter test -j 2` com os 24 passando.
- `flutter build linux --debug` compila o núcleo pelo cargokit e põe o `libchirp_core.so` no bundle; o app abre e mostra "Núcleo 0.2.0 · protocolo 1", vindo do Rust.

## Falta conferir

- Windows, macOS, Android e iOS: só o CI, depois do push. É o risco que a fase quer medir.
- O ícone do app nas plataformas ainda é o do protótipo; o novo vem com o canvas de design (fase 4).

## Decisões tomadas por padrão

As recomendações do plano valeram enquanto não houver outra escolha: núcleo em Rust e o nome Psito Chirp. A biblioteca do ratchet (`libsignal` ou `vodozemac`) e a da rede (iroh ou libp2p) só entram nas fases 1 e 2, e ainda podem mudar.

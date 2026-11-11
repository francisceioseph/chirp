# Fase 1: resultados

Identidade e armazenamento (`docs/PLANO.md`, seção 13).

## Feito

- **Banco cifrado** (`core/chirp-core/src/store/`): SQLCipher pelo `rusqlite` (`bundled-sqlcipher-vendored-openssl`), com a chave crua de 32 bytes, `cipher_memory_security`, `secure_delete` e `temp_store` em memória. Migrações pela `user_version` (`store/migrations.rs`), e um banco de versão mais nova é recusado (`NewerStore`) em vez de aberto pela metade.
- **Identidade** (`identity.rs`): um par Curve25519 do aparelho, gerado junto com o perfil e guardado só no banco. O formato é o da `IdentityKeyPair` do libsignal (32 bytes de segredo; a pública com o `0x05` na frente), para a sessão da fase 2 usar esta chave seja qual for a biblioteca do ratchet. A impressão digital é a metade de um número de segurança no formato do Signal (SHA-512 repetido 5200 vezes, 30 dígitos), com um vetor fixo no teste, calculado à parte.
- **Perfil** (`profile.rs`): nome com no máximo 64 caracteres, sem caracteres de controle nem os de direção de texto, e com versão (sobe a cada troca, para os contatos da fase 3).
- **Chave do banco**: 32 bytes do `getrandom`, guardados no cofre do sistema pelo `flutter_secure_storage` (`lib/src/platform/key_vault.dart`): Keychain no macOS e no iOS (`first_unlock_this_device`, fora do iCloud), Keystore no Android, Secret Service no Linux e o cofre de credenciais no Windows. Uma interface (`KeyVault`) e uma implementação que cobre as cinco, em vez de cinco implementações à mão. A escrita lê de volta para conferir.
- **Sem cofre, senha** (`passphrase.rs`): Argon2id com 64 MiB, 3 passadas e 1 faixa, e o sal (não secreto) em `chirp.salt` ao lado do banco. Mínimo de 8 caracteres. A senha e a chave saem da memória (`zeroize`) assim que o banco abre.
- **A ponte** (`api/store.rs`): `ChirpStore` opaco (o banco fica no Rust; o Dart só segura a alça), `store_state`, `new_store_key`, `wipe_store`. Os erros viram o `CoreFailure` do Dart, sem texto: a UI escolhe a mensagem.
- **A abertura** (`lib/src/application/startup_controller.dart`): uma máquina de estados (carregando, senha, cadastro, pronto, problema). Os problemas têm saída: o cofre que não respondeu pede para tentar de novo sem apagar nada; a chave perdida (o banco existe e a chave sumiu ou não abre) oferece apagar e começar de novo, com confirmação.
- **Telas** em atomic design: o avatar gerado pela chave (`atoms/identity_avatar.dart`, grade 5×5 espelhada nas cores do tema), o campo de senha (escondida, sem sugestões nem aprendizado do teclado), o campo do nome, a impressão digital em grupos, o cartão do perfil, os diálogos de apagar e de trocar o nome, e as páginas de senha, cadastro, perfil e problema sobre o `CenteredPanel`.
- Android com `allowBackup="false"`, para o banco e a chave não irem para o backup do Google.
- As mensagens novas nos sete idiomas.

## Conferido

- Rust: 25 testes, `clippy -D warnings` e `fmt`. A saída da fase é o `store::tests::the_file_has_no_plain_text`: cria o perfil, lê todos os arquivos da pasta e não acha o nome, o cabeçalho `SQLite format 3`, o esquema, nem pedaços da chave pública ou da chave do banco.
- Dart: 74 testes (a máquina de estados com núcleo e cofre falsos, cada caminho das telas, as quatro telas na janela mínima e num celular pequeno nos dois temas, com contraste e rótulos, e os sete idiomas), e o `flutter analyze` sem problemas.

- No Linux de verdade, o `integration_test/storage_test.dart` (`flutter test integration_test -d linux`): com o cofre do sistema (o keyring pelo libsecret), cria o perfil, reabre com a mesma impressão digital e só deixa o `chirp.db` na pasta, sem o nome nem o cabeçalho do SQLite; sem cofre, tranca com a senha, recusa a errada e abre com a certa, sem a senha nem o nome no disco. O app também abriu à mão e guardou a chave no keyring.
- As dependências do núcleo saem otimizadas também em debug (`[profile.dev.package."*"]`): sem isso, o Argon2 levava dezenas de segundos no `flutter run`.

- No Windows 10 (a VM do `tool/windows-vm.sh` do Player), com o build do CI: o app abre, a chave vai para o cofre do Windows (sem `chirp.salt`), o perfil é criado e volta igual ao reabrir, com a mesma impressão digital, e o `chirp.db` não tem o nome nem o cabeçalho do SQLite. Dois achados, já corrigidos: o bundle não trazia o runtime do Visual C++ (o app não abria num Windows limpo, `0xC0000135`; agora o CMake copia as DLLs do System32 de quem compila para o lado do executável), e a pasta dos dados era `Psito Chirp\Psito Chirp` (o `CompanyName` agora é `Psito`).

## Falta conferir

- O cofre no macOS: sem assinatura com um time, o Keychain pode recusar (`errSecMissingEntitlement`), e o Chirp cai para a senha. Funciona, mas o certo é assinar com o grupo do Keychain quando houver instalador.
- Android e iOS: o CI compila; abrir de verdade, ainda não.

## Decisões tomadas por padrão

- A biblioteca do ratchet continua em aberto (`libsignal` ou `vodozemac`, seção 14): a identidade foi feita sem nenhuma das duas, num formato que a primeira lê direto.
- O avatar sai da chave, e não de uma escolha: assim ele também ajuda a perceber uma chave trocada. Foto de perfil fica para a fase 4.

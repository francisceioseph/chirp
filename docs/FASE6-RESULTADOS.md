# Fase 6: arquivos, notificações e segundo plano → 1.0

O que a fase 6 do `docs/PLANO.md` (seção 13, com a 6.7 e a 9) pediu, o que foi feito e o que ficou. A fase vai em partes, uma por commit: os arquivos, depois as notificações e o segundo plano, depois os instaladores e os documentos da 1.0.

## Parte 1: arquivos

### Feito

- **Núcleo** (`files.rs`, migração 6):
  - fatias de 60 KiB cifradas com AES-256-GCM (uma chave por arquivo, o índice no nonce, o id do arquivo, o índice e "última" no AAD) e o BLAKE3 do arquivo inteiro;
  - o mesmo blob cifrado nos dois aparelhos, em `files/` ao lado do banco: o arquivo nunca fica em claro no disco, só a cópia que quem usa salva fora;
  - a oferta pela sessão (nome limpo, tamanho, tipo, miniatura, hash e chave), conferida ao chegar;
  - até 32 MiB baixa sozinho; acima, com o "Baixar";
  - as fotos (JPEG e PNG) perdem o EXIF (com a localização) antes de sair, com a rotação aplicada, e ganham a miniatura, tudo no aparelho; uma foto que não dá para limpar não sai;
  - apagar (para mim ou para todos, que agora vale para arquivos) tira o blob; o que sobra de um envio que caiu sai na próxima abertura; apagar tudo tira a pasta.
- **O nó** serve as fatias só ao contato a quem o arquivo foi oferecido, e quem baixa confere cada fatia ao chegar e retoma de onde parou.
- **App**:
  - o clipe no campo da conversa (o seletor do sistema, pelo `file_selector`);
  - o arquivo na bolha: a miniatura ou o ícone do tipo, o nome, o tamanho no formato do idioma, e o "Baixar", o progresso ("Esperando o contato" antes de começar), o "Salvar" (o "Salvar como" do sistema; no Android, a pasta), o "Tentar de novo" e a foto inteira por cima, com zoom;
  - na lista, "Arquivo: nome" como última mensagem;
  - 15 textos novos nos sete idiomas.

### Conferido

- Rust: 100 testes, `clippy -D warnings` e `fmt`. Os novos cobrem as bordas das fatias, a cópia fatia por fatia, as fatias trocadas, cortadas ou de outro arquivo, o blob adulterado, os nomes de fora, a foto com um EXIF com "GPS" (sai sem), as ofertas ruins e repetidas, e, sobre QUIC, o arquivo inteiro, a retomada e o pedido recusado.
- Dart: 208 testes. O `files_test`: anexar e desistir, o arquivo que não pode sair, esperar o contato, o progresso, salvar, o "Baixar" e o "Tentar de novo", a foto por cima, sem "Salvar" onde o sistema não deixa, a lista, e tudo em 240×160 e 320×568 nos dois temas, com contraste e rótulos.
- `integration_test/messages_test.dart`: um arquivo de três fatias vai de um banco ao outro pela ponte, baixa sozinho e a cópia salva é igual ao original.

### Revisão

- Os botões do arquivo usavam a cor primária sobre a bolha: na minha (`primaryContainer`), o contraste caía para 1,3 no escuro. Agora usam a cor do texto da bolha.
- A bolha escondia do leitor de tela tudo o que tinha dentro; num arquivo, os botões ficam visíveis.
- Uma recusa de arquivo era descartada no caminho (a conexão fechava antes de o outro lado ler); agora espera.
- Em 240×160, o aviso de alcance com o clipe não cabia: some da conversa nessa altura e continua nos detalhes do contato.

### Falta (dos arquivos)

- Notas de voz (gravar e tocar Opus).
- Escolher o limite do baixar sozinho, e "só de contatos verificados".
- Salvar no iOS (lá, o caminho é o "Compartilhar").
- O transporte mais rápido para arquivos é o que o iroh escolhe; o Bluetooth (fase 8) não leva arquivos grandes.

## Parte 2: notificações

### Feito

- **Núcleo** (`notifications.rs`, migração 7): o que as notificações mostram, no banco como os outros ajustes. São quatro modos: desligadas, sem conteúdo (só "Nova mensagem"), só o nome e nome e mensagem. O padrão é só o nome: o texto só sai do app para a tela do sistema, e para a tela bloqueada, se quem usa pedir.
- **App**:
  - o `Notifier` (`platform/notifier.dart`, pelo `flutter_local_notifications`), no mesmo molde do seletor de arquivos: o D-Bus no Linux, o Windows, o macOS, o Android (canal "Mensagens", com o texto escondido na tela bloqueada) e o iOS. Pede a permissão só com as notificações ligadas;
  - uma notificação por contato, a nova no lugar da anterior. Avisa o que chega com a conversa fora de vista, ou com o app sem foco. O clique abre a conversa, e ler, aqui ou em outro lugar, tira o aviso. O que já estava no banco ao abrir não avisa;
  - com o app sem foco, a conversa aberta não marca mais como lido o que chega (antes marcava, e mandava o recibo de leitura sem ninguém olhando). Marca quando o app volta à frente;
  - o cartão "Notificações" no perfil, com as quatro opções;
  - 12 textos novos nos sete idiomas.

### Conferido

- Rust: 103 testes (os novos: o padrão, o que foi escolhido e um código estranho), `clippy` e `fmt`.
- Dart: 217 testes. O `notifications_test` cobre os quatro modos, o que já estava no banco, a conversa aberta, o app sem foco e de volta, o clique e o ler, o cartão, e o tamanho em 240×160 e 320×568, com os rótulos.
- `integration_test/notifier_test.dart`: uma notificação de verdade no Linux, mostrada e tirada.

### Revisão

- No Linux, o plugin não tem o "o app abriu por uma notificação", e o erro derrubava a preparação inteira: nenhuma notificação aparecia. O teste de integração passava mesmo assim, porque o erro era engolido. Agora o `init` diz se deu certo, e o teste confere.

### Falta (das notificações)

- O que ficou para o segundo plano, na parte 3.

## Parte 3: segundo plano no desktop

### Feito

- **Núcleo** (migração 8): o "continuar recebendo com a janela fechada", ligado por padrão, ao lado do modo das notificações.
- **App** (`platform/desktop.dart`, pelo `nativeapi`, a base do `tray_manager` e do `window_manager`, usada direto):
  - o ícone na bandeja, com "Abrir o Psito Chirp" e "Sair". No Linux, é o StatusNotifierItem pelo D-Bus, sem o AppIndicator: nada a mais para instalar, e nada de GPL;
  - fechar a janela só esconde, e o nó continua recebendo; o "Sair" da bandeja sai de vez. Desligado, fechar sai, como antes;
  - abrir ao entrar no computador (o `.desktop` em `~/.config/autostart` no Linux, a chave `Run` no Windows, o `SMAppService` no macOS), já escondido, na bandeja. Se a abertura precisar de quem usa (a senha, o perfil novo, um problema), a janela aparece; sem a bandeja, também;
  - o clique na notificação traz a janela para a frente;
  - o cartão "Segundo plano" no perfil, só no desktop;
  - 7 textos novos nos sete idiomas.

### Conferido

- Rust: 104 testes, `clippy` e `fmt`.
- Dart: 228 testes. O `desktop_test`: a bandeja ao abrir com os textos do idioma, desligar e religar, abrir ao entrar (e sem o sistema deixar), o cartão só no desktop, começar escondido (e aparecer se a abertura precisar, ou sem a bandeja), a notificação que traz a janela, e o cartão em 240×160 e 320×568.
- `integration_test/desktop_test.dart`: no Linux de verdade, o ícone aparece no StatusNotifierWatcher da sessão, e a janela esconde e volta.

### Revisão

- O `tray_manager` e o `window_manager` novos são uma camada de compatibilidade (obsoleta) sobre o `nativeapi`; o app fala com o `nativeapi` direto. O `launch_at_startup` brigava com o `flutter_secure_storage` pela versão do `win32`, e o `nativeapi` já tem o abrir com o computador.
- Com a janela escondida não há quadros: um `pump` no teste esperava para sempre. O teste espera pelo relógio.

### Falta

- O Android, que veio na parte 4.
- O teste de abrir com o computador no sistema de verdade (grava na conta de quem testa).

## Parte 4: segundo plano no Android

### O desenho

Quando o Android fecha a tela do app, o motor do Flutter vai junto, e com ele o Dart que faz as notificações. As saídas eram três: o núcleo em Rust notificar sozinho (pelo JNI, com os textos dos sete idiomas levados para o núcleo), um segundo isolate no serviço (um segundo nó e uma segunda conexão ao banco, disputando a mesma identidade), ou manter vivo o motor que já existe. Ficou a terceira, como o Briar: nada da lógica muda, e é o mesmo código já testado.

### Feito

- **Kotlin**:
  - a `MainActivity` não é dona do motor: ele fica no `FlutterEngineCache`, e a tela se liga a ele ao abrir e o solta ao fechar (`shouldDestroyEngineWithHost` falso);
  - o `ReceiveService`, um serviço em primeiro plano do tipo `remoteMessaging` (o que o Android 14 pede para quem leva mensagens entre aparelhos), com uma notificação fixa de importância mínima, "Recebendo mensagens", que abre o app. Segura o processo, e o Dart continua com o nó, os eventos e as notificações com a tela fechada ou o app fora dos recentes;
  - o pedido para o Chirp ficar fora da economia de bateria, pelo sistema, e a pergunta se ele está dentro.
- **App**: o `Desktop` virou `Background` (`platform/background.dart`): o desktop, o Android (`AndroidBackground`, pelo canal `org.psito.chirp/background`) ou nada, no iOS. O mesmo "continuar recebendo" liga e desliga o serviço. O cartão "Segundo plano" aparece no Android, com o texto da notificação fixa e, só enquanto a economia de bateria segura o app, o "Deixar fora", que some quando quem usa volta dos ajustes do sistema com ele liberado. 5 textos novos nos sete idiomas.

### Conferido

- Dart: 233 testes. O `background_test` cobre também o Android: o texto da notificação fixa, sem o abrir ao entrar, o pedido da bateria (e ele sumir ao voltar liberado), nada de bateria com o segundo plano desligado, e o cartão em 240×160 e 320×568 com o pedido aberto.
- O Kotlin só é compilado no CI: o emulador não cabe na memória deste computador. O teste de verdade (fechar a tela, tirar dos recentes, receber) é num celular.

### Revisão

- O canal do Kotlin vive no motor, que dura mais que a tela: o pedido da bateria usa o contexto do app, não a tela que criou o canal.

### Falta

- Se o sistema matar o processo (falta de memória, reiniciar o celular), o serviço não volta sozinho (`START_NOT_STICKY`): sem a tela, o Dart não teria por onde fazer a abertura. Volta ao abrir o app. Abrir com o celular pediria a abertura sem tela.
- O ícone da notificação fixa é o do app; o Android pede um monocromático para a barra.

## Parte 5: instaladores, repositórios e os documentos da 1.0

### Feito

- **Versão**: o `set-version.sh` grava também o versionCode do Android depois do `+` (1.2.3 vira 1002003), porque o Android só instala por cima um número maior. O `release` do CI diz a tag nova, e o `packages.yml` roda com ela.
- **Linux**:
  - o pacote `psito-chirp` em `.deb` e `.rpm`, com o binário em `/usr/lib/psito-chirp/`, o `/usr/bin/psito-chirp`, o `.desktop` e o AppStream (`linux/packaging/`), o ícone e os documentos;
  - as dependências à mão: o GTK, a GLib 2.80, a glibc 2.38, o libsecret, o EGL e o GLES. O SQLCipher e o OpenSSL já vão no núcleo;
  - o AUR (`build-aur.sh`) gera o `PKGBUILD` a partir do `.deb` da release, e quem envia é quem mantém;
  - com a chave `APT_SIGNING_KEY`, os repositórios APT e DNF assinados, com as três últimas versões, no GitHub Pages, junto da página.
- **Windows**: o instalador do Inno Setup.
  - Por padrão, só para quem usa e sem administrador, e o Windows pergunta sobre a rede na primeira vez.
  - Para todos, com a regra do firewall para a rede local (redes privadas e de domínio).
  - Desinstalar fecha o Chirp da bandeja e tira a regra e o "abrir ao entrar". As conversas ficam: para apagar, há o "Apagar tudo".
- **Android**:
  - o APK assinado com a chave das versões (`ANDROID_KEYSTORE`, que sai do `create-android-key.sh`). Sem ela, o CI não publica o APK: um APK com a chave de depuração impediria as atualizações depois;
  - os textos e o ícone do F-Droid em `fastlane/metadata/android/`.
- **macOS**: o `.dmg` sem a assinatura da Apple, como build de teste. O iOS continua só pelo Xcode.
- **As somas**: o `SHA256SUMS` de tudo o que a release tem, assinado com a chave dos repositórios.
- **Documentos**:
  - o `SECURITY.md`, para relatar uma falha pelo relato privado do GitHub;
  - o `docs/AMEACAS.md`, o modelo de ameaças do que vale hoje, conferido com o código. O bloqueio de contatos e o aviso de chave trocada estavam no plano mas não no código, e foram para "ainda não feito";
  - a página do projeto (`site/`), nos sete idiomas, com a instalação de cada sistema e o que o Chirp protege e o que não.
- **CI**: o job `app` monta o `.deb` e o `.rpm` e valida o `.desktop` e o AppStream a cada push, para um arquivo que falta não aparecer só na versão.

### Conferido

- O `.deb` montado aqui tem o que deve, e o `desktop-file-validate` e o `appstreamcli validate` passam.
- A página, em 375 px de largura, cabe sem rolar para o lado, e as chaves dos sete idiomas são as mesmas da página.
- O `.rpm`, o instalador, o APK assinado e o `.dmg` só são montados no CI.

### Falta

- **Ações de quem é dono do repositório**:
  - rodar o `tool/create-apt-key.sh` e o `tool/create-android-key.sh`;
  - ligar o GitHub Pages com a origem "GitHub Actions";
  - ligar o relato privado de vulnerabilidades.
- O F-Droid: pedir a inclusão no `fdroiddata`, com o build reprodutível. O AppImage e o Flatpak ficam para depois.

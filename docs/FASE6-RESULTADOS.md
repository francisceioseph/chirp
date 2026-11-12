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

### Falta (das notificações e do segundo plano)

- No desktop, o clique abre a conversa, mas não traz a janela para a frente.
- A bandeja no desktop, iniciar com o sistema e o serviço em primeiro plano no Android, para receber com a janela fechada.

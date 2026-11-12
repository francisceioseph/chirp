# Fase 7: caixa postal

O que a fase 7 do `docs/PLANO.md` (seção 13, com a 7.6) pediu, o que foi feito e o que ficou. A fase vai em duas partes: a caixa para os contatos de agora, e depois o primeiro contato por ela (as prekeys publicadas).

A saída pedida: mandar mensagem a quem está offline e ela chegar quando a pessoa abrir o app.

## Parte 1: a caixa para os contatos de agora

### Feito

- **A caixa** (`core/chirp-mailbox`, o `chirp_mailbox`), um crate novo no workspace:
  - o protocolo (ALPN `chirp-mailbox/1`, frames em Protobuf como os do Chirp) e o código de ligação (`chirp://mailbox#`, o mesmo formato de endereços do convite), numa biblioteca que o núcleo usa sem o servidor;
  - a pasta da caixa: um arquivo por envelope, gravado por cima de um temporário; os códigos de ligação só como SHA-256, de uso único e por 24 horas; as fichas de cada dono só como SHA-256; os limites (20 mil envelopes e 256 MiB no total, 2 mil por ficha, 30 dias);
  - o servidor no iroh, sem descoberta por servidor: ligar e depositar abertos, as fichas, buscar, apagar e desligar só para o dono, autenticado pelo QUIC;
  - o binário: `run` (porta 47474, `--public`, `--relay`, `--keep-days`, `--quota-mb`; para com o `SIGTERM` do systemd e do Docker), `pair` (o QR no terminal e o link; o código fica com o dono da pasta, para o serviço poder usar) e `status` (só contagens).
- **Núcleo** (`mailbox.rs`, migração 10):
  - cada contato ganha uma ficha própria pela sessão, num `MailboxInfo` (conteúdo 17), uma vez por caixa; desligar manda um vazio;
  - quem não atende e tem caixa recebe nela a caixa de saída, na ordem, e a mensagem fica "na caixa postal";
  - a caixa deste aparelho é lida ao ligar, a cada 60 segundos e quando um contato novo chega; cada envelope é aberto pela sessão do contato da ficha, e o que não decifra é jogado fora. O "entregue" volta pelo `Receipt.delivered`, mesmo com os recibos de leitura desligados;
  - na API, `mailbox`, `pair_mailbox` e `unpair_mailbox`, e o `in_mailbox` da mensagem; dois erros novos (o código que não se lê, o código recusado).
- **App**:
  - o cartão "Caixa postal" no perfil: o que ela vê, colar o código, ligar, o estado (lida por último, ou sem resposta) e desligar, perguntando antes;
  - a caixa de correio no lugar do relógio, na bolha e na lista, para a mensagem que espera na caixa do contato, com o nome para o leitor de tela;
  - 16 textos novos nos sete idiomas.
- **Distribuição**:
  - o pacote `chirp-mailbox` (`tool/build-mailbox-deb.sh`): o binário e a unidade do systemd, ligada na instalação, com usuário dinâmico e o sistema só de leitura para ela; o `purge` apaga a pasta;
  - a imagem de contêiner (`core/chirp-mailbox/Dockerfile`, usuário sem privilégio, a pasta em `/data`), publicada pelo CI em `ghcr.io/<dono>/chirp-mailbox`;
  - o `.deb` sai junto com os outros pacotes da versão e entra no repositório APT; o `set-version.sh` dá a versão à caixa também.
- **Documentos**: o protocolo da caixa no `PROTOCOLO.md`, o que ela vê no `AMEACAS.md`, e o `CAIXA-POSTAL.md` para quem vai instalar.

### Conferido

- Rust: 129 testes (118 do núcleo, 11 da caixa), `clippy -D warnings` e `fmt`. Os novos: os frames e o link em cada corte; a pasta da caixa; sobre QUIC, ligar, depositar e só o dono buscar; a caixa chegando aos contatos uma vez e o desligar; um `MailboxInfo` estranho ignorado; e, de ponta a ponta com uma caixa de verdade, Alice manda a Bob desligado, a mensagem fica "na caixa postal", Bob volta, busca e o "entregue" chega a Alice. O código de ligação não serve duas vezes.
- Dart: 260 testes. O `mailbox_test` cobre o código errado, o recusado, o certo, o desligar com e sem confirmar, a caixa sem resposta, o ícone e o nome da mensagem na caixa, e o cartão em 240×160 e 320×568.
- O pacote montado (`dpkg-deb -I` e `-c`), e o binário: `run`, `pair`, `status` e o fim pelo `SIGTERM`. A imagem compila e roda.

### Revisão

- O `pair` lia a chave antes de ver se a caixa já tinha rodado: numa pasta errada, criava uma caixa nova sem querer. Agora recusa, dizendo onde procurou.
- Rodado com `sudo`, o `pair` deixava o código com o dono `root`, e o serviço (outro usuário) não conseguiria apagar ao usar. Agora o código fica com o dono da pasta.
- O `run` só parava com o Ctrl+C; o `SIGTERM` do systemd e do Docker o matava sem fechar o endpoint.
- O teste da troca de nome pegava "o único campo de texto" da tela, e o do código da caixa virou o segundo.

### Falta (da parte 1)

- Ler o código da caixa pelo QR no celular (hoje é colar o link).
- A caixa não avisa o app de que os endereços dela mudaram: com um IP novo, é preciso ligar de novo com outro código (ou usar `--public` e um retransmissor).
- Desligar a caixa com a rede do app desligada não avisa a caixa, só os contatos; o que estava guardado sai no prazo dela.
- Os arquivos continuam pedindo os dois online: a caixa leva a oferta, não as fatias.
- O pedido do `PLANO.md` de uma caixa de um amigo (um contato guardando para outro).

## Parte 2: o primeiro contato pela caixa

A fazer: a caixa publica as prekeys PQXDH do dono, e quem tem só o link do convite manda a primeira mensagem sem os dois estarem online.

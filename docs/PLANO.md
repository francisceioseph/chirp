# Psito Chirp: plano de reconstrução

Mensageiro privado, ponto a ponto e sem servidor, para Linux, Windows, macOS, Android e iOS. Projeto independente da suíte Psito, com instaladores próprios (como o Psito Player sozinho), e não um app do Psito OS.

Este documento tem quatro partes: o diagnóstico do código de hoje, as decisões (protocolo, criptografia, transportes, arquitetura e UI), o roteiro por fases e os riscos.

---

## 0. Resumo

- **O que existe**: um protótipo bem organizado na intenção (domínio, casos de uso, portas e adaptadores, atomic design, 14 temas), mas a criptografia e a rede **não entregam o que o app promete**. Hoje uma pessoa na mesma rede consegue virar "amiga" sem pedir, se passar por outra e ler o tráfego futuro se roubar uma chave. A rede depende de um servidor de terceiros (o do PeerJS), e o app vaza nomes para a DiceBear e o IP para o Google Fonts.
- **Recomendação central**: reescrever o núcleo (criptografia, rede, armazenamento) em **Rust**, ligado ao Flutter pelo `flutter_rust_bridge` (o mesmo que o Player já carrega pelo `smtc_windows`), e manter o Flutter só para a UI. Aproveitar o que dá da UI e do domínio, e jogar fora o `peerdart`, o `crypton`, o `encrypt` e o Hive.
- **Signal vale?** Vale, **na camada das mensagens**: o Double Ratchet (com a extensão pós-quântica do Signal) é o melhor que existe para sigilo futuro e recuperação depois de um vazamento. Mas o "protocolo Signal" inteiro pressupõe um servidor que guarda as prekeys e entrega as mensagens; aqui o primeiro aperto de mão acontece frente a frente (QR) ou ao vivo, e o servidor vira, no máximo, uma caixa postal opcional. Detalhes na seção 4.
- **Transportes**: rede local (mDNS e QUIC), internet (QUIC com furo de NAT e retransmissor opcional, sem guardar nada), Bluetooth LE e, mais tarde, Wi-Fi Direct (Android) e Tor. Todos levam o mesmo envelope já cifrado: o transporte nunca é a camada de segurança.
- **UI**: Material 3 com `ColorScheme.fromSeed`, os temas de hoje viram "sementes" com personalidade (Lutino, Skylight, Old Days...), atomic design no mesmo molde do Player, 7 idiomas, acessibilidade testada, sem `Colors.x` nos widgets. O desenho passa antes por um canvas no Claude Design, como o do Player.
- **Fases**: 0 (fundação) a 12 (auditoria e 1.0), com o 1:1 seguro na rede local primeiro, e grupos, arquivos grandes, chamadas e Bluetooth depois.

---

## 1. Diagnóstico do código atual

Referência: `master` em `4c29502` (jun/2026), cerca de 6.700 linhas de Dart fora o gerado.

### 1.1 O que está bom e fica

- A **intenção da arquitetura**: `domain/` (entidades, casos de uso, portas), `infrastructure/` (adaptadores, repositórios, serviços) e `app/` (controllers e widgets). É o esqueleto certo, só a regra de dependência que vaza (1.4).
- Os **casos de uso pequenos e com nome de verbo** (`RequestFriendshipUseCase`, `SendChirpUseCase`...). O formato fica; o conteúdo muda.
- O **`sealed class ChirpPacket`** com `switch` exaustivo: bom padrão para o protocolo, que volta como mensagens Protobuf no núcleo (seção 6.6), mas com a mesma ideia.
- O **atomic design** já começado (`atoms/`, `molecules/`, `organisms/`, `templates/`), e o layout desktop e celular separados (`desktop_home_template.dart`, `mobile_home_template.dart`).
- A **identidade visual e o vocabulário** das calopsitas (bando, ninho, pio). Ficam na marca e nos textos; no código, os nomes passam a dizer o que as coisas são (seção 11.5).
- Os **testes de domínio** que existem (`test/domain/`), como ponto de partida.

### 1.2 Falhas críticas de segurança

| # | Onde | Problema | Consequência |
|---|---|---|---|
| S1 | `complete_handshake_use_case.dart:20,25` | Um `ChirpAcceptPacket` que chega **sem ter havido pedido** cria ou promove o contato a `connected` com a chave pública que veio no pacote. | Qualquer um vira "amigo" de qualquer um sem consentimento, e pode **trocar a chave de um amigo existente** pela dele (o `copyWith(publicKey: ...)` sobrescreve). A partir daí lê tudo que a vítima mandar àquele contato. |
| S2 | `chirp_packet.dart` (todos) | `fromId` e `fromName` vão em claro e **sem assinatura**; nada liga o envelope a quem mandou. | Qualquer um manda mensagens "como" outra pessoa. O `senderId` e o `author` de dentro do JSON cifrado também são escolhidos por quem envia. |
| S3 | `request_friendship_use_case.dart`, `confirm_friendship_use_case.dart` | A chave pública trafega em claro no pedido e no aceite, sem verificação (sem QR, sem número de segurança). | Um intermediário (o servidor do PeerJS, alguém na rede local) troca as chaves das duas pontas: ataque *man-in-the-middle* clássico, invisível para as duas pessoas. |
| S4 | `secure_chirp.dart:18,34` | `enc.AES(aesKey)` usa o modo padrão do pacote `encrypt`, que é o **SIC/CTR sem autenticação** (e com PKCS7 por cima, sem necessidade). | O texto cifrado é maleável: dá para inverter bits do conteúdo sem a chave. Não há MAC nem AEAD. |
| S5 | `secure_chirp.dart` | RSA estático por pessoa, chave AES nova por mensagem cifrada com o RSA. | **Sem sigilo futuro (forward secrecy)**: quem grava o tráfego hoje e rouba a chave privada amanhã lê tudo, para trás e para frente. Sem recuperação depois de um vazamento. |
| S6 | `identity_service.dart:34` | A **chave privada RSA fica no `SharedPreferences`**, em texto puro (no Linux, um JSON em `~/.local/share`; no Android, um XML legível com root ou backup). | Qualquer processo do usuário, backup ou cópia do disco leva a identidade. |
| S7 | `flock_manager.dart:26` | `Peer(id: identity.id)` sem servidor próprio usa o **servidor de sinalização público do PeerJS** (e STUN de terceiros), conforme o padrão do PeerJS. *Confirmar no código do `peerdart` instalado.* | Não é descentralizado: um terceiro vê quem fala com quem, os IPs e os horários, pode negar o serviço e é o intermediário ideal para o S3. Sem internet, não funciona nem na rede local. |
| S8 | `chirp_packet.dart`, recepção | Sem número de sequência, sem nonce de mensagem, sem janela de tempo. | Repetição (*replay*) de pacotes antigos é aceita. |
| S9 | Recepção em geral | Nenhum limite de tamanho, de taxa ou de pedidos pendentes; JSON de qualquer tamanho é decodificado. | Negação de serviço trivial na rede local (lista de pedidos infinita, pacotes gigantes). |

### 1.3 Privacidade e "sem logs, sem telemetria"

| # | Onde | Problema |
|---|---|---|
| P1 | `tiel.dart:25`, `conversation.dart:28-29`, `chirp_member.dart:19`, `profile_screen.dart:15`, `chirp_qr_screen.dart:23`, `chirp_user_control_tile.dart:40` | Avatares da `api.dicebear.com` com `seed=<nome>`: **manda o nome de cada contato a um terceiro**, junto com o IP. É telemetria involuntária. |
| P2 | `chirp_theme_base.dart` e mais 18 arquivos | `GoogleFonts` baixa as fontes do Google em tempo de execução: o Google vê o IP e quando o app abre. |
| P3 | `flock_discovery.dart:21,41` | A cada 10 s, um broadcast UDP em claro com o **id fixo e o nome do aparelho** (que vem do `device_info_plus`: "iPhone de Fulano"). | Rastreável em qualquer rede: o id nunca muda. |
| P4 | `app_logger.dart` e todos os `log.*` | Logs com nomes, ids e eventos de conversa, também em release. |
| P5 | `secure_nest_hive_adapter.dart` | O Hive cifra os valores, mas as **chaves das caixas (ids de contato, de conversa, de mensagem) e os nomes das caixas ficam em claro** no disco, e o tamanho de cada registro aparece. |

### 1.4 Bugs e arquitetura

- **B1** `identity_service.dart:23`: grava o `id` no lugar do nome (`setString(_keyName, id)`), então o nome se perde no segundo uso.
- **B2** `send_chirp_use_case.dart:58` + `receive_chirp_use_case.dart:23`: a mensagem vai serializada com `isFromMe: true`, e quem recebe guarda como veio. **Toda mensagem recebida aparece como se fosse minha.**
- **B3** A descoberta (UDP, com o endereço IP) e o transporte (PeerJS, pelo id) não se falam: o `address` que a descoberta acha nunca é usado para conectar.
- **B4** `CompleteHandshake` cria contato com `address: "0.0.0.0"`; `UpdateTielsStatus` usa 120 s e o README diz 15 s.
- **B5** `ChirpController` é `registerFactory` no GetIt e vive dentro de um `ChangeNotifierProvider`; controllers ficam ao mesmo tempo no GetIt e no Provider.
- **B6** Ofertas de arquivo: enviadas, mas a recepção é `log.w("not implemented")`.
- **A1 Regra de dependência quebrada**: 10 arquivos de `domain/` importam `infrastructure/` (`TielNestRepository` concreto, `SecureChirp` estático, `FlockManager`), e 2 entidades importam Flutter (`tiel.dart` com `Color`, `chirp_theme.dart`). O domínio não é testável sem a infraestrutura.
- **A2** Repositórios estendem `ChangeNotifier` (a infraestrutura depende do Flutter e faz papel de estado da UI).
- **A3** `DateTime.now()` espalhado, sem relógio injetável: testes de presença e de ordem ficam impossíveis.
- **A4** Hive 1.x está sem manutenção desde 2022.

### 1.5 UI

- 14 arquivos de tema escritos à mão, cada um com suas cores; **33 arquivos de widget com `Colors.x` ou `Color(0x...)`**.
- Glassmorphism com `BackdropFilter` de 35 px em painéis e gaveta: caro em GPU fraca, celular antigo e máquina virtual sem aceleração, e ruim de contraste.
- Textos em português direto no código (`Text("...")`, `statusText` do `Tiel`), sem `gen-l10n`.
- Sem `Semantics` nem `Tooltip` sistemáticos; nada testado para leitor de tela ou teclado.
- Emojis na UI e nos logs.

### 1.6 Testes e CI

- Só testes de modelos e entidades; nenhum de criptografia, rede, casos de uso ou widgets.
- O CI pede o `CODECOV_TOKEN` e o `dart format` estrito, mas não compila para nenhuma plataforma.

**Conclusão**: a casca (domínio, casos de uso, UI organizada) aproveita; o miolo de segurança precisa ser refeito do zero, e isso é normal para um protótipo. A seção 13 diz o que é migrado e o que é descartado, arquivo por arquivo.

---

## 2. Princípios

1. **Seguro desde a primeira interação.** Não existe estado "conectado mas sem chave verificada que se comporta como verificado". O primeiro contato já é autenticado e com sigilo futuro.
2. **Sem servidor obrigatório.** Duas pessoas na mesma rede, no mesmo Bluetooth ou com IP alcançável conversam sem nenhum terceiro. Tudo que é servidor (retransmissor, caixa postal) é opcional, trocável, auto-hospedável e **não consegue ler nada**.
3. **Sem conta, sem telefone, sem e-mail.** A identidade é um par de chaves gerado no aparelho.
4. **Sem logs, sem telemetria, sem chamadas de rede que não sejam a conversa.** Nenhum recurso remoto (fonte, avatar, prévia de link, verificação de versão) sem o usuário pedir. Logs só com a opção "Registrar logs" ligada, como no Player, e mesmo assim sem conteúdo nem identificadores.
5. **Mínimo de metadados.** O que trafega em claro não identifica ninguém para quem não é contato. Nomes e fotos só vão cifrados, e só para contatos.
6. **Nada de criptografia caseira.** Só primitivas e protocolos padronizados, de bibliotecas auditadas. O que for nosso (o formato do envelope, a descoberta) é especificado num documento e testado com vetores.
7. **Fácil como o MSN.** Segurança que exige ler um manual não protege ninguém: adicionar contato é mostrar um QR ou tocar em quem está por perto, e o resto é automático. A verificação é um gesto, não uma configuração.
8. **Funciona offline e em rede ruim.** Mensagens ficam numa fila e saem quando der, por qualquer transporte.

---

## 3. Modelo de ameaças

### 3.1 Contra quem protegemos

| Adversário | Capacidade | Defesa |
|---|---|---|
| Alguém na mesma rede local (café, faculdade) | Vê, injeta, repete e derruba pacotes | Canal autenticado (QUIC/TLS com chave do nó, ou Noise), envelope com Double Ratchet, descoberta com identificadores rotativos |
| Provedor de internet, Estado, operador de retransmissor | Vê IPs, horários e tamanhos; pode bloquear | Conteúdo cifrado de ponta a ponta, preenchimento de tamanho, retransmissor que não guarda nada, Tor opcional para esconder o IP |
| Quem grava tudo hoje para decifrar com computador quântico amanhã | "Colher agora, decifrar depois" | Acordo de chaves híbrido X25519 + ML-KEM-768 (PQXDH) e ratchet com ML-KEM (SPQR) |
| Quem rouba as chaves de um aparelho por um tempo | Lê o estado da sessão | Sigilo futuro (o passado não é lido) e recuperação pós-comprometimento (o futuro volta a ser seguro depois de alguns turnos) |
| Quem pega o aparelho desbloqueado ou a cópia do disco | Lê os arquivos do app | Banco cifrado (SQLCipher) com chave no cofre do sistema, senha do app opcional, mensagens que somem, apagar tudo |
| Contato mal-intencionado | Recebe o que mandamos a ele | Não protegemos o conteúdo que mandamos a quem escolhemos; protegemos contra ele se passar por outro e contra abuso (bloquear, limites) |
| Estranho por perto | Manda pedidos em massa | Pedidos só com o QR ou com o modo "visível para estranhos" ligado, e limite de taxa |

### 3.2 Fora do escopo (declarado na página e no app)

- Aparelho com malware ou root do adversário.
- Esconder **que** você usa o Chirp de quem observa a rede local (sem Tor, o tráfego tem cara de QUIC e de mDNS).
- Anonimato forte contra quem observa a internet inteira (o Tor ajuda, não resolve).
- Captura de tela pelo outro lado.

---

## 4. O protocolo Signal vale aqui?

### 4.1 O que é o "protocolo Signal"

São peças separadas:

1. **X3DH / PQXDH**: o acordo de chaves inicial **assíncrono**. Bob publica *prekeys* num servidor; Alice baixa e já manda a primeira mensagem com Bob offline. O PQXDH (2023) junta o X25519 com o ML-KEM (Kyber), contra computador quântico.
2. **Double Ratchet**: cada mensagem usa uma chave nova (ratchet simétrico), e cada troca de turno faz um novo Diffie-Hellman (ratchet assimétrico). Dá **sigilo futuro** e **recuperação pós-comprometimento**.
3. **SPQR / Triple Ratchet** (2025): um ratchet de ML-KEM entrelaçado ao Double Ratchet, para a recuperação também ser pós-quântica.
4. **Sesame**: a gestão de sessões entre vários aparelhos.
5. **Sender Keys**: grupos, com uma cadeia por remetente distribuída pelos canais 1:1.
6. Coisas do serviço Signal (Sealed Sender, servidor de prekeys, contatos por telefone), que **não se aplicam aqui**.

### 4.2 Veredito

- **Double Ratchet + PQXDH (+ SPQR)**: **sim**. É o padrão de fato da indústria (Signal, WhatsApp, Google Messages, a base do Olm do Matrix), estudado à exaustão, e dá exatamente o que o Chirp promete. Não existe nada melhor para conversa 1:1.
- **O modelo de servidor do Signal**: **não**. No P2P, o primeiro contato é síncrono (frente a frente ou os dois online), então a parte "assíncrona" do X3DH/PQXDH é dispensável no começo. As prekeys voltam só para a **caixa postal** (seção 7.6), quando Alice quer mandar a primeira mensagem a quem está offline.
- **Grupos**: começar com **Sender Keys** (vem na mesma biblioteca, funciona sem servidor, bom até dezenas de pessoas). O **MLS** (RFC 9420, OpenMLS) é melhor para grupos grandes, mas precisa de alguém que ordene os *commits*; sem servidor, commits simultâneos conflitam. Fica como avaliação na fase de grupos (seção 6.8).

### 4.3 Qual biblioteca

| Opção | Linguagem / licença | Prós | Contras |
|---|---|---|---|
| **`libsignal`** (do Signal, crate `libsignal-protocol`) | Rust, **AGPL-3.0** | A implementação de referência, com PQXDH, SPQR e Sender Keys; mantida pelo próprio Signal; em produção para centenas de milhões | Não é publicada no crates.io (dependência por tag do git); API pensada para o servidor deles, muda sem aviso; AGPL |
| `vodozemac` (Matrix) | Rust, Apache-2.0 | Olm (Double Ratchet) e Megolm (grupos), auditada (Least Authority, 2022), API estável e simples | **Sem pós-quântico** hoje; Megolm não tem recuperação pós-comprometimento em grupo |
| OpenMLS | Rust, MIT | Padrão IETF, grupos grandes, suítes PQ chegando | Ordem dos commits sem servidor; mais complexo para 1:1 |
| Dart puro (`cryptography` + implementação própria do ratchet) | Dart | Sem ponte nativa | **Não recomendado**: nenhuma implementação auditada do ratchet em Dart, sem garantia de tempo constante nem de apagar segredos da memória (o GC copia), sem ML-KEM confiável |

**Recomendação**: `libsignal` (fixada numa tag, atrás de uma interface `SessionCipher` nossa), com o `vodozemac` como plano B se a API do `libsignal` ficar impraticável. A licença AGPL-3.0 é compatível com a GPL-3.0 do Chirp (as duas permitem combinar, pela seção 13), e para um app P2P sem servidor a cláusula de rede da AGPL praticamente não muda nada. **Atenção**: GPL e AGPL criam atrito com a App Store da Apple (o caso do VLC). Como as lojas não importam agora, segue; registrar no `DECISOES.md`.

---

## 5. Arquitetura alvo

### 5.1 Visão geral

```
┌──────────────────────────────── Flutter (Dart) ────────────────────────────────┐
│  ui/ (atomic design: atoms → molecules → organisms → templates → pages)        │
│  state/ (controllers por funcionalidade, ChangeNotifier/ValueNotifier)          │
│  application/ (casos de uso finos que chamam o núcleo)                          │
│  platform/ (DesktopPlatform/MobilePlatform: notificações, bandeja, cofre, BLE)  │
└───────────────────────────────▲─────────────────────────────┬──────────────────┘
                                │ eventos (Stream)            │ comandos (Future)
                      flutter_rust_bridge 2.x (API gerada, tipos fortes)
┌───────────────────────────────┴─────────────────────────────▼──────────────────┐
│                         chirp-core (Rust, sem Flutter)                          │
│  api/        fachada: Core::open, send_text, add_contact_from_qr, events()...   │
│  identity/   chaves do aparelho, perfil, números de segurança                   │
│  session/    libsignal (PQXDH, Double/Triple Ratchet, Sender Keys)               │
│  envelope/   formato do fio (Protobuf), preenchimento, assinatura               │
│  router/     fila de saída, recibos, reenvio, deduplicação, ordem               │
│  transport/  trait Transport: lan, internet(iroh), ble, wifi_direct, tor, mailbox│
│  discovery/  mDNS com tokens rotativos, BLE advertising                          │
│  store/      SQLCipher (rusqlite), migrações, apagar seguro                      │
│  files/      fatias cifradas, BLAKE3, retomar                                    │
│  clock/ rng/ injetáveis para teste                                               │
└─────────────────────────────────────────────────────────────────────────────────┘
          │                                   │
   chirp-mailbox (binário headless)     chirp-cli (testes, depuração, interop)
```

**Por que Rust no núcleo, e não Dart**:

- As bibliotecas que importam (libsignal, iroh, rusqlite+SQLCipher, snow, ml-kem, blake3, arti) são Rust.
- Segredos em memória com `zeroize`, tempo constante nas primitivas, sem GC copiando chaves.
- O mesmo núcleo vira o `chirp-mailbox` (um Raspberry Pi, um servidor, um PC sempre ligado) e o `chirp-cli` para testes de integração com vários nós num processo só.
- O `flutter_rust_bridge` gera a ponte para as 5 plataformas, e o Player já depende dele (versão 2.11.1, pelo `smtc_windows`).
- Custo: compilar Rust para Android (NDK), iOS (xcframework) e as 3 de desktop. O `cargokit` (que vem com o FRB) resolve isso dentro do `flutter build`.

### 5.2 Estrutura do repositório

```
chirp/
  core/                      # workspace Cargo
    chirp-core/              # a biblioteca
    chirp-proto/             # .proto e o código gerado (prost)
    chirp-mailbox/           # binário da caixa postal
    chirp-cli/               # binário de teste e interop
    fuzz/                    # cargo-fuzz: parser do envelope, do QR, da descoberta
  rust_builder/              # cargokit (gerado pelo FRB)
  lib/
    main.dart                # standalone: runChirp()
    chirp_app.dart           # ChirpView: recebe o núcleo e as portas de fora (como o PlayerView)
    l10n/
    src/
      bridge/                # o gerado pelo FRB, e só ele
      application/           # casos de uso (Dart) — orquestram o núcleo e a plataforma
      state/                 # controllers
      platform/              # DesktopPlatform/MobilePlatform por sistema
      ui/
        atoms/ molecules/ organisms/ templates/ pages/
        theme/               # sementes, ChirpTheme (ThemeExtension), tipografia
      settings/
      logging.dart
  test/                      # Dart: unidade, widget, golden, l10n, acessibilidade
  integration_test/          # dois núcleos no mesmo processo, conversa ponta a ponta
  docs/
    PLANO.md (este)
    PROTOCOLO.md             # a especificação do fio, versão a versão
    AMEACAS.md               # o modelo de ameaças público
    DESIGN.md                # o resumo do canvas do Claude Design
    DECISOES.md
  site/                      # página do projeto, como a do Player
  tool/                      # scripts de release, repositórios APT/DNF, AUR, instaladores
  android/ ios/ linux/ macos/ windows/
```

A ideia do `ChirpView` recebendo as dependências de fora é a mesma do `PlayerView`: o app sozinho monta tudo no `main.dart`, e os testes montam com núcleo e plataforma falsos. Se um dia o Chirp entrar no Psito OS, um projeto à parte faz o papel do `player_psito` sem tocar neste repositório; isso **não** está no plano.

### 5.3 A fronteira Dart ↔ Rust

- **Comandos** são `Future`s com tipos fortes (`Future<MessageId> sendText(ConversationId, String)`), nunca JSON solto.
- **Eventos** são um único `Stream<CoreEvent>` (um `sealed class` gerado do `enum` do Rust): `MessageReceived`, `MessageStatusChanged`, `ContactPresence`, `ContactRequest`, `TransferProgress`, `TransportStateChanged`, `SafetyNumberChanged`...
- **Consultas** paginadas (`listMessages(conv, before, limit)`) para a UI não segurar o histórico inteiro na memória.
- O conteúdo das mensagens atravessa a ponte decifrado só quando a UI pede para mostrar.
- O núcleo roda nas próprias threads (tokio); a UI nunca bloqueia.

---

## 6. Protocolo Chirp v1

Tudo isto vai para o `docs/PROTOCOLO.md`, com vetores de teste. Versão no fio desde o primeiro byte.

### 6.1 Identidade

- **Chave de identidade** (Ed25519/X25519 do libsignal) por aparelho, gerada na primeira abertura, guardada no banco cifrado; a chave do banco vai no cofre do sistema (seção 8).
- **NodeId** do transporte de internet (Ed25519 do iroh): separado da identidade, para trocar sem perder os contatos. Ligado à identidade por uma assinatura que só os contatos veem.
- **Perfil** (nome, foto, frase de status, a "mensagem pessoal" do MSN): **só vai cifrado, só para contatos**, e com versão; mudar o perfil manda a versão nova a cada contato.
- **Número de segurança**: impressão digital das duas identidades (como o do Signal: 60 dígitos e um QR). Na tela do contato, com "Marcar como verificado".
- **Vários aparelhos** (fase 11): cada aparelho tem a própria identidade; ligar um aparelho novo é ler um QR do antigo, que assina o novo (como no Signal e no WhatsApp). Os contatos veem "Fulano (2 aparelhos)".

### 6.2 Adicionar contato (as três portas)

1. **QR frente a frente** (a principal, e a mais segura). O QR leva: versão, chave de identidade, NodeId, endereços conhecidos agora (opcional), um **token de convite de uso único** (32 bytes aleatórios) e uma prekey PQ. Quem lê já tem a chave certa: o contato nasce **verificado**. Os dois lados fazem o aperto de mão na hora pela rede que houver.
2. **Link de convite** (`chirp://invite#...`, com o mesmo conteúdo do QR, no fragmento). Para mandar por outro canal. O contato nasce **não verificado**, com o aviso e o convite para comparar o número de segurança depois. O token expira (24 h por padrão) e vale uma vez.
3. **Por perto** (o "radar"). Só com o modo "Visível por perto" ligado nos dois aparelhos (desligado por padrão, liga por 10 minutos). Os dois aparecem um para o outro com um apelido escolhido para a ocasião (nunca o nome do aparelho). Tocar abre o pedido; aceitar faz o aperto de mão e mostra aos dois um **código curto de verificação** (SAS: 6 dígitos ou 4 emojis, derivados do transcrito do aperto de mão, como no Bluetooth e no ZRTP). Se bater nos dois telefones, o contato nasce verificado.

Em todas: **sem pedido aceito não existe contato**, e um "aceite" que não responde a um pedido nosso (o S1 de hoje) é descartado e conta como abuso.

### 6.3 Aperto de mão

- Canal: o do transporte (QUIC/TLS 1.3 com chaves cruas do iroh, ou Noise XX do `snow` nos transportes próprios, como o BLE) já autentica o **nó**. Por cima, a sessão do libsignal autentica a **pessoa**.
- Fluxo do QR: Bob mostra o QR com a prekey; Alice lê e roda o **PQXDH** com ela; a primeira mensagem de Alice leva o token de convite, o perfil dela (cifrado) e o pedido; Bob confere o token, aceita (automático no QR, manual no link) e responde com o perfil. A partir daí, Double Ratchet (e SPQR quando a versão do libsignal tiver).
- O token de uso único impede que um QR fotografado depois sirva para outra pessoa.

### 6.4 Envelope no fio

```
Frame (transporte) {
  version: u8
  kind: enum { SESSION_MSG, PREKEY_MSG, SEALED, PING, ACK, FILE_CHUNK, ... }
  payload: bytes       // tudo cifrado pela sessão, exceto o mínimo para entregar
}
Conteúdo decifrado (Protobuf) {
  message_id: 16 bytes aleatórios
  sent_at: u64 (relógio de quem manda, só para mostrar)
  lamport: u64          // ordem dentro da conversa
  body: oneof { Text, Reaction, Edit, Delete, Receipt, Typing, Nudge, FileOffer, Profile,
                GroupOp, CallSignal, ... }
  padding: bytes        // até o próximo tamanho da escala (ver 6.5)
}
```

- Quem mandou **não vai em claro**: o transporte autentica o nó, e a sessão diz quem é. Nada de `fromId`/`fromName` no cabeçalho.
- Deduplicação pelo `message_id`; o ratchet já recusa *replay* (chave usada uma vez).
- Limites: tamanho máximo do frame (64 KiB; arquivo vai em fatias), taxa por nó, fila de pedidos pendentes com teto. Tudo antes de decifrar.
- Evolução: campos novos no Protobuf, `version` sobe só em mudança incompatível; um nó recusa versão maior com uma mensagem clara ("atualize o app"), e a UI explica.

### 6.5 Metadados

- **Preenchimento** do conteúdo até uma escala (256 B, 1 KiB, 4 KiB, 16 KiB, 64 KiB), para o tamanho não dizer "mensagem curta" ou "foto".
- **Digitando** e **lida**: ligados por padrão, mas com opção de desligar cada um (como no WhatsApp); desligar o "lida" desliga para os dois lados, como lá.
- **Presença**: só para contatos, cifrada; "Aparecer offline" e o "Ocupado" do MSN.
- Opcional (fase 12): tráfego de cobertura em intervalo fixo para quem precisa.

### 6.6 Mensagens e recursos (inspiração nos anos 2000)

| Recurso | Referência | Como fica |
|---|---|---|
| Texto, com emojis e formatação leve (negrito, itálico, código) | todos | Markdown limitado, renderizado sem HTML |
| Recibos: enviado, entregue, lida | WhatsApp | ✓, ✓✓, ✓✓ na cor primária; "lida" opcional |
| Digitando... | MSN, iChat | Opcional, cifrado, com limite de frequência |
| **Chamar atenção** (o "nudge" que tremia a janela) | MSN | Uma vez a cada 10 s por conversa; treme a janela e vibra; dá para desligar o recebimento |
| Mensagem pessoal e status (Online, Ausente, Ocupado, Invisível) | MSN, AIM, Skype | No perfil cifrado; mensagem de ausência automática (o "away message" do AIM) opcional |
| Reações e responder citando | iMessage (tapbacks), WhatsApp | `Reaction` e `reply_to` no Protobuf |
| Editar e apagar para todos | WhatsApp, iMessage | `Edit` e `Delete` com janela de tempo; o outro lado apaga de verdade no banco |
| Mensagens temporárias | WhatsApp, Signal | Por conversa (5 min a 4 semanas), com apagar do banco e do índice de busca |
| Áudio gravado (nota de voz) | WhatsApp | Opus, como arquivo |
| Fotos e arquivos | todos | Seção 6.7, com prévia gerada no aparelho, nunca por terceiros |
| Prévia de link | iMessage | **Desligada por padrão**; quando ligada, quem **manda** gera a prévia e a envia cifrada (o modelo do Signal); quem recebe não acessa o link |
| Lista de contatos em grupos ("Amigos", "Trabalho") | MSN, AIM, iChat | Grupos locais, só no aparelho |
| Sons de contato entrando e mensagem chegando | MSN, AIM | Pios de calopsita do README, com volume e "não perturbe" |
| Histórico com busca | todos | FTS5 dentro do SQLCipher (seção 8) |
| Chamadas de voz e vídeo | Skype, FaceTime | Fase 10 |
| Grupos | WhatsApp, Skype | Fase 9 |

### 6.7 Arquivos

- Quem manda gera uma chave aleatória por arquivo (AES-256-GCM ou XChaCha20-Poly1305 em fatias de 64 KiB, com o índice da fatia no nonce/AAD) e calcula o **BLAKE3**.
- O `FileOffer` vai pela sessão (cifrado): nome, tamanho, tipo, miniatura (gerada no aparelho), hash e a chave.
- Quem recebe aceita (automático até um tamanho configurável, e só de contatos verificados se o usuário quiser) e pede as fatias; pode retomar de onde parou. Pelo transporte mais rápido disponível (LAN antes de internet antes de BLE; BLE só para arquivos pequenos).
- Arquivo recebido fica no armazenamento do app, cifrado; "Salvar em..." usa o seletor do sistema.
- Antes de mandar foto, tirar os metadados EXIF (com a localização) por padrão.

### 6.8 Grupos (fase 9)

- **Sender Keys** do libsignal: cada membro tem uma cadeia; a chave de remetente vai a cada membro pelo canal 1:1. Mensagem do grupo vai a cada membro pelo melhor transporte (*fan-out*), sem servidor.
- Operações do grupo (entrar, sair, admin, nome, foto) assinadas, com relógio de Lamport e uma regra de desempate determinística (o menor hash ganha), num CRDT simples de membros.
- Quem sai força rotação das chaves de todos.
- Limite inicial: 64 membros. Avaliar OpenMLS (com a ordem dos commits decidida pelo desempate acima, ou pelo admin) se aparecer demanda por grupos grandes.

---

## 7. Transportes

### 7.1 O contrato

```rust
trait Transport {
    fn kind(&self) -> TransportKind;              // Lan, Internet, Ble, WifiDirect, Tor, Mailbox
    async fn reachable(&self, peer: &PeerAddr) -> Reachability;
    async fn send(&self, peer: &PeerAddr, frame: Frame) -> Result<()>;
    fn incoming(&self) -> impl Stream<Item = (PeerLink, Frame)>;
    fn cost(&self) -> Cost;                       // latência, banda, bateria, metadados
}
```

O **roteador** (padrão *Strategy* + *Chain of Responsibility*) escolhe, por mensagem, o transporte disponível de menor custo, cai para o próximo quando falha, e manda para a caixa postal quando nenhum alcança. Cada transporte é um *Adapter* testado sozinho, e todos levam o mesmo `Frame` já cifrado: nenhum transporte é a camada de segurança.

### 7.2 Rede local (fase 2)

- **Descoberta**: mDNS/DNS-SD (`_chirp._udp.local`) pelo `mdns-sd` em Rust. O anúncio **não leva id fixo nem nome**: leva um **token de época** `HMAC(chave de descoberta pessoal, época de 15 min)`, truncado. Cada contato recebe a chave de descoberta pessoal pelo canal cifrado e calcula o token esperado. Quem é contato reconhece; quem não é vê um número aleatório que muda a cada 15 minutos. (Um token por contato esconderia até de um contato quem mais está ali, mas não escala; fica a chave única por pessoa, trocada quando um contato é bloqueado.)
- Modo "Visível por perto" (6.2.3): anúncio extra com apelido efêmero e chave efêmera, só enquanto ligado.
- **Conexão**: QUIC direto (o endpoint do iroh com endereço local) ou, se o iroh não for usado no LAN, TCP com Noise XX.
- Funciona **sem internet nenhuma** (um roteador sem WAN, um ponto de acesso do celular).

### 7.3 Internet (fase 5)

- **iroh** (n0, Rust): QUIC, conexão pela chave pública (não pelo IP), furo de NAT, retransmissor (*relay*) quando o furo falha. É o que mais se parece com o "disque uma chave" que o Chirp quer, e é mantido e pensado para celular.
- **Retransmissores**: o padrão do iroh usa os servidores da n0 e a descoberta por DNS/pkarr. No Chirp: **desligado por padrão** o DNS/pkarr público; a lista de retransmissores é uma configuração visível ("Servidores de retransmissão"), com o binário `iroh-relay` documentado para quem quiser hospedar. O retransmissor vê os IPs e os NodeIds e repassa bytes já cifrados; não guarda nada e não lê nada. Isso fica escrito na tela.
- Alternativa avaliada: `rust-libp2p` (Noise, Kademlia, relay v2, DCUtR). Mais "descentralizado" (DHT), mas a DHT anuncia publicamente quem está online, a API é mais pesada e não tem BLE. Fica como plano B.
- Endereços do contato: vão pelo canal cifrado a cada mudança de rede, então dois contatos que já se falaram se reencontram sem nenhum diretório.

### 7.4 Bluetooth LE (fase 8)

- Não existe plugin Flutter que faça **periférico** BLE nas 5 plataformas (o `flutter_blue_plus` e o `btleplug` são só centrais). Então: um plugin próprio `chirp_ble` com código nativo por sistema:
  - Android: `BluetoothLeAdvertiser` + GATT server + **L2CAP CoC** (banda bem maior que GATT);
  - iOS/macOS: CoreBluetooth (periférico e central, L2CAP);
  - Linux: BlueZ pelo D-Bus (`LEAdvertisingManager1`, `GattManager1`);
  - Windows: WinRT (`BluetoothLEAdvertisementPublisher`, GATT server).
- O anúncio leva o UUID de serviço do Chirp e o mesmo token rotativo da 7.2, truncado para caber nos 31 bytes do anúncio BLE legado (os detalhes do formato vão para o `PROTOCOLO.md`).
- Link com **Noise XX** (`snow`) sobre a característica ou o canal L2CAP; por cima, o mesmo `Frame`.
- Uso: texto e arquivos pequenos sem rede nenhuma (show, protesto, avião, apagão). Alcance de dezenas de metros.
- **Malha** (fase 12, experimental): repassar mensagens de contatos de contatos por BLE, como o Briar e o Bridgefy, com TTL e cota. A Bridgefy teve problemas sérios publicados (2020-2022); estudar antes de prometer.

### 7.5 Wi-Fi Direct / Multipeer (fase 12)

- Android: Wi-Fi Aware ou Wi-Fi Direct para arquivos grandes sem roteador.
- Apple: `MultipeerConnectivity` (ou Network.framework com Wi-Fi peer-to-peer).
- Só depois do BLE, e usando o BLE para descobrir e combinar.

### 7.6 Caixa postal (fase 7): mensagens para quem está offline

O problema clássico do P2P: Alice escreve, Bob está desligado. Opções, em ordem:

1. **Fila local**: a mensagem espera no aparelho de Alice e sai quando os dois se encontrarem (sempre ligado, sem configurar nada).
2. **Caixa postal pessoal (`chirp-mailbox`)**: um aparelho sempre ligado **do próprio Bob** (um PC, um Raspberry Pi, um servidor, um celular velho, como o Briar Mailbox) que recebe por ele. Bob liga a caixa ao app por QR; a caixa recebe envelopes **já cifrados para Bob** e guarda até ele buscar (com prazo). A caixa não tem chave de nada: vê só que alguém deixou N bytes para Bob.
3. **Caixa de um amigo** (opcional): um contato aceita guardar para outro, nas mesmas condições.

Para a **primeira** mensagem a quem está offline (contato por link), a caixa publica as **prekeys PQXDH** de Bob: aqui entra a parte assíncrona do Signal.

### 7.7 Tor (fase 12, experimental)

- `arti-client` (o Tor em Rust) com serviço onion por usuário: esconde o IP dos contatos e dos retransmissores. Custa latência e bateria. Opção avançada "Esconder meu endereço IP", com explicação.

### 7.8 O que funciona em cada sistema

| | Linux | Windows | macOS | Android | iOS |
|---|---|---|---|---|---|
| Rede local (mDNS + QUIC) | sim | sim (firewall pede permissão) | sim (permissão de rede local) | sim (`MulticastLock`) | sim (`NSLocalNetworkUsageDescription`, entitlement de multicast precisa de pedido à Apple) |
| Internet (iroh) | sim | sim | sim | sim | sim, só em primeiro plano |
| BLE | BlueZ | WinRT | CoreBluetooth | sim | sim, limitado em segundo plano |
| Receber com o app fechado | bandeja / serviço do usuário | bandeja / iniciar com o Windows | item de menu / login item | serviço em primeiro plano (como o Briar) | **não sem push**: só com o app aberto ou pela caixa postal ao abrir |
| Cofre de chaves | libsecret (Secret Service) | DPAPI / Credential Manager | Keychain | Android Keystore | Keychain (Secure Enclave) |

**iOS em segundo plano** é a maior limitação honesta do projeto: a Apple não deixa um app manter conexões abertas. Receber com o app fechado exigiria notificações push pela APNs, o que exige um servidor que sabe o token do aparelho. Proposta: na 1.0, iOS recebe ao abrir (e pela caixa postal); avaliar depois um "acordador" opcional e auto-hospedável que só manda um push vazio ("tem algo na sua caixa"), sem conteúdo nem remetente.

---

## 8. Armazenamento e privacidade local

- **SQLCipher** pelo `rusqlite` (feature `bundled-sqlcipher-vendored-openssl`), dentro do núcleo. Tudo cifrado, inclusive os ids e os índices (corrige o P5). A busca é FTS5 dentro do mesmo banco.
- **Chave do banco**: 32 bytes aleatórios guardados no cofre do sistema (tabela 7.8), pelo `flutter_secure_storage` ou por canal próprio no `platform/`. Sem cofre (Linux sem Secret Service), o app **pede uma senha** e deriva com **Argon2id**; nunca grava a chave em claro.
- **Senha do app** (opcional): Argon2id → chave que envolve a chave do banco; bloqueio por inatividade; biometria no celular.
- **Mensagens temporárias** apagam a linha, o FTS e os arquivos; `secure_delete=ON` no SQLCipher; `VACUUM` periódico.
- **Apagar tudo** (nas configurações, com confirmação), e uma **senha de pânico** opcional que apaga em vez de abrir.
- **Backup**: desligado por padrão (Android `allowBackup=false`, exclusão do iCloud). Fase 11: exportação cifrada com uma frase de 24 palavras, para trocar de aparelho.
- **Capturas de tela**: `FLAG_SECURE` no Android e esconder a prévia no seletor de apps do iOS, como opção "Bloquear capturas".
- **Notificações**: opção de mostrar só "Nova mensagem" (sem nome nem texto), para a tela bloqueada.
- **Teclado**: pedir ao teclado do sistema para não aprender (`enableIMEPersonalizedLearning: false`) nos campos de mensagem.

---

## 9. Distribuição (independente, como o Player)

| Sistema | Formato | Como sai |
|---|---|---|
| Linux | `.deb`, `.rpm`, AUR (`psito-chirp-bin`), AppImage; depois Flatpak | GitHub Actions; repositórios APT e DNF no GitHub Pages com chave própria, como os do Player (`tool/build-apt-repo.sh`, `build-dnf-repo.sh`) |
| Windows | Instalador Inno Setup, nome fixo para o link de download valer | `windows.yml`, como o do Player; regra de firewall criada pelo instalador para a rede local |
| macOS | `.dmg` assinado e notarizado (precisa da conta de desenvolvedor da Apple; sem ela, `.dmg` sem assinatura com instrução do Gatekeeper) | `macos.yml` |
| Android | APK assinado no GitHub e no **F-Droid** (combina com a proposta: sem Google Play Services, sem FCM) | `android.yml`; build reprodutível para o F-Droid |
| iOS | TestFlight ou instalação pelo Xcode / AltStore enquanto as lojas não importam | manual no começo |

- **Versão**: semantic-release como no Player (`feat` sobe o minor, `fix` o patch).
- **Sem atualização automática que chama servidor**: o app não verifica versão sozinho. Os repositórios do sistema (APT, DNF, F-Droid) fazem isso.
- **Builds reprodutíveis** como meta (Android e Linux primeiro), e as somas SHA-256 assinadas na release.
- Nome sugerido: **Psito Chirp** (pacote `psito-chirp`, id `org.psito.chirp`), na família do Player e do Nest. A marca "ChirpTalk" do README pode ficar como apelido.

---

## 10. UI e design

### 10.1 Material 3 e temas

- `ColorScheme.fromSeed` em claro e escuro, com `DynamicSchemeVariant` escolhível; cor dinâmica do sistema (`dynamic_color`) no Android 12+ e onde houver.
- Os 7 temas de hoje viram **sementes com personalidade** (`ChirpTheme`: semente, variante, raio dos cantos, densidade e o "efeito" opcional), em vez de 14 arquivos de cor:
  - **Sunny Lutino** (amarelo-queijo, padrão), **Wild Grey** (cinza com bochecha laranja como terciária), **Skylight** (o azul do MSN dos anos 2000), **Old Days** (cinza Windows 2000), **Human** (laranja e beringela do Ubuntu antigo), **Symbian**, **Foundation**, **Mighty Cats** (alumínio do Mac OS X).
  - Cada um define só a semente e um `ThemeExtension<ChirpStyle>` (formato das bolhas, raio, fundo da conversa), e o M3 faz o resto, com contraste garantido.
- **Glassmorphism** sai do padrão: vira o "Efeito vidro" opcional, desligado quando o sistema pede menos animação ou transparência, e nunca atrás de texto longo.
- Fonte: a do sistema (sem `google_fonts`; se quiser a Urbanist, vai **empacotada** nos assets, com a licença OFL no `THIRD_PARTY_LICENSES.md`).
- Avatares: **gerados no aparelho** (monograma colorido pela semente, ou uma calopsita desenhada em SVG com as mutações de cor, aproveitando a arte do Psito Nest), nunca de um serviço. Foto escolhida pelo usuário vai cifrada no perfil.
- Regras do Player valem aqui: cores só do `colorScheme`/`ThemeExtension`, botão principal `FilledButton`, secundário tonal, terciário `TextButton`, buscas pelo `SearchField`, `design_test` conferindo.

### 10.2 Atomic design

| Camada | Exemplos |
|---|---|
| **atoms** | `ChirpAvatar`, `PresenceDot`, `UnreadBadge`, `DeliveryTicks`, `VerifiedShield`, `SafetyNumberText`, `SearchField`, `ToggleIconButton`, `EmptyNote`, `TransportIcon` (LAN, internet, BLE) |
| **molecules** | `ContactTile`, `ConversationTile`, `MessageBubble`, `ReactionBar`, `QuotedMessage`, `TypingIndicator`, `FileCard`, `VoiceNotePlayer`, `NearbyPeerTile`, `SettingsRow`, `ComposerToolbar`, `SasCodeView` |
| **organisms** | `ContactList` (com grupos recolhíveis, à la MSN), `ConversationList`, `MessageList` (paginada, com divisores de dia), `Composer`, `QrShareCard`, `QrScanner`, `NearbyRadar`, `ContactHeader`, `SafetyNumberPanel`, `TransferList` |
| **templates** | `ShellTemplate` (3 colunas no desktop: lista de contatos, conversa, painel do contato; navegação inferior no celular; o mesmo `isMobile` do Player), `OnboardingTemplate`, `SettingsTemplate` (lista à esquerda, painel à direita), `DialogTemplate` (diálogo, tela cheia abaixo de 600 px) |
| **pages** | `OnboardingPage`, `HomePage`, `ConversationPage`, `ContactPage`, `AddContactPage`, `NearbyPage`, `VerifyPage`, `SettingsPage` (Perfil, Privacidade, Rede, Aparência, Notificações, Armazenamento, Sobre), `MailboxPage`, `AboutSecurityPage` |

O que aparece em mais de uma página sobe de camada (regra do Player).

### 10.3 Telas para o canvas do Claude Design

Antes de escrever a UI, um canvas "Psito Chirp" (como o `Psito_Player.html`), em desktop 1280×800 e celular 390×844, claro e escuro, com a semente Lutino e uma segunda (Skylight) para provar o sistema de temas:

1. Boas-vindas e criar perfil (nome, foto ou calopsita), com a frase "suas conversas ficam só nos aparelhos de vocês".
2. Início vazio (nenhum contato): os três caminhos para adicionar.
3. Início com contatos: lista em grupos à la MSN, presença, mensagem pessoal; conversas recentes.
4. Conversa: bolhas, recibos, digitando, reações, citação, arquivo, nota de voz, "chamar atenção", divisor de dia, faixa "conversa verificada / não verificada".
5. Adicionar contato: mostrar meu QR, ler QR, link de convite.
6. Por perto (radar) e o código de verificação SAS lado a lado.
7. Contato: perfil, número de segurança, verificar, transporte atual, mensagens temporárias, bloquear.
8. Configurações: Privacidade (recibos, digitando, presença, bloquear capturas, senha do app), Rede (rede local, internet, retransmissores, Bluetooth, Tor), Aparência (tema, cor dinâmica, efeito vidro, densidade, texto), Caixa postal.
9. Estados: sem rede, contato fora de alcance (mensagem na fila), versão incompatível, chave do contato mudou (alerta de segurança).
10. Janela mínima (240×160 no desktop) e celular pequeno.

Depois do canvas, um `docs/DESIGN.md` resume os papéis do `ColorScheme`, as formas e os componentes M3 de cada tela, no formato do `DESIGN.md` do Player.

### 10.4 Acessibilidade, idiomas e janela

- `Semantics`/`Tooltip` em todo clique, ordem de foco e atalhos de teclado (Ctrl+N nova conversa, Ctrl+K buscar, Alt+↑/↓ trocar de conversa, Esc fechar painel); `accessibility_test` nos dois temas, como no Player.
- 7 idiomas como o Player (en, pt, es, fr, de, ru, zh), com o `l10n_test` conferindo chaves, marcadores e se cabe.
- Sem emojis em texto fixo da UI (emojis **nas mensagens** são do usuário e usam a fonte de emoji empacotada, `Noto Color Emoji`, para não depender do sistema).
- Funciona até 240×160 no desktop; `golden_test` nas telas principais.

---

## 11. Padrões de projeto ("backend")

### 11.1 No núcleo (Rust)

- **Arquitetura hexagonal** (portas e adaptadores) de verdade: o domínio (`session`, `router`, `identity`) depende de *traits* (`Transport`, `Store`, `Clock`, `Rng`, `KeyVault`), e os adaptadores (`iroh`, `ble`, `sqlcipher`) implementam. Testes do domínio com adaptadores em memória.
- **Máquinas de estado explícitas** (*State*, com `enum` e transições puras) para o aperto de mão, o contato (`Invited → Pending → Established → Verified → Blocked`), a transferência de arquivo e a conexão. Cada transição testada; estados impossíveis não compilam.
- **Strategy + Chain of Responsibility** no roteador de transportes (7.1).
- **Outbox** (caixa de saída transacional): a mensagem é gravada na mesma transação que avança o ratchet, e só depois sai pela rede; o reenvio lê da outbox. Nunca perde mensagem nem gasta chave à toa se o app cair no meio.
- **Inbox idempotente**: deduplicação pelo `message_id` antes de processar.
- **Atores** (uma task do tokio por conexão e uma pelo roteador, conversando por canais): sem trava compartilhada no caminho quente.
- **Event sourcing leve** para grupos (operações assinadas + Lamport), e **CRDT** simples para os membros.
- **Repository** sobre o SQLCipher, com migrações versionadas (`refinery` ou próprio), testadas da v1 em diante.
- **Newtypes** para ids (`ContactId`, `ConversationId`, `MessageId`, `NodeId`): não dá para trocar um pelo outro.
- **Erros tipados** (`thiserror`) que viram `sealed class` no Dart; a UI decide o texto (traduzido), o núcleo não fala língua nenhuma (como o `psito_fs`).
- **Segredos** em `secrecy::SecretBox` + `zeroize`; `#![forbid(unsafe_code)]` fora da ponte.

### 11.2 No Dart

- **Casos de uso finos** (`application/`), um por intenção (`SendTextMessage`, `AddContactFromQr`, `VerifyContact`...), com o núcleo atrás de uma interface `ChirpCore` (o gerado do FRB por trás); nos testes, um `FakeChirpCore`.
- **Controllers por funcionalidade** (`ConversationsController`, `ConversationController(id)`, `ContactsController`, `NearbyController`, `SettingsController`) assinando o `Stream<CoreEvent>`; sem controller "deus" como o `ChirpController` de hoje.
- **Injeção pelo construtor** do `ChirpView` (como o `PlayerView`), sem service locator global. O `get_it` e o `provider` saem, ou o `provider` fica só como `InheritedWidget` de conveniência.
- **Domínio sem Flutter**: nada de `Color` em entidade (o `getStatusColor` do `Tiel` vai para um widget).
- **Relógio injetável** (`Clock`) no Dart e no Rust.
- **`platform/`** como no Player: `DesktopPlatform`/`MobilePlatform` por sistema (notificações, bandeja, iniciar com o sistema, cofre, permissões de BLE e câmera).

### 11.3 Logs

- `debugPrint` atrás do `logging.dart` do Player: em release, só com "Registrar logs" ligado; nunca conteúdo, nome, id, chave ou endereço (um teste procura padrões proibidos nos logs gerados pelos testes de integração).
- No Rust, `tracing` com o nível desligado por padrão em release e um filtro que só aceita campos marcados como seguros.

### 11.4 Dependências

- Cada dependência nova passa por: mantida? quem mantém? chama a rede? licença compatível? `cargo deny` e `cargo audit` no CI; `cargo vet` para a criptografia.
- Fixar versões do libsignal, iroh e SQLCipher; atualizar com intenção.

### 11.5 Vocabulário

Nomes de código dizem o que as coisas são; a marca fica nos textos:

| Hoje | No código | Na UI (pt) |
|---|---|---|
| Tiel | `Contact` / `Peer` | contato, calopsita |
| Flock | `Network` / `Router` | o bando |
| Nest | `Store` | o ninho |
| Chirp | `Message` | pio, mensagem |
| FlockDiscovery | `Discovery` | radar |

---

## 12. Qualidade e segurança contínua

- **Testes do núcleo**: unidade em cada módulo; propriedades (`proptest`) no envelope, na ordem e na deduplicação; **vetores de teste** do protocolo no `docs/PROTOCOLO.md`; testes de integração com **N nós no mesmo processo** sobre um transporte em memória que perde, atrasa, duplica e reordena pacotes.
- **Fuzzing** (`cargo-fuzz`) em todo parser que recebe bytes de fora: frame, Protobuf, QR, link de convite, anúncio de descoberta, BLE. No CI, uma rodada curta; semanal, longa.
- **Testes do Dart**: unidade nos casos de uso e controllers com `FakeChirpCore`; widget e golden nas páginas; `l10n_test`, `accessibility_test`, `design_test` e um `privacy_test` que proíbe imports de pacotes que chamam a rede (`google_fonts`, `http` fora do núcleo) e URLs no código.
- **Integração real**: dois apps no mesmo host (Linux) conversando pela rede local num teste do `integration_test`; no CI, dois contêineres.
- **CI**: `cargo test`, `clippy -D warnings`, `cargo deny`, fuzz curto, `flutter analyze`, `flutter test -j 2`, e builds das 5 plataformas (iOS e macOS no runner de macOS).
- **Revisão de segurança**: antes da 1.0, uma auditoria externa do núcleo e do protocolo (OSTIF e Open Technology Fund financiam auditorias de projetos livres de privacidade; vale pedir). Antes disso, um `SECURITY.md` com contato para relatos e a página `AMEACAS.md` pública.

---

## 13. Roteiro por fases

Cada fase termina com algo usável, testes verdes e um `FASEn-RESULTADOS.md`. As fases 0 a 6 fazem a 1.0 "1:1 seguro"; o resto vem em 1.x.

### Fase 0: Fundação e limpeza (1 a 2 semanas)

- Congelar o protótipo numa tag `prototipo-2026` e abrir a reconstrução na `master` (direto, sem branch, como no Psito).
- `CLAUDE.md` do projeto com as regras (as do Player adaptadas: l10n, cores, acessibilidade, logs, sem terceiros).
- Workspace Cargo `core/` com `chirp-core` vazio, FRB 2.x ligado, `cargokit`, e um `hello()` chamado do Flutter **nas 5 plataformas** no CI. É a fase de risco técnico: se a ponte não compilar em algum sistema, descobrir agora.
- `gen-l10n` com os 7 idiomas, `logging.dart`, `analysis_options` mais estrito.
- Remover: `peerdart` (e o override do `flutter_webrtc`), `crypton`, `encrypt`, `google_fonts`, `hive_flutter`, `shared_preferences` para segredos, DiceBear.
- Trocar o id `com.example.chirp` por `org.psito.chirp` em todas as plataformas.
- **Saída**: app abre, mostra a versão do núcleo, CI verde em 5 sistemas.

### Fase 1: Identidade e armazenamento (2 semanas)

- `identity/`: chaves do libsignal, perfil local; `store/` com SQLCipher e migrações; chave no cofre de cada sistema, senha com Argon2id quando não houver cofre.
- Interface `KeyVault` no `platform/` do Dart, com as 5 implementações.
- Onboarding (nome, avatar gerado).
- **Saída**: perfil criado e guardado cifrado; teste que abre o arquivo do banco e não acha nenhum texto em claro.

### Fase 2: Rede local e aperto de mão (3 a 4 semanas)

- `transport/lan` (QUIC pelo iroh com endereço local, ou TCP+Noise) e `discovery/` mDNS com tokens rotativos.
- Contato por **QR** (mostrar e ler: `mobile_scanner` no celular e no macOS; no Linux e no Windows, ler pela câmera é mais difícil, então colar o link ou ler de uma imagem) e por **link**.
- PQXDH + Double Ratchet pelo libsignal; máquina de estados do contato; número de segurança e "verificar".
- **Saída**: dois computadores na mesma rede, sem internet, viram contatos por QR/link, e o teste de integração prova que um terceiro na rede não consegue se passar por nenhum dos dois (os S1 a S3 viram testes de regressão).

### Fase 3: Mensagens 1:1 (3 semanas)

- Envelope Protobuf, preenchimento, outbox/inbox, recibos, digitando, ordem, reenvio, fila offline.
- Editar, apagar, responder, reações, "chamar atenção".
- Busca (FTS5).
- **Saída**: conversa completa na rede local, com o app fechando e abrindo no meio sem perder nada.

### Fase 4: UI nova em Material 3 (3 a 4 semanas, pode começar em paralelo à fase 2)

- Canvas no Claude Design (10.3) e o `DESIGN.md`.
- Temas por semente, `ThemeExtension`, efeito vidro opcional.
- Atomic design completo (10.2), layout desktop de 3 colunas e celular com navegação inferior.
- Migrar as telas do protótipo que servem (lista de conversas, bolhas, perfil, seleção de tema) para os novos componentes; descartar as que não servem.
- `golden_test`, `accessibility_test`, `design_test`, `l10n_test`.
- **Saída**: o app inteiro na UI nova, nos dois temas, com as 7 línguas.

### Fase 5: Internet (3 semanas)

- `transport/internet` com o iroh: furo de NAT, retransmissor configurável (padrão: nenhum; o usuário escolhe ou hospeda), troca de endereços pelo canal cifrado.
- Roteador escolhendo LAN antes de internet.
- Configurações → Rede, com o texto do que cada opção revela.
- **Saída**: dois contatos em redes diferentes conversam; com o retransmissor desligado e NAT simétrico, o app diz claramente por que não conecta.

### Fase 6: Arquivos, notificações e segundo plano → **1.0** (3 semanas)

- Arquivos em fatias (6.7), fotos sem EXIF, notas de voz.
- Notificações nativas (com o modo "sem conteúdo"), bandeja no desktop, iniciar com o sistema, serviço em primeiro plano no Android.
- Instaladores e repositórios (seção 9) para Linux, Windows e Android; macOS e iOS como build de teste.
- `SECURITY.md`, `AMEACAS.md`, página do projeto.
- **Saída: versão 1.0**, mensageiro 1:1 seguro na rede local e na internet.

### Fase 7: Caixa postal (2 a 3 semanas)

- `chirp-mailbox` (binário Rust, pacote `.deb` e imagem de contêiner), ligado por QR; prekeys PQXDH publicadas nela; buscar ao abrir.
- **Saída**: mandar mensagem a quem está offline e ela chegar quando a pessoa abrir o app.

### Fase 8: Bluetooth LE (4 a 6 semanas)

- Plugin `chirp_ble` com os 4 sistemas nativos (7.4), Noise sobre L2CAP/GATT. Começar por Android e Linux, depois Apple, por último Windows.
- **Saída**: dois celulares sem rede nenhuma trocam mensagens e fotos pequenas.

### Fase 9: Grupos (4 semanas)

- Sender Keys, operações assinadas, CRDT de membros, rotação ao sair, até 64 membros.
- UI de grupos (criar, convidar por QR/link, admin).

### Fase 10: Chamadas de voz e vídeo (6+ semanas)

- WebRTC (`flutter_webrtc`) com a sinalização **pelo canal cifrado do Chirp**, as impressões digitais do DTLS conferidas por ele, só candidatos locais e do retransmissor escolhido (nenhum STUN de terceiros por padrão).
- Alternativa a estudar: Opus/VP8 direto por datagramas QUIC do iroh, sem a pilha WebRTC.

### Fase 11: Vários aparelhos e backup (4 semanas)

- Ligar aparelho por QR (6.1), sincronizar histórico cifrado entre os próprios aparelhos, exportação com frase de 24 palavras.

### Fase 12: Avançado e auditoria

- Tor (arti), Wi-Fi Direct/Multipeer, malha BLE experimental, tráfego de cobertura, builds reprodutíveis, **auditoria externa**, depois as lojas (F-Droid primeiro).

### Mapa do que acontece com cada arquivo de hoje

| Hoje | Destino |
|---|---|
| `infrastructure/services/secure_chirp.dart`, `domain/models/chirp_envelope.dart`, `secure_keys.dart` | **Descartar** (substituídos pelo libsignal no núcleo) |
| `infrastructure/services/flock_manager.dart`, `flock_discovery.dart` | **Descartar** (transportes e descoberta no núcleo) |
| `infrastructure/services/identity_service.dart` | **Descartar** (identidade no núcleo, cofre no `platform/`) |
| `infrastructure/adapters/secure_nest_hive_adapter.dart`, `repositories/*`, `secure_nest.dart`, `data/chirp_cache.dart` | **Descartar** (SQLCipher no núcleo) |
| `domain/models/chirp_packet.dart` | **Reescrever** como `chirp.proto` (a ideia do `sealed` fica) |
| `domain/entities/*` | **Reaproveitar a forma** como tipos gerados do núcleo (sem Flutter, sem `Color`, sem URL de avatar) |
| `domain/usecases/*` | **Reescrever finos** em `application/`, chamando o núcleo |
| `app/controllers/*` | **Reescrever** por funcionalidade |
| `app/themes/*` (14 arquivos) | **Condensar** em sementes + `ThemeExtension` |
| `app/widgets/**` | **Migrar** os que encaixam no atomic design novo (bolha, tiles, avatar, seletor de tema), trocando cores fixas pelo esquema e textos pelo l10n |
| `test/domain/*` | Manter os que ainda fizerem sentido; o resto renasce no núcleo |
| `.github/workflows/flutter_ci.yaml` | **Reescrever** (5 plataformas, Rust, fuzz, sem Codecov obrigatório) |

---

## 14. Riscos e decisões em aberto

| Risco | Impacto | Mitigação |
|---|---|---|
| API do `libsignal` instável / feita para o servidor do Signal | Alto | Interface `SessionCipher` nossa; plano B `vodozemac` (sem PQ); fixar tag |
| Ponte Rust em 5 plataformas (NDK, xcframework, MSVC) | Alto no começo | Fase 0 só disso, no CI |
| iOS sem segundo plano | Alto para o "WhatsApp" | Caixa postal; ser honesto na UI; avaliar acordador auto-hospedável |
| BLE periférico em 4 pilhas nativas | Alto | Fase própria, Android+Linux primeiro |
| NAT simétrico sem retransmissor | Médio | Retransmissor opcional e auto-hospedável; mensagem clara |
| Licença AGPL/GPL e App Store | Médio (futuro) | Registrado; lojas fora do escopo agora; F-Droid sem problema |
| Escopo enorme para uma pessoa | Alto | 1.0 é só 1:1 (fases 0-6); cada fase entrega algo usável |
| Abuso (spam por perto, pedidos em massa) | Médio | Visibilidade desligada por padrão, limites, bloquear |
| Criptografia mal usada mesmo com boas bibliotecas | Alto | Especificação escrita, vetores, fuzz, auditoria antes de prometer "seguro" na página |

**Decisões para tomar com você antes da fase 0:**

1. Núcleo em Rust (recomendado) ou tudo em Dart (mais simples, bem menos seguro)?
2. `libsignal` (AGPL, com pós-quântico) ou `vodozemac` (Apache, sem pós-quântico)?
3. iroh (recomendado) ou libp2p para a internet?
4. Nome: "Psito Chirp" (`org.psito.chirp`) ou manter "ChirpTalk"?
5. Os 7 temas ficam todos, ou a 1.0 sai com Lutino e Wild Grey e o resto vem depois?
6. Retransmissor: o projeto mantém um público (custa dinheiro e vira alvo) ou só documenta como hospedar?

---

## 15. Referências para estudar

- Signal: especificações do X3DH, PQXDH, Double Ratchet, Sesame e o anúncio do SPQR (signal.org/docs e o blog de 2025).
- **Briar** (Bramble Transport Protocol, Briar Mailbox): o projeto mais parecido com o que o Chirp quer (Bluetooth, Wi-Fi, Tor, sem servidor).
- **SimpleX Chat**: identidade sem identificador fixo, filas unidirecionais, Double Ratchet com PQ.
- **Berty** (Wesh protocol): libp2p + BLE em Go; vale pela parte de rede e pelo BLE.
- **Session**: o que **não** fazer (removeram o sigilo futuro em 2020).
- **Cwtch**: mensageiro sobre onion services do Tor.
- Noise Protocol Framework (noiseprotocol.org) e o `snow`.
- iroh (iroh.computer): documentação de *relays* e *discovery*.
- RFC 9420 (MLS) e o OpenMLS, para a fase de grupos.
- Os relatórios públicos das falhas da Bridgefy (2020 e 2022), antes da malha BLE.

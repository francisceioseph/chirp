# Protocolo Chirp v1

O que vai no fio e como dois aparelhos viram contatos. Rascunho vivo: muda com as fases, mas o que está marcado como v1 só muda com a versão do protocolo (`wire::VERSION`). As decisões e o porquê estão no `docs/PLANO.md` (seções 4 e 6).

## Chaves de cada aparelho

| Chave | O que é | Onde fica |
|---|---|---|
| Identidade | Curve25519 no formato do libsignal (`0x05` e 32 bytes na pública) | Banco cifrado (`identity`) |
| Nó | Ed25519 do iroh: autentica a conexão QUIC (TLS 1.3 com chaves cruas) | Banco cifrado (`local_keys`) |
| Descoberta | 32 bytes aleatórios, para os tokens de descoberta (fase 3) | Banco cifrado (`local_keys`) |
| Registro | id de 14 bits do libsignal | Banco cifrado (`local_keys`) |

A identidade é a pessoa; o nó é só por onde se chega. Trocar o nó não perde contatos.

## Impressão digital e número de segurança

O `Fingerprint` do libsignal, versão 2, 5200 iterações, com o identificador estável igual à própria chave de identidade:

```
h0 = SHA-512(0x0000 || chave || chave || chave)
hn = SHA-512(h(n-1) || chave)
```

Dos primeiros 30 bytes saem 6 grupos de 5 bytes, cada um como inteiro big-endian módulo 100000 e escrito com 5 dígitos. A "Sua chave" do perfil é essa metade; o número de segurança de uma conversa junta as duas metades em ordem, igual nos dois aparelhos (60 dígitos).

Vetor: para a chave `0x05` seguida de 32 zeros, a impressão é `00474 20068 94096 69306 80853 32172`, e a semente do avatar (bytes 30 a 33 do mesmo hash, big-endian) é `2961606259` (`identity::tests::the_fingerprint_matches_the_vector`).

## O convite (QR e link)

```
versão (1, = 1) || identidade (33) || nó (32) || token (32) ||
n (1, até 8) || n × [ 4 || IPv4 (4) || porta (2)  |  6 || IPv6 (16) || porta (2) ]
[ || m (1, de 1 a 200) || retransmissor (m, URL em UTF-8) ]      (fase 5, opcional)
[ || 0xFF || nó da caixa (32) || n (1, até 8) || n × endereço ||
     r (1, até 200) || retransmissor da caixa (r) ]              (fase 7, opcional)
```

- O link é `chirp://invite#` e os bytes em base64url sem preenchimento. O QR é o mesmo link. Fica em torno de 180 caracteres.
- O token tem 32 bytes aleatórios, vale uma vez, por 24 horas, e o banco guarda só o SHA-256 dele.
- Com a internet desligada (o padrão), os endereços são só os da rede local (IPv4 privado e IPv6 `fc00::/7`): o link mandado por outro canal não leva IP público. Com ela ligada, vêm também os públicos (os da interface e o que o retransmissor viu), os locais primeiro.
- O retransmissor de quem convida, se houver, vai no fim (`https://`, ou `http://` para uma rede própria, sem usuário, senha, consulta nem fragmento). Sem ele, os bytes são os de antes; uma versão anterior recusa um convite com retransmissor como "convite inválido".
- A caixa postal de quem convida vai por último, só quando as prekeys do convite foram publicadas nela (a seguir, "O primeiro contato pela caixa"). O `0xFF` não se confunde com o tamanho de um retransmissor. O link aceita até 1024 caracteres.
- As prekeys **não** vão no convite: a Kyber1024 sozinha tem 1568 bytes, e o QR ficaria ilegível. Quem lê pede pela rede e confere as assinaturas com a identidade do convite, o que dá a mesma garantia.
- Qualquer byte a mais, a menos ou fora do formato recusa o convite inteiro (`invite::tests`).

## Frames

Cada frame é `tamanho (u32, big-endian) || Frame (Protobuf)`, com no máximo 64 KiB. O tamanho é conferido antes de alocar, e um `version` diferente de 1 é recusado.

```
Frame { version = 1; oneof body {
  BundleRequest bundle_request = 2;   // { bytes token = 1 }
  Bundle bundle = 3;                  // as prekeys de um convite
  bytes pre_key_message = 4;          // PreKeySignalMessage do libsignal
  bytes message = 5;                  // SignalMessage do libsignal
  Refused refused = 6;                // {} — sem motivo
  Ack ack = 7;                        // {} — gravei a mensagem anterior
  FileRequest file_request = 8;       // { bytes file_id = 1; uint32 from = 2; } (fase 6)
  FileChunk file_chunk = 9;           // { uint32 index = 1; bytes data = 2; }   (fase 6)
}}

Bundle {
  uint32 registration_id = 1;
  uint32 prekey_id = 2;        bytes prekey = 3;
  uint32 signed_prekey_id = 4; bytes signed_prekey = 5; bytes signed_prekey_signature = 6;
  uint32 kyber_prekey_id = 7;  bytes kyber_prekey = 8;  bytes kyber_prekey_signature = 9;
}
```

## Conteúdo (dentro da sessão)

```
Content { bytes message_id = 1 (16 aleatórios);
          oneof body { Hello hello = 2; Welcome welcome = 3; Text text = 4;
                       Receipt receipt = 5; Edit edit = 6; Delete delete = 7;
                       Reaction reaction = 8; Typing typing = 9; Nudge nudge = 10;
                       PeerProfile profile = 11; Peer addrs = 12;
                       FileOffer file = 16; MailboxInfo mailbox = 17;
                       PeerPhoto photo = 18; };
          uint64 sent_at = 13 (ms, relógio de quem manda, só para mostrar);
          uint64 lamport = 14 (a ordem na conversa);
          bytes padding = 15; }
Hello    { bytes token = 1; PeerProfile profile = 2; Peer peer = 3;
           MailboxInfo mailbox = 4 (fase 7: a caixa de quem leu, com a ficha de quem convidou); }
Welcome  { PeerProfile profile = 1; Peer peer = 2; }
PeerProfile { string display_name = 1; uint32 version = 2; }
Peer     { bytes endpoint_id = 1; repeated string addrs = 2; bytes discovery_key = 3; }
         // addrs: "IP:porta" (até 8) e URLs de retransmissor (até 3), conferidos por
         // quem recebe (`network::clean_addrs`); o resto é descartado.
         // No `addrs = 12` (os endereços mudaram), só o addrs vale.
Text     { string text = 1; bytes reply_to = 2 (o message_id citado, ou vazio); }
Receipt  { repeated bytes read = 1 (até 256 message_ids lidos);
           repeated bytes delivered = 2 (até 256 que chegaram pela caixa postal, fase 7); }
Edit     { bytes target = 1; string text = 2; }
Delete   { bytes target = 1; }
Reaction { bytes target = 1; uint32 kind = 2 (1 a 6; 0 tira); }
Typing   {}
Nudge    {}
FileOffer { bytes file_id = 1 (16); string name = 2; uint64 size = 3; string mime = 4;
            bytes hash = 5 (BLAKE3, 32); bytes key = 6 (32); bytes thumbnail = 7 (JPEG ou vazio); }
PeerPhoto { bytes jpeg = 1; }
            // A foto do perfil: um JPEG inteiro (começa em FF D8 e termina em FF D9), até
            // 48 KiB, quase quadrado e até 1024 px, que se decodifica; vazio: a foto não é
            // mais para este contato, e quem recebe apaga a que tinha. Fora disso, ignorado.
MailboxInfo { bytes endpoint_id = 1 (32, o nó da caixa); repeated string addrs = 2;
              bytes drop = 3 (32, a ficha deste contato); }
            // Tudo vazio: a caixa foi desligada. Fora disso, um campo de tamanho errado
            // faz o conteúdo ser ignorado. Os addrs passam pelo `network::clean_addrs`.
```

O conteúdo é preenchido até o próximo degrau (256 B, 1 KiB, 4 KiB, 16 KiB, 60 KiB), para o tamanho cifrado não dizer o que é.

## O aperto de mão (ALPN `chirp/1`)

Uma conexão QUIC e um stream bidirecional; no máximo 4 frames e 20 segundos.

1. **Convidado → anfitrião**: `BundleRequest { token }`.
2. **Anfitrião**: o token tem de ser de um convite vivo (existe, não venceu, não foi usado). Responde `Bundle` com as prekeys **daquele** convite (uma EC de uso único, uma assinada e uma Kyber1024), ou `Refused`.
3. **Convidado**: confere as assinaturas das prekeys com a identidade do convite (`process_prekey_bundle`), roda o PQXDH e manda `pre_key_message` com o `Hello` cifrado. O contato fica `Pending`.
4. **Anfitrião**, numa transação só:
   - decifra;
   - confere que o token do `Hello` é de um convite vivo e que as prekeys usadas são as dele;
   - confere que o `Peer.endpoint_id` é o nó da conexão (ninguém repassa o `Hello` de outro);
   - valida o nome e os dados do `Peer`;
   - gasta o convite, apaga as prekeys, grava o contato `Established` e responde `message` com o `Welcome` cifrado.

   Qualquer falha desfaz tudo (nem sessão, nem identidade, nem contato) e responde `Refused`.
5. **Convidado**: decifra o `Welcome`, confere o nó da conexão de novo, e o contato fica `Established`. Se o `Welcome` não vier, o contato pendente e a sessão são apagados, para tentar com outro convite.

**Verificado**: só quem **leu** o QR frente a frente nasce verificado, porque viu a chave de quem o mostrava. Quem mostrou o QR não conferiu nada de quem leu e nasce não verificado, até comparar o número de segurança. Pelo link, ninguém nasce verificado.

## As mensagens (fase 3)

### Duas conversas no mesmo ALPN

Quem recebe uma conexão olha o nó de quem conecta (a chave autenticada pelo TLS do QUIC):

- **um contato estabelecido**: é uma conexão de mensagens. Cada frame é um `message` (ou `pre_key_message`) da sessão do libsignal; quem recebe decifra, aplica e grava numa transação, e só então responde `ack`. Até 1024 mensagens por conexão, 30 segundos sem nada e ela fecha. Uma mensagem que não decifra recebe `refused`;
- **qualquer outro nó**: é um aperto de mão, como acima.

Um contato que conecta mostra também de onde fala: o endereço vai para a frente da lista dele (só os da rede local), e o que esperava por ele sai na hora.

### Caixa de saída e caixa de entrada

- **Mandar** é gravar a mensagem, cifrar e guardar o cifrado na caixa de saída, numa transação só com o avanço do ratchet. A rede manda na ordem, um contato por vez, e só tira da caixa com o `ack`. O app pode fechar no meio: o reenvio manda os mesmos bytes, e nenhuma chave é gasta à toa.
- **Receber** é idempotente: o mesmo cifrado de novo (o `ack` se perdeu) o libsignal reconhece como repetido, e recebe só o `ack`. O `message_id` também é único por conversa.
- O que decifra mas não serve (fora do formato, fora do prazo, de um alvo que não é do contato) é descartado **e confirmado**, para não voltar para sempre.
- A caixa é tentada de novo a cada 20 segundos, quando há algo novo e quando o contato conecta.

### Ordem e prazos

- Ordem por um relógio de Lamport por conversa; empate pelo `sent_at` e pela ordem de chegada. Um contato não empurra o relógio mais que 2³² de uma vez.
- Texto: até 4000 caracteres, sem caracteres de controle além de `\n` e `\t`; o `\r` vira `\n`.
- **Editar**: só a própria mensagem de texto, por 15 minutos. **Apagar para todos**: por 24 horas; o texto sai do banco e da busca nos dois aparelhos, e as reações vão junto. Quem recebe confere o prazo pela hora em que recebeu (com 5 minutos de folga), não pelo relógio de quem manda.
- **Chamar atenção**: uma vez a cada 10 segundos por conversa; quem recebe ignora o que vier antes disso.
- **Recibos de leitura** e **digitando**: desligar vale para os dois lados. Sem os recibos, não se manda e não se aplica.
- **Digitando** vai só para um contato que falou com a gente há menos de 90 segundos, e é jogado fora se não sair na hora: cada aviso gasta uma chave do ratchet, e os perdidos viram chaves puladas do outro lado, que o libsignal limita.
- **Perfil**: trocar o nome manda o `profile` a cada contato; quem recebe só aceita uma versão maior que a guardada.

### O nó entre uma abertura e outra

- A porta UDP fica guardada no banco e é a mesma na próxima abertura (se estiver ocupada, vai outra, que fica guardada). Assim, o endereço que os contatos têm continua valendo.
- Ao ligar, o nó abre uma conexão vazia com cada contato: quem recebe aprende o endereço de agora e entrega o que esperava.
- Se os dois aparelhos mudam de IP ao mesmo tempo, quem os junta de novo é a descoberta por mDNS (a seguir) e, com a internet ligada, o `Addrs`.

## A internet e os retransmissores (fase 5)

- Os dois começam desligados (`network`, migração 5). Desligada, o nó não usa IP público nem retransmissor de contato nenhum, e não manda os seus.
- Ligada, o nó confere os endereços a cada 15 segundos; o que mudou e ficou igual por duas conferências vai a todos os contatos num `Content.addrs`, pela sessão (cifrado, só para eles). Os últimos mandados ficam no banco, para não repetir a cada abertura.
- Com um retransmissor escolhido, o endpoint do iroh fica com ele (`RelayMode::Custom`): é por ele que o iroh descobre o próprio endereço público, combina o furo do NAT e, se o furo falhar, repassa os pacotes, já cifrados pelo QUIC e pela sessão. A descoberta por DNS/pkarr continua desligada.
- Sem retransmissor, só conecta se um dos dois aceitar conexões de fora (um IPv6 público sem bloqueio, uma porta aberta). Um NAT simétrico, comum em redes móveis, não deixa: a conversa mostra por quê.
- O nó guarda, em memória, por onde alcançou cada contato da última vez (rede local, internet direta, retransmissor, ou não alcançou), pelo caminho que a conexão do iroh escolheu.

## Os arquivos (fase 6)

- Quem manda gera um `file_id` (16 bytes) e uma chave (32 bytes) aleatórios por arquivo e corta o conteúdo em fatias de 60 KiB (a última pode ser menor; um arquivo vazio tem uma fatia vazia).
- Cada fatia é cifrada com AES-256-GCM: nonce = `0u32 || índice (u64, big-endian)`, AAD = `file_id || índice (u64, big-endian) || última (1 byte)`. A chave é só deste arquivo, então o nonce por contador não se repete; o AAD impede trocar a ordem, misturar arquivos ou cortar o fim.
- O blob guardado é a sequência das fatias cifradas, igual nos dois aparelhos. O hash (BLAKE3) é do arquivo em claro, conferido quando a última fatia chega; se não bate, o blob é apagado e o arquivo fica como falho.
- A oferta (`FileOffer`) vai pela sessão. Quem recebe confere: `file_id` de 16, chave de 32, hash de 32, até 1 GiB, miniatura até 24 KiB; o nome perde o caminho e os caracteres de controle. Uma oferta com um `file_id` já conhecido é ignorada.
- Até 32 MiB, baixa sozinho; acima, espera quem usa pedir.
- As fatias vão numa conexão de contato (o ALPN `chirp/1`): o primeiro frame é um `FileRequest` com o `from` (a primeira fatia que falta), e a resposta é um `FileChunk` por fatia, na ordem. Quem serve só responde por um arquivo que ofereceu **àquele** contato; qualquer outro pedido é um `Refused`, sem motivo. Quem baixa confere cada fatia (o índice, o tamanho e a etiqueta do AES-GCM) antes de gravar, e retoma de onde parou numa próxima conexão.
- Fotos (JPEG e PNG) são decodificadas e codificadas de novo antes de sair: o EXIF (com a localização) não passa, e a rotação dele é aplicada antes. Uma foto que não se decodifica não sai. A miniatura é um JPEG de até 320 px, feito no aparelho de quem manda.

## A caixa postal (fase 7, ALPN `chirp-mailbox/1`)

Um servidor de quem usa (o binário `chirp-mailbox`, `core/chirp-mailbox/`), que guarda o que os contatos não conseguiram entregar direto. Não tem chave de nada: guarda o mesmo `Frame` que iria pela conexão, já cifrado pela sessão do Signal.

**Ligar** (dono e caixa): `chirp-mailbox pair` cria um código de uso único, que vale 24 horas, e mostra o link:

```
chirp://mailbox#<base64url sem preenchimento de>
versão (1, = 1) || nó da caixa (32) || código (32) ||
n (1, até 8) || n × [ 4 || IPv4 (4) || porta (2)  |  6 || IPv6 (16) || porta (2) ] ||
[ m (1, de 1 a 200) || retransmissor (m, URL em UTF-8) ]
```

O app conecta ao nó do link e manda `Pair { token }`. A caixa guarda só o SHA-256 do código e apaga ao usar; o dono passa a ser o nó da conexão (o TLS do QUIC autentica). Qualquer byte fora do lugar no link recusa tudo.

**Frames** (`tamanho (u32, big-endian) || Frame`, até 64 KiB + 1 KiB, versão 1, um stream bidirecional por conexão):

```
Frame { version = 1; oneof body {
  Pair pair = 2;          // { bytes token = 1 }                 qualquer um
  Done done = 3;          // {}                                  a resposta de sucesso
  Refused refused = 4;    // {}                                  sem motivo
  SetDrops set_drops = 5; // { repeated bytes hashes = 1 }       só o dono; troca todas
  Deposit deposit = 6;    // { bytes drop = 1; bytes envelope = 2 }   quem tem uma ficha
  Fetch fetch = 7;        // { uint64 after = 1 }                só o dono: os Item, e um Done
  Item item = 8;          // { uint64 seq = 1; bytes drop = 2 (o SHA-256); bytes envelope = 3;
                          //   uint64 stored_at = 4 }
  Remove remove = 9;      // { uint64 up_to = 1 }                só o dono: apaga até o seq
  Unpair unpair = 10;     // {}                                  só o dono: esquece tudo
  Publish publish = 11;   // { bytes lookup = 1; bytes bundle = 2; bytes drop = 3 (o SHA-256);
                          //   uint64 expires_at = 4 }          só o dono
  GetBundle get_bundle = 12; // { bytes lookup = 1 }             qualquer um
  Bundle bundle = 13;     // { bytes bundle = 1 }                a resposta ao GetBundle
}}
```

**As fichas**: cada contato estabelecido ganha uma ficha de 32 bytes aleatórios (`contacts.drop_token`), mandada pela sessão num `MailboxInfo`, com o nó e os endereços da caixa. A caixa recebe só o SHA-256 delas (`SetDrops`, quando o conjunto muda) e devolve o SHA-256 em cada `Item`: o dono sabe de que contato veio, e decifra com a sessão **daquele** contato. O que não decifra é descartado, então a caixa não consegue se passar por ninguém.

**Mandar**: quando a conexão a um contato falha (`Unreachable`) e ele tem caixa, o nó joga fora o "digitando" e deposita a caixa de saída dele, na ordem, um `Deposit` por envelope. Cada `Done` tira o envelope da caixa de saída e marca a mensagem como "na caixa postal" (`messages.in_mailbox`). Um `Refused` (cheia, ficha que não vale) para e deixa o resto na caixa de saída.

**Receber**: ao ligar o nó, a cada 60 segundos e quando um contato novo fecha o aperto de mão, o nó avisa os contatos que ainda não sabem da caixa (`contacts.mailbox_told`), manda o `SetDrops` se as fichas mudaram e busca: `Fetch { after }`, abre cada `Item` como se tivesse chegado direto (`messages::receive_from`) e manda `Remove` até o último lido. Uma falha do banco para antes e deixa o resto na caixa. Para o que é da conversa (texto, atenção, arquivo), um `Receipt.delivered` volta pela sessão: quem mandou passa de "na caixa postal" a "entregue".

**Desligar**: o app manda `Unpair` (se a caixa atender), apaga a caixa do banco e manda um `MailboxInfo` vazio a quem sabia dela.

**O primeiro contato pela caixa** (a parte assíncrona do PQXDH): com a caixa ligada, um convite novo publica nela o `Bundle` dele (o mesmo do `BundleRequest`), com

```
lookup = SHA-256("chirp-invite-lookup" || token)
drop   = SHA-256("chirp-invite-drop" || token)       (a ficha do Hello; a caixa recebe o SHA-256 dela)
```

e o convite ganha a parte da caixa. A caixa não vê o token, então não consegue montar um Hello (ele leva o token dentro da sessão). Quem lê o convite e não alcança quem convidou pede `GetBundle { lookup }` à caixa, confere as assinaturas das prekeys com a identidade do convite, como sempre, e deposita o Hello (um `PreKeyMessage`) com a ficha `drop`. No Hello vai a caixa de quem leu, se houver, com uma ficha para quem convidou. O contato fica pendente.

Quem convidou acha o Hello pela ficha (`invites.drop_hash`) e o aceita como um que chegou pela rede, com duas diferenças: o convite vale pela hora em que o Hello chegou à caixa (`stored_at`, nunca depois de agora), e o nó que o Hello diz não pode ser o de um contato que já existe (ninguém o autenticou). O Welcome vai para a caixa de saída: sai direto ou pela caixa de quem leu. Do outro lado, o Welcome chega por uma conexão do nó de quem convidou (o contato pendente é aceito nela) ou pela caixa, com a ficha do contato pendente. Um convite publicado fica no banco por mais 30 dias depois de vencer, para um Hello guardado antes ainda valer.

Na caixa, um convite publicado vale no máximo 7 dias, cada dono publica até 32, e o pacote de prekeys tem até 8 KiB.

**Os limites da caixa** (`Limits`): 20 mil envelopes e 256 MiB no total, 2 mil por ficha, 30 dias guardados, 4096 fichas por dono, 256 itens por `Fetch`. Os arquivos não passam pela caixa: a oferta vai, e as fatias continuam pedindo os dois online.

## A foto do perfil

- Quem usa escolhe uma imagem; o núcleo a decodifica (com a rotação do EXIF aplicada), corta o centro quadrado, reduz a até 512 px e codifica de novo em JPEG, baixando a qualidade e o tamanho até caber em 48 KiB. Nada do arquivo original além dos pixels sai do aparelho.
- Quem vê: ninguém, todos os contatos (o padrão) ou só os marcados (`contacts.photo_allowed`). A foto vai pela sessão num `Content.photo`, como uma mensagem: passa pela caixa postal e não pede os dois online.
- Cada contato guarda o que recebeu por último (`contacts.photo_sent`: nada, vazio ou o SHA-256 da foto). A cada mudança, e a cada rodada da caixa postal (ao ligar, a cada 60 segundos e com um contato novo), quem deve ver e não tem a foto de agora a recebe, e quem tinha e não deve mais recebe uma vazia. Quem nunca recebeu nada e não deve ver não recebe nada: não fica sabendo nem que há foto.
- Tirar alguém apaga a foto do app dele; uma cópia feita fora do app não volta, e o app diz isso.

## A descoberta na rede local (mDNS)

O serviço é `_chirp._udp.local.`, e o anúncio **não leva id fixo nem nome**. O nome da instância e o do host são um token de época:

```
época = segundos desde 1970 / 900          (15 minutos)
token = hex(HMAC-SHA256(chave de descoberta, "chirp-discovery-v1" || época (u64, big-endian))[0..10])
```

- O registro leva os IPs da rede local do aparelho (os mesmos do convite) e a porta do nó; nenhum TXT.
- A chave de descoberta (32 bytes) vai para cada contato dentro do `Peer`, cifrada, no aperto de mão. Quem acha um anúncio confere o token com o de cada contato, na época de agora e nas vizinhas (pela diferença dos relógios). Quem não é contato vê um número que muda a cada 15 minutos.
- Achou: os endereços (só os da rede local) vão para a frente da lista do contato, e a caixa de saída dele sai.
- O anúncio é refeito a cada época e quando os endereços mudam, e sai da rede quando o nó desliga.
- **O anúncio não é autenticado.** Qualquer um na rede pode repetir um token que viu, com outro endereço. Ele só diz "tente aqui": a conexão confere a chave do nó, e um endereço falso dá numa conexão recusada. Repetindo sem parar, dá para empurrar os endereços verdadeiros para fora da lista (8 por contato) até o próximo anúncio verdadeiro: uma negação de serviço de dentro da rede local, onde ela já é possível de outros jeitos.
- O mesmo IP e a mesma porta continuam ligando um anúncio ao outro para quem olha a rede: o token esconde quem é de quem não é contato, não esconde o aparelho da rede em que ele está.

Vetores: `token(32 zeros, 0) = a9b1226a9e540fb5b7bb` e `token(32 × 0x07, 1888888) = 1583b99009cc653054cc` (`discovery::tests`).

Por sistema: no iOS e no macOS, o `NSLocalNetworkUsageDescription` e o `_chirp._udp` no `NSBonjourServices`; no iOS, o multicast de verdade ainda pede à Apple o entitlement `com.apple.developer.networking.multicast`. No Android, falta pegar o `MulticastLock` (a permissão já está no manifesto). Sem mDNS, o resto funciona: só não se reencontra quem mudou de IP.

## O que os testes garantem

- `session::tests`: o aperto de mão inteiro e cada recusa:
  - um `Hello` reenviado ou um token gasto, desconhecido ou vencido;
  - um `Hello` repassado por outro nó, que é recusado sem deixar nada;
  - prekeys trocadas no meio, que a assinatura pega (a EC e a Kyber);
  - um `Hello` que um terceiro não consegue ler;
  - um `Welcome` de outro nó, ou um "aceite" que não responde a pedido nosso;
  - o próprio convite, ou o de quem já é contato;
  - dados do `Peer` fora do formato.
- `node::tests`: o mesmo sobre QUIC de verdade, entre nós no mesmo processo. O convite não serve a um terceiro, e ninguém respondendo não deixa nada no banco.
- `messages::tests`: o texto, o entregue e o lido; sem recibos; o reenvio depois de um `ack` perdido; 30 mensagens na fila com os dois escrevendo ao mesmo tempo, na mesma ordem nos dois aparelhos; responder, editar, reagir e apagar para todos (que tira da busca); os prazos, conferidos por quem recebe; o limite do chamar atenção nos dois sentidos; o digitando; o perfil novo; textos inválidos; um estranho que não injeta mensagem; a busca sem acento nem sintaxe do FTS; as páginas do histórico; nenhum texto em claro no arquivo do banco.
- `files::tests`: cifrar e decifrar em cada borda das fatias (vazio, 1 byte, uma fatia, uma a mais); copiar fatia por fatia dá o mesmo arquivo; uma fatia trocada de lugar, marcada como última, de outro arquivo ou de outra chave não abre; um blob adulterado ou com o hash errado falha; nomes de fora limpos; uma foto com EXIF (com "GPS") sai sem ele, com a miniatura.
- `messages::tests`: ofertas com chave curta ou grandes demais não entram; uma boa entra com o nome limpo, a repetida não vira outra mensagem, e uma grande espera.
- `node::tests` (fase 6): um arquivo vai de um nó ao outro sobre QUIC e baixa sozinho; cortado depois da primeira fatia, retoma só o resto; e um pedido de um arquivo não oferecido àquele contato é recusado.
- `network::tests`: os ajustes, os retransmissores recusados (sem `https`, com usuário, consulta, fragmento, controle, compridos, mais de três) e os endereços de contato conferidos.
- `node::tests` (fase 5): com um retransmissor de verdade (o do `iroh::test_utils`), dois nós que não sabem nenhum IP um do outro viram contatos pelo convite só com o retransmissor, e uma mensagem só pelo retransmissor chega e volta o "entregue". Com a internet desligada, um contato só com IP público e retransmissor nem é tentado, e fica "fora de alcance"; e o nó não anuncia nada público.
- `node::tests`: mensagens nos dois sentidos com os recibos, sobre QUIC de verdade, e a fila de quem estava desligado, entregue na ordem quando ele volta. E um contato que "mudou de endereço" (porta nova, e os dois com o endereço errado um do outro), achado só pelo mDNS: com o mDNS desligado, o mesmo teste falha.
- `discovery::tests`: o token muda com a época e com a chave, os vetores, as épocas vizinhas, um estranho que não casa com ninguém e os endereços que servem.
- `chirp_mailbox` (fase 7): o frame que vai e volta, o grande demais e a versão errada; o link em cada corte e com um byte a mais; a pasta da caixa (ligar com código vencido ou repetido, as fichas de outro dono, os limites, o prazo); e, sobre QUIC, ligar, depositar, só o dono buscar e apagar.
- `invite::tests`, `session::tests` e `node::tests` (fase 7, o primeiro contato): o convite com a caixa, com e sem retransmissor, em cada corte; o Hello pela caixa vale pela hora em que chegou e não toma o nó de um contato; e, com uma caixa de verdade, Bob convida e desliga, Alice lê e desliga, Bob volta e aceita, Alice volta e recebe o Welcome e um "oi", sem os dois nunca online juntos.
- `messages::tests` e `node::tests` (fase 7): a caixa chega aos contatos uma vez, com uma ficha só de cada um, e o desligar também; um `MailboxInfo` fora do formato é ignorado; e, com uma caixa de verdade, uma mensagem a um contato desligado fica "na caixa postal", ele busca ao voltar e o "entregue" chega a quem mandou. O código de ligação serve uma vez só.
- `photo::tests` e `messages::tests` (a foto): a imagem vira um JPEG quadrado no tamanho; uma foto cortada, em PNG ou comprida é recusada; e a foto chega a quem deve ver uma vez, sai de quem foi tirado, volta quando marcado e some com "ninguém".
- `wire::tests` e `invite::tests`: frames grandes demais, versões e lixo recusados; o convite truncado em cada posição é recusado; 20 mil entradas aleatórias não derrubam o leitor.

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
```

- O link é `chirp://invite#` e os bytes em base64url sem preenchimento. O QR é o mesmo link. Fica em torno de 180 caracteres.
- O token tem 32 bytes aleatórios, vale uma vez, por 24 horas, e o banco guarda só o SHA-256 dele.
- Os endereços são só os da rede local (IPv4 privado e IPv6 `fc00::/7`): o link mandado por outro canal não leva IP público.
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
                       PeerProfile profile = 11; };
          uint64 sent_at = 13 (ms, relógio de quem manda, só para mostrar);
          uint64 lamport = 14 (a ordem na conversa);
          bytes padding = 15; }
Hello    { bytes token = 1; PeerProfile profile = 2; Peer peer = 3; }
Welcome  { PeerProfile profile = 1; Peer peer = 2; }
PeerProfile { string display_name = 1; uint32 version = 2; }
Peer     { bytes endpoint_id = 1; repeated string addrs = 2; bytes discovery_key = 3; }
Text     { string text = 1; bytes reply_to = 2 (o message_id citado, ou vazio); }
Receipt  { repeated bytes read = 1 (até 256 message_ids lidos); }
Edit     { bytes target = 1; string text = 2; }
Delete   { bytes target = 1; }
Reaction { bytes target = 1; uint32 kind = 2 (1 a 6; 0 tira); }
Typing   {}
Nudge    {}
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
- Se os dois aparelhos mudam de IP ao mesmo tempo, quem os junta de novo é a descoberta por mDNS (a seguir).

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
- `node::tests`: mensagens nos dois sentidos com os recibos, sobre QUIC de verdade, e a fila de quem estava desligado, entregue na ordem quando ele volta. E um contato que "mudou de endereço" (porta nova, e os dois com o endereço errado um do outro), achado só pelo mDNS: com o mDNS desligado, o mesmo teste falha.
- `discovery::tests`: o token muda com a época e com a chave, os vetores, as épocas vizinhas, um estranho que não casa com ninguém e os endereços que servem.
- `wire::tests` e `invite::tests`: frames grandes demais, versões e lixo recusados; o convite truncado em cada posição é recusado; 20 mil entradas aleatórias não derrubam o leitor.

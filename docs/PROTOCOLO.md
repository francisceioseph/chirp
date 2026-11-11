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
          oneof body { Hello hello = 2; Welcome welcome = 3; };
          bytes padding = 15; }
Hello   { bytes token = 1; Profile profile = 2; Peer peer = 3; }
Welcome { Profile profile = 1; Peer peer = 2; }
Profile { string display_name = 1; uint32 version = 2; }
Peer    { bytes endpoint_id = 1; repeated string addrs = 2; bytes discovery_key = 3; }
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
- `wire::tests` e `invite::tests`: frames grandes demais, versões e lixo recusados; o convite truncado em cada posição é recusado; 20 mil entradas aleatórias não derrubam o leitor.

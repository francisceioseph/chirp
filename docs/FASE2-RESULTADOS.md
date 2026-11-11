# Fase 2: resultados

Rede local e aperto de mão (`docs/PLANO.md`, seção 13). O protocolo está em `docs/PROTOCOLO.md`.

## Feito

- **Sessão pelo libsignal** (`libsignal-protocol` v0.107.0, pela tag do git): PQXDH (X25519 e Kyber1024) e Double Ratchet. As lojas do libsignal ficam no banco cifrado (`session/store.rs`), na migração 2. Cada convite tem as prekeys dele (uma EC de uso único, uma assinada e uma Kyber), gastas no aperto de mão.
- **Convite** (`invite.rs`): QR e link (`chirp://invite#...`, uns 180 caracteres), com a identidade, o nó, os endereços da rede local e um token de uso único por 24 horas. As prekeys vêm pela rede, conferidas com a identidade do convite, para o QR continuar legível.
- **Aperto de mão** (`session/`): BundleRequest, Bundle, Hello e Welcome, com cada passo de quem recebe numa transação. As regras e o que cada teste garante estão no `PROTOCOLO.md`.
- **Rede local** (`node.rs`): iroh 1.4 (QUIC, TLS 1.3 com a chave do nó), com o preset `Minimal`, o relay desligado e as features padrão fora (sem UPnP, sem métricas). O nó fala só com os endereços de um convite. Até 8 apertos de mão ao mesmo tempo, 4 frames e 20 segundos cada.
- **Contatos** (`contacts.rs`): `Pending` e `Established`, e o "verificado" à parte. O número de segurança é o `Fingerprint` do libsignal: 60 dígitos, igual nos dois aparelhos, com a "Sua chave" do perfil como metade.
- **A impressão digital da fase 1 mudou** para bater com a do libsignal (faltava a chave depois do id, na primeira passada). Quem já tinha perfil vê outra "Sua chave"; como ainda não havia contatos, nada se perde.
- **App**:
  - a lista de contatos virou a tela principal, com o perfil no avatar do canto;
  - "Adicionar contato" tem duas abas: o meu código (QR, copiar o link, código novo) e colar um convite;
  - a tela do contato mostra o número de segurança e o "marcar como verificado";
  - quando alguém lê o meu QR, a tela fecha e avisa;
  - o `ContactsController` liga a rede e escuta o núcleo (`watch_contacts`, um `StreamSink`);
  - sem rede, a lista aparece com um aviso e o "tentar de novo".
- As mensagens novas nos sete idiomas, e o `protoc` no CI (o libsignal compila os `.proto` dele).

## Conferido

- Rust: 53 testes, `clippy -D warnings` e `fmt`. Os testes do aperto de mão cobrem a saída da fase: um terceiro na rede não se passa por ninguém. Um Hello repassado por outro nó, prekeys trocadas no meio, um Hello lido por quem não é o destino, um aceite que não responde a pedido nosso, convites gastos ou vencidos: tudo recusado, sem deixar nada no banco.
- O nó, rastreado com `strace` num teste de dois nós: só falou com os endereços do próprio aparelho. Nada de DNS, relay ou servidor; os `connect` para `10.254.254.254` são o truque de UDP para achar a interface de saída e não mandam pacote.
- Dart: 101 testes. Cobrem os contatos com o núcleo falso, cada falha do convite com a mensagem dela, o QR e o link copiado, alguém que lê o meu código, o número de segurança e o verificado, e as telas novas na janela mínima e num celular pequeno, nos dois temas, com contraste e rótulos. O `flutter analyze` não acusa nada.
- O `integration_test` no Linux, com o núcleo, o banco e a rede de verdade.

## Revisão

O que a revisão do diff pegou e já foi corrigido:

- **Verificado**: quem mostra o QR nascia "verificado", mas não conferiu a chave de quem leu. Um QR fotografado e usado por outra pessoa daria um contato verificado falso. Agora só quem lê o QR nasce verificado.
- **IP no link**: o convite levava o IPv6 público, que vazaria num link mandado por outro canal. Agora só vão endereços privados.
- **Dados do outro lado**: os endereços e a chave de descoberta não eram conferidos. Agora têm limite e formato.
- **Convites vencidos**: eles e as prekeys deles ficavam para sempre no banco. Agora saem a cada convite novo.
- **Apertos de mão sem teto**: não havia limite de apertos de mão simultâneos. Agora são 8.
- **Tela de adicionar**: ela não fechava quando alguém lia o QR, porque contava o contato novo como já conhecido.

## Ficou para a fase 3

- **Descoberta por mDNS com tokens rotativos.** Ela serve para reencontrar um contato quando o IP muda, e só faz falta quando houver mensagens para entregar. A chave de descoberta já é trocada no aperto de mão.
- **Aceitar à mão um contato vindo de link.** Precisa da entrega assíncrona (a outbox) da fase 3. Por enquanto, o link entra direto, não verificado, e o token vale uma vez.
- **Ler o QR pela câmera.** Por enquanto se cola o link, e o app diz isso na tela. A câmera vem com o `mobile_scanner`, no celular e no macOS.

## Decisões tomadas por padrão

- **`libsignal`** (decisão 2 do plano), pelo pós-quântico. Ele é **AGPL-3.0**: o app continua GPL-3.0-or-later no código dele, mas o binário que leva o libsignal segue a AGPL-3.0. A GPLv3 permite essa combinação (seção 13). Para as lojas, isso pesa; agora não.
- **iroh** para a rede (decisão 3), só local nesta fase.
- Compilar o núcleo agora pede o `protoc` (`apt install protobuf-compiler`).

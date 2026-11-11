# Fase 3: mensagens 1:1

O que a fase 3 do `docs/PLANO.md` (seção 13) pediu, o que foi feito e o que ficou. O formato no fio está no `docs/PROTOCOLO.md`.

## Feito

- **Núcleo** (`messages.rs`, migração 3):
  - texto (até 4000 caracteres), responder citando, editar (15 minutos), apagar para mim e para todos (24 horas), reações de um conjunto fixo de seis, chamar atenção (uma vez a cada 10 segundos);
  - recibos de entregue (o `ack` do transporte) e de lida (cifrado, desligável), e o "digitando" (desligável, só para quem está online);
  - a ordem por um relógio de Lamport por conversa;
  - a caixa de saída transacional e a caixa de entrada idempotente: o app pode fechar no meio sem perder nem duplicar nada;
  - a busca no histórico pelo FTS5, dentro do banco cifrado, sem acento nem caixa;
  - o perfil novo vai a cada contato quando o nome muda.
- **Rede** (`node.rs`): a conexão de mensagens ao lado do aperto de mão, a entrega na ordem com o `ack`, a nova tentativa a cada 20 segundos, a porta guardada entre as aberturas, o aviso aos contatos ao ligar e o endereço aprendido de quem conecta.
- **Descoberta** (`discovery.rs`): o mDNS com o token de época (HMAC da chave de descoberta, trocado a cada 15 minutos), sem nome nem id fixo no anúncio. Reencontra um contato que mudou de IP.
- **App**:
  - a tela principal virou a lista de conversas (a última mensagem, a hora, as não lidas, o "digitando…");
  - a conversa: as bolhas, a citação, editada, o estado (relógio, um tique, dois tiques), as reações, o chamar atenção que treme a tela, e as opções por segurar, pelo botão direito ou pelo teclado;
  - no computador, Enter manda e Shift+Enter quebra a linha;
  - a busca em todas as conversas;
  - no perfil, os recibos de leitura e o "digitando";
  - os detalhes do contato (o número de segurança) pelo título da conversa;
  - 44 textos novos nos sete idiomas.

## Conferido

- Rust: 74 testes, `clippy -D warnings` e `fmt`. Os de `messages` cobrem cada recurso sem rede; os de `node`, as mensagens sobre QUIC de verdade, a fila de quem estava desligado, que chega na ordem quando ele volta, e um contato que mudou de endereço, achado só pelo mDNS (com ele desligado, o teste falha).
- O nó, rastreado com `strace` no teste da descoberta: só mandou pacotes aos endereços do próprio aparelho (IPv4 e os IPv6 dele, entre os dois nós do teste), ao multicast do mDNS (`224.0.0.251` e `ff02::fb`) e ao endereço falso do teste. Nada de DNS, relay ou servidor.
- Dart: 138 testes, com o núcleo falso: mandar e receber, as não lidas, os recibos, o digitando, responder, editar, apagar, reagir, chamar atenção e o limite dele, o Enter, o teclado nas opções, a busca e os ajustes; e as telas novas na janela mínima e num celular pequeno, nos dois temas, com contraste e rótulos. O `flutter analyze` não acusa nada.
- `integration_test/messages_test.dart` no Linux: dois bancos de verdade no mesmo processo, pela ponte, viram contatos e conversam (entregue, lida, resposta, reação, edição, chamar atenção, busca e ajustes).
- Entre dois computadores: o app de Windows (o pacote do CI, na VM) e o `examples/invite_host.rs` no Linux, que responde cada texto com um eco. O Windows colou o link, os dois viram o mesmo número de segurança, o texto chegou, o eco voltou citando, o Linux viu a mensagem dele como lida e recebeu o chamar atenção. O firewall do Windows pergunta na primeira abertura, e recusar não atrapalha quem conecta para fora.

## Revisão

O que a revisão do diff pegou e já foi corrigido:

- **"Digitando" para quem está desligado**: cada aviso gasta uma chave do ratchet, e os que não saem viram chaves puladas do outro lado. O libsignal aceita até 25 mil: semanas digitando para alguém desligado quebrariam a sessão. Agora o aviso só sai para quem falou com a gente nos últimos 90 segundos.
- **Fim de linha do Windows**: um `\r` colado fazia o núcleo recusar a mensagem. Agora vira `\n`.
- **Relógio de quem manda**: o "digitando" era descartado se os relógios dos dois diferissem mais de 5 minutos. Agora não depende dele.
- **Trocar o nome**: uma falha ao avisar os contatos devolvia erro, com o nome já trocado. Agora o nome troca, e o aviso fica para depois.
- **Carregar as antigas**: rolar rápido podia pedir a mesma página duas vezes e duplicar mensagens na tela.
- **macOS sem rede**: o app de release rodava no sandbox sem as permissões de rede (da fase 2), e não conectaria a nada. Agora tem as de cliente e servidor, e o pedido de rede local do macOS 15. O texto do iOS ainda era do protótipo.
- **Teclado e sugestões**: as opções de uma mensagem não tinham caminho pelo teclado, e o campo de mensagem aceitava as sugestões do teclado. Agora têm, e não aceita.

## Ficou para depois

- **O `MulticastLock` no Android** (sem ele, o mDNS pode não receber nada lá) e o entitlement de multicast da Apple no iOS. Sem mDNS, o resto funciona; só não se reencontra quem mudou de IP.
- **Aceitar à mão um contato vindo de link** (docs/PLANO.md, 6.3). O link continua entrando direto, não verificado.
- **Formatação leve** (negrito, itálico, código) e a lista de contatos em grupos.
- **Sons** de mensagem e de contato, com o "não perturbe", ficam com as notificações da fase 6.
- **Uma mensagem que nunca decifra** (uma sessão corrompida) fica na caixa de saída, tentando de novo. Falta um jeito de refazer a sessão.

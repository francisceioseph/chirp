# Fase 5: internet

O que a fase 5 do `docs/PLANO.md` (seção 13 e seção 7.3) pediu, o que foi feito e o que ficou. O formato está no `docs/PROTOCOLO.md`.

## Feito

- **Núcleo** (`network.rs`, migração 5): a internet e até três servidores de retransmissão, os dois desligados por padrão. Um retransmissor é `https://` (ou `http://`, para uma rede própria), sem usuário, senha, consulta nem fragmento.
- **O nó** (`node.rs`):
  - com a internet desligada, nada muda: só endereços da rede local, sem IP público nem retransmissor de ninguém;
  - ligada, os endereços públicos entram no convite e no que vai aos contatos, os da rede local primeiro (o iroh tenta todos e fica com o melhor caminho, então a rede local ganha quando dá);
  - com um retransmissor, o endpoint do iroh usa ele para descobrir o endereço público, furar o NAT e, se não der, repassar. A descoberta por DNS/pkarr continua desligada; nenhum servidor é padrão;
  - os endereços novos vão aos contatos pela sessão (`Content.addrs`), quando mudam e ficam iguais por duas conferências;
  - por onde cada contato foi alcançado (rede local, internet direta, retransmissor, fora de alcance), pelo caminho da conexão;
  - mudar os ajustes religa o nó, e os eventos da UI continuam (o canal ficou no `ChirpStore`).
- **O convite** leva o retransmissor no fim, só quando há um; sem ele, os bytes são os de antes.
- **App**:
  - no perfil, o cartão **Rede**: a local sempre ligada, a internet e os retransmissores, cada um com o que revela (o IP público aos contatos; ao retransmissor, os IPs e quando se conversa), a linha de estado (sem retransmissor, esperando, conectado) e o aviso quando um endereço não serve;
  - na conversa, quando o contato não foi alcançado, **o porquê**: só a rede local ligada (ligue a internet), internet sem retransmissor (o direto não passa, e por quê) ou com retransmissor (o contato parece desligado). As mensagens esperam;
  - no contato, por onde ele foi alcançado;
  - 23 textos novos nos sete idiomas.

## Conferido

- Rust: 91 testes, `clippy -D warnings` e `fmt`. Os novos:
  - com um retransmissor de verdade (o do `iroh::test_utils`, sobre sockets de verdade), dois nós que não sabem IP nenhum um do outro viram contatos por um convite só com o retransmissor, e uma mensagem só pelo retransmissor chega e volta o "entregue";
  - com a internet desligada, um contato só com IP público e retransmissor nem é tentado e fica "fora de alcance", e o nó não anuncia nada público;
  - os ajustes, os retransmissores recusados, os endereços de contato conferidos, o `Addrs` na sessão (o mesmo de novo e lixo não mudam nada), o convite com e sem retransmissor, e religar o nó pela API;
  - os testes dos retransmissores usam o loopback: nenhum teste procura servidor de fora.
- Dart: 197 testes. O `network_test`: ligar a internet, um retransmissor recusado e um aceito, removido, a linha de estado, os três porquês na conversa e o aviso que some quando o contato volta, o caminho no contato, e tudo em 240×160 e 320×568, com contraste e rótulos.

- `integration_test` no Linux: os dois passam (a conversa pela ponte e o banco de verdade).

## Revisão

O que a revisão pegou e já foi corrigido:

- **O app não saía depois de desligar a rede.** O canal de eventos foi para o `ChirpStore` para sobreviver a um religamento, e com isso o fluxo do Dart nunca fechava: o teste de integração terminava, mas o processo ficava vivo. Agora o `stop_network` fecha o fluxo (`NodeEvent::Closed`), e só o religamento pelos ajustes o mantém.
- **Aviso demais na conversa.** Ao ligar, o nó procura todos os contatos, e qualquer um desligado ficava "fora de alcance". O aviso só aparece quando há uma mensagem minha esperando.
- **Um teste que procuraria um servidor de fora.** O teste da API usava `relay.example.org` com o nó ligado; passou para o loopback.
- **O `Addrs` não chegava.** O `oneof` do `Content` lista as tags à mão, e a 12 faltava: o conteúdo novo era lido como vazio. O teste do `messages` pegou.

## Falta

- **Conversar de verdade entre duas redes diferentes**, com um `iroh-relay` próprio na internet e um NAT simétrico. O teste do retransmissor roda no mesmo aparelho; entre a VM do Windows e o Linux falta o build do Windows, que depende do CI (parado pela cobrança do GitHub).
- O `Transport` e o roteador da seção 7.1 como camadas próprias: hoje o iroh faz a escolha do caminho (rede local, direto, retransmissor) sozinho, e o "LAN antes da internet" sai dele. O roteador entra quando houver um segundo transporte (o Bluetooth, fase 8).
- No celular, a rede muda o tempo todo: o aviso de endereços novos espera até 30 segundos.

# Modelo de ameaças do Psito Chirp

O que o Chirp protege, contra quem, e o que fica de fora. Vale para a versão 1.0: um mensageiro 1:1 na rede local e na internet. O plano completo, com o que vem depois, está no [`PLANO.md`](PLANO.md) (seção 3), e o protocolo no [`PROTOCOLO.md`](PROTOCOLO.md).

## O que o Chirp guarda e o que manda

- **No aparelho**:
  - a identidade (a chave do nó e a do Signal);
  - os contatos;
  - as conversas;
  - os arquivos recebidos.

  Tudo num banco SQLCipher, com o `secure_delete` ligado. A chave do banco são 32 bytes aleatórios no cofre do sistema (Keychain, Credential Manager, Keystore, Secret Service). Sem cofre, ela vem de uma senha, pelo Argon2id. Ela nunca fica em claro no disco. Os arquivos recebidos ficam na pasta do app, e o Android não faz backup dela (`allowBackup=false`).
- **Na rede**: o envelope cifrado, dentro de uma conexão QUIC autenticada pela chave do nó (o `iroh`). Na rede local, também um anúncio mDNS.
- **No Bluetooth, se você ligar** (desligado por padrão): um anúncio com o UUID do Chirp e um token que muda a cada 15 minutos, e, com um contato por perto, o mesmo envelope cifrado dentro de um canal Noise, em que cada lado prova a chave do nó.
- **A foto do perfil, se você puser uma**: só para os contatos que você deixar, pela sessão, refeita no aparelho (quadrada, até 512 px, sem a localização nem outros dados do arquivo).
- **Na caixa postal, se você ligar uma** (um servidor seu, ou de quem você confia, rodando o `chirp-mailbox`): o que os contatos mandaram com o seu aparelho desligado, no mesmo envelope cifrado, até você buscar (no máximo 30 dias). A caixa não tem chave de nada.
- **Em servidor nosso**: nada. Não há conta, número de telefone, registro nem telemetria. O app não verifica atualizações sozinho.

## Contra quem protegemos

| Quem | O que consegue | O que o Chirp faz |
|---|---|---|
| Alguém na mesma rede local (café, faculdade) | Ver, injetar, repetir e derrubar pacotes | O canal QUIC confere a chave do nó, e o conteúdo vai no Double Ratchet. O anúncio mDNS não leva id fixo nem nome: é um token que muda a cada 15 minutos, que só os contatos reconhecem. Um anúncio repetido só leva a uma conexão que falha. |
| O provedor de internet, o Estado, quem opera um retransmissor | Ver IPs, horários e tamanhos; bloquear | O conteúdo é cifrado de ponta a ponta. O tamanho vai preenchido até um degrau (256 B, 1 KiB, 4 KiB, 16 KiB, 60 KiB), e os arquivos vão em fatias do mesmo tamanho. A internet e os retransmissores vêm desligados, e nenhum retransmissor é padrão. |
| Quem grava tudo hoje para decifrar com um computador quântico amanhã | "Colher agora, decifrar depois" | O acordo de chaves é híbrido: o PQXDH, com X25519 e ML-KEM (Kyber1024). |
| Quem rouba as chaves de um aparelho por um tempo | Ler o estado das sessões | O sigilo futuro impede ler o passado, e a recuperação do Double Ratchet volta a proteger o futuro depois de alguns turnos. |
| Quem pega o aparelho desligado ou uma cópia do disco | Ler os arquivos do app | O banco é cifrado, com a chave no cofre do sistema. O "Apagar tudo" apaga o banco, os arquivos e a chave do cofre. |
| Quem se passa por um contato | Conversar no lugar dele | A primeira troca é por QR ou por um convite que vale uma vez e por 24 horas. Depois, a identidade fica presa ao contato: outra chave com o mesmo nome é recusada. O código de segurança de cada contato serve para conferir pessoalmente. |
| Quem opera a caixa postal (ou a invade) | Ver o nó do dono, os IPs de quem deposita, os horários, os tamanhos e quantos contatos diferentes mandam; apagar ou segurar envelopes; encher a caixa; ver as prekeys públicas dos convites publicados e quando alguém as busca | O conteúdo é o mesmo envelope do Double Ratchet, e o que não decifra com a sessão do contato é jogado fora: a caixa não lê nem inventa mensagens. Cada contato tem uma ficha própria, e a caixa só guarda o SHA-256 delas. Um convite publicado é achado por um hash do token, e a caixa não vê o token: não consegue usar o convite nem trocar as prekeys (a assinatura é conferida com a identidade do convite). Apagar ou segurar aparece como "na caixa postal" que não vira "entregue". Nenhuma caixa é padrão. |
| Um contato que quer atrapalhar | Encher a sua caixa | Cada ficha tem um teto (2 mil envelopes), e a caixa inteira outro (20 mil e 256 MiB). |
| Alguém com um rádio Bluetooth por perto (dezenas de metros) | Ver que há um Chirp ali, seguir o aparelho enquanto o token não muda, repetir um anúncio, escutar e mexer no canal | O Bluetooth vem desligado. O anúncio não leva nome nem id fixo, e só os contatos reconhecem o token. O canal é cifrado pelo Noise e cada lado prova a chave do nó: um anúncio copiado dá numa conexão em que nada é mandado, e um byte mudado derruba o canal. Por dentro, o mesmo Double Ratchet. |
| Um membro de um grupo | Ver os outros membros (nome, chave de identidade e nó), e o que eles escrevem no grupo | O grupo só entra com um convite do admin, que é contato de quem recebe. Só o admin muda o nome e os membros, e cada mensagem vai pela sessão a dois: um membro não fala em nome de outro, nem edita ou apaga a mensagem de outro. Quem sai, ou é tirado, para de receber na hora, sem chave de grupo para trocar. |
| O admin de um grupo | Pôr no grupo quem quiser, com o nome que quiser; repassar (ou não) os convites que apresentam os membros entre si | A chave de cada convite repassado tem de ser a do membro na lista do grupo, então o admin não troca um membro por outro no meio do caminho; mas é ele quem diz quem é membro. Para ter certeza de alguém, confira o código de segurança com essa pessoa. |
| Um estranho por perto | Mandar pedidos em massa | Ninguém vira contato sem um convite, e há um teto de 8 apertos de mão ao mesmo tempo. |

## O que fica de fora

Estes limites estão declarados também na página do projeto.

- **Um aparelho com malware ou com root do adversário.** Quem controla o sistema lê a tela, o teclado e a memória.
- **Esconder *que* você usa o Chirp.** Quem observa a rede local vê o mDNS (`_chirp._udp`) e o tráfego QUIC. Com o Bluetooth ligado, quem procura por perto vê o UUID do Chirp; e, enquanto um token vale (até 15 minutos), pode seguir o aparelho, se o sistema não trocar o endereço Bluetooth nesse meio.
- **O seu IP.**
  - Com a internet ligada, os contatos veem o seu IP público, porque a conexão é direta.
  - Um retransmissor que você configurou vê os IPs e os horários das conversas, mas não o conteúdo.
  - Ainda não há o Tor (fase 12).
- **Os horários e o volume.** Os tamanhos são preenchidos, mas os horários não. Ainda não há tráfego de cobertura.
- **A caixa postal sumir.** Se ela ficar fora do ar, ou for desligada com mensagens dentro, essas mensagens se perdem: quem mandou continua vendo "na caixa postal", sem o "entregue".
- **O que o contato faz com o que você manda**: guardar, encaminhar, capturar a tela. Isso vale para a foto do perfil: tirar alguém dos que veem apaga a foto do Chirp dele, não uma cópia que ele já tenha feito.
- **As notificações.** O sistema mostra e pode guardar o que estiver nelas. O modo "Sem conteúdo" mostra só "Nova mensagem".
- **O microfone.** Ele só liga enquanto se grava uma nota de voz, e a nota vai cifrada como qualquer arquivo. Quem controla o sistema ouve o microfone de qualquer jeito.
- **O que o teclado do sistema aprende.** Os campos pedem ao teclado para não aprender, mas a decisão é do teclado.

## Ainda não feito, e previsto

- Senha do app e senha de pânico.
- Bloquear um contato.
- Mensagens temporárias.
- Bloquear capturas de tela no Android e no iOS.
- Tor (fase 12) e tráfego de cobertura.
- Auditoria externa (fase 12).
- Builds reprodutíveis, para comparar o binário com o código.

## Como relatar uma falha

Veja o [`SECURITY.md`](../SECURITY.md): pelo relato privado do GitHub, sem abrir uma issue pública.

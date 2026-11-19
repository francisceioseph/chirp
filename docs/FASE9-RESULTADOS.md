# Fase 9: grupos

O que a fase 9 do `docs/PLANO.md` (seção 13, com a 6.8) pediu, o que foi feito e o que ficou. A fase vai em partes: os grupos entre contatos primeiro, depois apresentar os membros entre si e o resto do que uma conversa a dois já tem.

## Parte 1: grupos entre contatos

### Feito

- **Decisão**: sem Sender Keys. Cada mensagem vai a cada membro pela sessão a dois (o *fan-out*). Sem servidor, cada membro recebe a sua cópia de qualquer jeito, então as Sender Keys só economizariam a cifra. E perderiam a recuperação do Double Ratchet depois de um vazamento, e pediriam a rotação a cada saída. Com até 64 membros, o custo é pequeno.
- **Núcleo** (`groups.rs`, migração 14):
  - o grupo é uma linha de `contacts` (o estado `Group`), então a lista de conversas, o histórico, a busca e a tela da conversa são os mesmos; os membros e o admin ficam em `groups` e `group_members`;
  - criar, renomear, adicionar, tirar e sair; só o admin muda, e o `GroupUpdate` leva o grupo inteiro numa versão;
  - quando o admin sai, o novo é o membro de menor chave de identidade, a mesma conta em todos;
  - no grupo: texto, editar e apagar (só do autor), e a resposta citando; a mensagem diz quem escreveu.
- **App**:
  - "Novo grupo" na lista (com algum contato): o nome e quem entra;
  - a conversa do grupo, com o nome de quem escreveu em cada bolha, sem chamar atenção, anexo, nota de voz e reações (vieram na parte 3);
  - a página do grupo: os membros (o admin marcado, e quem não é contato avisado), e, para o admin, adicionar, renomear e tirar; sair pergunta antes e deixa a conversa só para ler;
  - 20 textos novos nos sete idiomas.
- **Documentos**: o formato no `PROTOCOLO.md` e o que um membro e o admin veem e podem no `AMEACAS.md`.

### Conferido

- Rust: sete testes novos com três aparelhos e um "carteiro": o grupo criado chega aos dois e todos escrevem nele, com o "entregue"; editar e apagar chegam, e um membro não apaga a mensagem de outro; só o admin muda (um update forjado por outro membro, com versão maior, é ignorado); tirar alguém faz ele saber e parar de receber, e adicionar de novo volta; o admin sai e o de menor chave assume; um membro que não é contato aparece e não recebe; updates estranhos (id curto, admin de fora, membro repetido, nome com controle de direção, sem quem recebe) não criam nada.
- Dart: seis testes novos: criar e escrever, o autor em cada bolha e sem reações, o admin renomeia, tira e sai, quem não é admin só vê, e o grupo em 240×160 e 320×568.

### Falta (da parte 1)

- Reações, arquivos, notas de voz, chamar atenção, "digitando" e recibos de leitura no grupo.
- A foto do grupo e mais de um admin.
- Um admin que saiu e volta a ser adicionado pelo novo admin não aceita o grupo (o admin guardado com ele é ele mesmo).

## Parte 2: apresentar os membros entre si

### Feito

- **Núcleo** (migração 15, o `GroupIntro`, conteúdo 22): de cada par de membros que não se conhecem, o de menor chave cria um convite e manda ao admin, que repassa ao outro; quem recebe confere que a chave do convite é a do membro e entra nele, pela rede ou pela caixa postal. O nó faz isso ao ligar, a cada 60 segundos e quando um grupo muda, e manda de novo um convite que não virou contato em 24 horas.
- O contato que nasce assim fica fora da lista de conversas até alguém escrever a dois.
- **App**: o membro que ainda não é contato aparece como "sendo apresentado pelo admin", e o texto do grupo diz como funciona, nos sete idiomas.

### Conferido

- Rust: só o de menor chave convida, e não de novo antes de um dia; o admin repassa entre membros e não para quem está fora do grupo, nem um convite que não é link do Chirp; e, de ponta a ponta com três nós de verdade, Ana faz um grupo com Bia e Caio, que não se conhecem: os dois viram contatos pelo convite repassado, ficam fora da lista de conversas, e a mensagem de Bia no grupo chega a Caio.

### Falta (da parte 2)

- Se o admin não é contato de um membro (depois que o admin de antes sai), esse membro não é apresentado.
- Reações, arquivos, notas de voz, chamar atenção, "digitando" e recibos de leitura no grupo.
- A foto do grupo e mais de um admin.
- Um admin que saiu e volta a ser adicionado pelo novo admin não aceita o grupo.

## Parte 3: arquivos e reações no grupo

### Feito

- **Núcleo** (migração 16, `group_reactions`): a reação de cada membro, uma por mensagem; o arquivo e a nota de voz oferecidos a cada membro, baixados do autor pela sessão a dois com ele, e entregues só a quem é membro agora.
- **App**: anexo, nota de voz e reações na conversa do grupo; a bolha mostra cada tipo de reação uma vez e, quando há mais de uma do mesmo, quantas são ao todo; o leitor de tela diz quem reagiu com o quê. Num grupo de que saí, sem anexo nem reação.

### Conferido

- Rust: as reações de dois membros ficam separadas, trocar substitui e 0 tira; o arquivo de um membro chega aos outros, é baixado dele, e quem foi tirado do grupo não consegue buscar.
- Dart: o anexo na conversa do grupo, as reações dos outros com a contagem e o rótulo para o leitor de tela, e sem anexo nem reações num grupo de que saí.

### Falta

- Um arquivo de quem ainda não é contato espera a apresentação.
- A foto do grupo e mais de um admin.
- Um admin que saiu e volta a ser adicionado pelo novo admin não aceita o grupo.

## Parte 4: "digitando" e "lida" no grupo

### Feito

- **Núcleo** (migração 17, `group_receipts`): o "digitando" vai aos membros online, e quem recebe sabe quem é; cada mensagem minha de texto guarda a quem foi, quem lê manda o recibo só ao autor, e a mensagem fica "lida" quando todos que a receberam e ainda são membros leram. Os dois seguem os ajustes de "digitando" e de recibos de leitura.
- **App**: "Canela está digitando…" no cabeçalho do grupo e na lista; digitar no grupo avisa. Um texto novo nos sete idiomas.

### Conferido

- Rust: o aviso vai só a quem está online, uma vez por vez, e chega com o nome; a mensagem fica "entregue" até o último membro ler, e Caio não manda recibo a Bia pela mensagem de Ana; quem foi tirado não segura o "lida"; com os recibos desligados, fica "entregue".
- Dart: quem digita na lista e no cabeçalho, a volta para "Grupo" depois de alguns segundos, e o aviso saindo ao digitar.

### Falta

- Chamar atenção no grupo, e ver quem já leu (hoje é só o "lida" de todos).
- Um arquivo de quem ainda não é contato espera a apresentação.
- A foto do grupo e mais de um admin.
- Um admin que saiu e volta a ser adicionado pelo novo admin não aceita o grupo.

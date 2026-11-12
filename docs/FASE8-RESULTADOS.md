# Fase 8: Bluetooth LE

O que a fase 8 do `docs/PLANO.md` (seção 13, com a 7.4) pediu, o que foi feito e o que ficou. A fase vai em partes: o núcleo e o Linux primeiro, depois o Android, e por fim os sistemas da Apple e o Windows.

A saída pedida: dois celulares sem rede nenhuma trocam mensagens e fotos pequenas.

## Parte 1: o núcleo e o Linux

### Feito

- **Núcleo** (`ble/`, migração 13):
  - o anúncio: o token de época (o HMAC da chave de descoberta, com outro rótulo que o do mDNS) e a porta L2CAP, nos dados de serviço de um UUID próprio, sem nome;
  - o canal (`ble/secure.rs`): o Noise NN pelo `snow` e, logo depois, cada lado assina o hash do aperto de mão com a chave do nó, cifrado;
  - o rádio como contrato (`Radio`: abrir o canal, anunciar, procurar, conectar, parar), com um rádio na memória para os testes;
  - no nó: um contato visto há pouco que não atende pela rede recebe pelo Bluetooth, com os mesmos frames e o mesmo `Ack`; quem chega pelo Bluetooth só é aceito se for contato; o alcance novo "por perto, pelo Bluetooth".
- **Linux** (`ble/bluez.rs`): o BlueZ pelo D-Bus (`bluer`) para anunciar e procurar, e os soquetes L2CAP do kernel para o canal. Sem adaptador, desligado ou sem o `bluetoothd`, o nó segue sem Bluetooth e a tela avisa.
- **App**: o Bluetooth no cartão Rede (só no Linux por enquanto), desligado por padrão, com o que ele revela e a bateria; o aviso quando o sistema não deixou; o alcance novo, com o ícone, no contato. Quatro textos novos nos sete idiomas.
- **Distribuição**: o `libdbus-1-dev` para compilar (CI e README), e a `libdbus` nas dependências do `.deb`, do `.rpm` e do AUR.

### Conferido

- Rust: os testes novos cobrem o anúncio e o token; o canal (os dois lados sabem quem é o outro e conversam, mais de um pedaço nos dois sentidos; um byte mudado derruba; uma chave dita e outra assinada é recusada); e, no nó, com o rádio na memória e sem caminho pela rede, as mensagens indo e voltando pelo Bluetooth com o "entregue", esperando até o contato chegar perto, e um anúncio copiado por outro aparelho sem receber nada.
- No adaptador deste computador (o teste ignorado `bluez_listens_advertises_and_scans`): abrir o canal L2CAP, anunciar e procurar, como usuário comum.
- Dart: o Bluetooth começa desligado, ligar religa a rede, o aviso quando não funciona, o alcance pelo Bluetooth no contato, e o cartão em 240×160 e 320×568.

### Revisão

- O "Ok" do nó dizia que o rádio não funcionava enquanto ele ainda abria; agora só diz quando a abertura falha.

### Falta (da parte 1)

- Dois aparelhos de verdade: com um adaptador só, o computador não fala com ele mesmo. O teste de verdade vem com o Android (parte 2).
- Os arquivos (as fotos pequenas da saída) pelo Bluetooth: hoje o arquivo baixa pela rede.
- O aperto de mão de um contato novo pelo Bluetooth (o QR frente a frente sem rede).
- Android (parte 2), Apple e Windows (parte 3).

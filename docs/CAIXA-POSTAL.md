# A caixa postal do Chirp

O Chirp manda as mensagens direto de um aparelho ao outro. Quando o contato está desligado, elas esperam no seu aparelho até os dois estarem online. A **caixa postal** muda isso: é um pequeno servidor seu (um Raspberry Pi, um PC sempre ligado, um servidor alugado), ou de alguém em quem você confia, que guarda o que os contatos mandam enquanto o **seu** aparelho está desligado. Quando você abre o Chirp, ele busca.

- A caixa recebe as mensagens já cifradas pela sessão do Signal e não tem chave de nada. Ela vê quem deixa algo (o IP), quando e o tamanho, nunca o conteúdo.
- Cada contato recebe uma ficha só dele; a caixa só guarda o SHA-256 das fichas, e não aceita nada sem uma.
- O que fica guardado sai depois de buscado, ou depois de 30 dias.
- Com a caixa ligada, os convites que você cria levam o endereço dela, e as chaves públicas do convite ficam lá: quem receber o seu link com o seu aparelho desligado deixa o pedido na caixa, e vira contato quando você abrir o Chirp.
- Os arquivos não passam pela caixa: a mensagem com o arquivo chega, e o arquivo baixa quando os dois estiverem online.

O protocolo está no [`PROTOCOLO.md`](PROTOCOLO.md), e o que ela vê, no [`AMEACAS.md`](AMEACAS.md).

## Instalar

### Debian e Ubuntu (o pacote `.deb`)

Baixe o `chirp-mailbox_<versão>_amd64.deb` da página de versões (ou do repositório APT do Chirp) e instale:

```bash
sudo apt install ./chirp-mailbox_*_amd64.deb
```

O serviço `chirp-mailbox` liga sozinho, na porta UDP 47474, com os dados em `/var/lib/chirp-mailbox`. Ele roda com um usuário que só existe enquanto ele roda, sem ver nada além da pasta dele.

Para mudar a porta, dizer o endereço público ou usar um retransmissor:

```bash
sudo systemctl edit chirp-mailbox
```

```ini
[Service]
ExecStart=
ExecStart=/usr/bin/chirp-mailbox run --data /var/lib/chirp-mailbox --public 203.0.113.7:47474
```

### Contêiner (Docker ou Podman)

```bash
docker run -d --name chirp-mailbox --restart unless-stopped \
  -p 47474:47474/udp -v chirp-mailbox:/data \
  ghcr.io/francisceioseph/chirp-mailbox run --data /data --public 203.0.113.7:47474
```

### Compilando

```bash
cd core && cargo build --release -p chirp_mailbox --bin chirp-mailbox
./target/release/chirp-mailbox run
```

## Ligar ao app

1. No servidor, gere um código (vale uma vez, por 24 horas):

   ```bash
   sudo chirp-mailbox pair --data /var/lib/chirp-mailbox     # o pacote
   docker exec chirp-mailbox chirp-mailbox pair --data /data # o contêiner
   ```

   Ele mostra um QR e um link `chirp://mailbox#...`.
2. No Chirp: Seu perfil, Caixa postal, cole o link e toque em Ligar.
3. Os contatos ficam sabendo da caixa pela conversa, cifrado, na próxima vez que vocês se falarem.

Uma caixa liga a um aparelho só. Ligar outra troca a de antes. Desligar (no mesmo lugar) apaga o que estava esperando nela.

## Onde pôr a caixa

O aparelho e os contatos precisam alcançar a caixa:

- **Na rede local** (um Raspberry Pi em casa): funciona com a internet do Chirp desligada, mas só para quem está na mesma rede.
- **Na internet**: ligue a internet em Seu perfil, Rede. A caixa precisa de um IP público com a porta UDP aberta (`--public IP:porta`, para o código levar o endereço certo), ou de um retransmissor (`--relay https://...`, o mesmo tipo de servidor da Rede, no Chirp).

`chirp-mailbox status` mostra quantos donos a caixa tem e o que cada um tem guardado, sem nenhum id.

## Limites

| | Padrão | Opção |
|---|---|---|
| Quanto tempo guarda | 30 dias | `--keep-days` (de 1 a 365) |
| Espaço total | 256 MiB | `--quota-mb` |
| Envelopes no total | 20 mil | |
| Envelopes por contato | 2 mil | |

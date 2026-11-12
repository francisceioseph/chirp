# Desenho do Psito Chirp

O resumo do que a UI usa do Material 3, para quem mexe nas telas. O porquê está no `docs/PLANO.md`, seção 10; as regras que se conferem sozinhas estão no `test/design_test.dart`, no `test/privacy_test.dart` e nas imagens de referência do `test/golden_test.dart`.

## Temas

- Cada tema é um `ChirpThemeSpec` (`lib/src/ui/theme/chirp_themes.dart`): a semente, a variante do M3, uma terciária opcional, o canto, a densidade e o `ChirpStyle` (as bolhas e o vidro). O `chirpTheme` monta o `ThemeData`; nenhum widget escreve cor ou canto do tema à mão.
- Os nove: Sunny Lutino (o padrão), Wild Grey, Skylight, Old Days, Human, Symbian, Foundation, Mighty Cats e a Cor do sistema (só onde o sistema tem uma).
- Claro, escuro ou o do sistema, à escolha de quem usa. O vidro é opcional, só nas barras de cima, e some com menos animação ou mais contraste pedidos.
- A fonte é a **Urbanist** (SIL OFL 1.1), empacotada em `assets/fonts/` com a licença, sem nada buscado na rede. Os títulos e rótulos sobem um degrau de peso (ela é estreita); o cirílico e o chinês caem na fonte do sistema.
- O redesign do Material You partiu do canvas do Claude Design "Psito Chirp Redesign", com as referências dos mensageiros dos anos 2000: o anel de presença e os grupos do MSN, as bolhas com cauda do iMessage, os tiques do WhatsApp, o painel do contato do Skype e do iChat, o "chamar atenção" à vista.

## Papéis do ColorScheme

| Onde | Papel |
|---|---|
| Fundo das telas | `surface` |
| O lado da conversa antes de escolher uma | `surfaceContainerLow` |
| Minha bolha / o texto dela | `primaryContainer` / `onPrimaryContainer` |
| A bolha do contato / o texto dela | `surfaceContainerHighest` / `onSurface` |
| A citação dentro da bolha | `surfaceContainer`, com a borda em `primary` |
| A conversa escolhida na lista | `secondaryContainer` / `onSecondaryContainer` |
| Não lidas, "digitando" | `primary` |
| O escudo de verificado, a nota "cifrada de ponta a ponta" | `tertiary`, `tertiaryContainer` |
| O "chamar atenção" na conversa | `tertiaryContainer` / `onTertiaryContainer`, numa pílula |
| O anel de quem está ao alcance | `ChirpStyle.reachable` (verde, no claro e no escuro); fora de alcance, `outlineVariant` |
| A bochecha da calopsita | `ChirpStyle.cheek` (o laranja, igual em todos os temas) |
| Cartões | `surfaceContainerLow`, sem sombra |
| Textos de apoio (hora, estado) | `onSurfaceVariant` |
| O QR | preto sobre branco nos dois temas (`qrDark`, `qrLight`), porque os leitores esperam assim |

## Formas

- Os cartões e diálogos são 8 mais redondos que o canto do tema (o M3 Expressive); o canto do tema vale nos chips, campos e no botão flutuante (até 16). Os itens de lista são pílulas (com canto de 12 ou mais). Com canto de 12 ou mais, os botões são pílulas; abaixo disso, retângulos com o canto do tema (o Old Days é reto e compacto).
- As bolhas têm o canto do `ChirpStyle` e a "cauda" embaixo, do lado de quem falou.

## Componentes

- Botões: o principal é o `FilledButton`, o secundário o tonal, o terciário o `TextButton`. Sem `OutlinedButton` nem `ElevatedButton`.
- O texto vem do `textTheme`, sem `fontSize` à mão. O número de segurança usa a fonte monoespaçada do sistema.
- Barra de cima: a `ChirpAppBar` nas telas que rolam por baixo dela (a lista e a conversa); a `AppBar` nas outras.
- Adicionar contato: o `FloatingActionButton.extended` da lista.
- Ajustes: cartões com `SwitchListTile` (e `RadioListTile` num `RadioGroup` para escolher um entre vários, como as notificações); claro e escuro num `SegmentedButton` (só os ícones abaixo de 300 px); os temas numa grade de `ThemeSwatch`.
- Avisos: `SnackBar` flutuante para o que passou, `MaterialBanner` para o que continua (sem rede).
- A lista: o meu avatar e o meu nome na barra; os filtros (`FilterChip`: todas, não lidas, verificados) a partir de 4 conversas; os grupos "ao alcance" e "fora de alcance" só quando o alcance de todos já se sabe; quem está fora de alcance fica apagado.
- O avatar dos contatos é o `ReachAvatar`: a grade gerada da chave, com o anel de alcance.
- Os estados vazios têm a calopsita (`Cockatiel`, desenhada em `CustomPaint`) ou o `StateIcon` (um ícone num quadrado de cantos redondos, no tom do estado: primário, secundário ou erro).
- A conversa abre com a nota de segurança (verificada ou não, com o "Conferir código"); vazia, mostra um "Diga oi", o conferir e o chamar atenção. A nota de voz tem as barras de uma forma de onda, tiradas do id da mensagem.

## Layout

- O `ShellTemplate`: uma coluna abaixo de 840 px (a conversa abre por cima), duas a partir de 840 px (a lista com 340 px) e três a partir de 1200 px (o contato com 360 px).
- As telas de uma coluna (o `CenteredPanel`) ganham outra forma a partir dos mesmos 840 px, para não deixar um cartão estreito no meio do vazio:
  - o perfil vira os ajustes de um app de computador: as seções numa lista à esquerda (260 px) e a escolhida à direita, no topo, com até 640 px;
  - o convite mostra o código e o colar lado a lado, em dois cartões, sem as abas.
- Sem navegação embaixo por enquanto: o M3 pede de três a cinco destinos, e hoje há um só (as conversas; o perfil é uma página). Ela chega quando houver "Por perto" (fase 8) e os ajustes virarem uma seção.
- Tudo cabe em 240×160 no computador e em 320×568 no celular, rolando onde precisar.

## Acessibilidade e teclado

- Todo clique tem nome (`Tooltip` ou `Semantics(label:)`) e caminho pelo teclado. O contraste e os rótulos passam nos dois temas e em cada um dos oito temas.
- Na tela principal: Ctrl+N adicionar, Ctrl+K buscar, Alt+↑/↓ trocar de conversa, Esc fechar o painel. Na conversa: Enter manda, Shift+Enter quebra a linha, Esc cancela a resposta ou a edição.

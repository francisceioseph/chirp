# Desenho do Psito Chirp

O resumo do que a UI usa do Material 3, para quem mexe nas telas. O porquê está no `docs/PLANO.md`, seção 10; as regras que se conferem sozinhas estão no `test/design_test.dart`, no `test/privacy_test.dart` e nas imagens de referência do `test/golden_test.dart`.

## Temas

- Cada tema é um `ChirpThemeSpec` (`lib/src/ui/theme/chirp_themes.dart`): a semente, a variante do M3, uma terciária opcional, o canto, a densidade e o `ChirpStyle` (as bolhas e o vidro). O `chirpTheme` monta o `ThemeData`; nenhum widget escreve cor ou canto do tema à mão.
- Os nove: Sunny Lutino (o padrão), Wild Grey, Skylight, Old Days, Human, Symbian, Foundation, Mighty Cats e a Cor do sistema (só onde o sistema tem uma).
- Claro, escuro ou o do sistema, à escolha de quem usa. O vidro é opcional, só nas barras de cima, e some com menos animação ou mais contraste pedidos.

## Papéis do ColorScheme

| Onde | Papel |
|---|---|
| Fundo das telas | `surface` |
| O lado da conversa antes de escolher uma | `surfaceContainerLow` |
| Minha bolha / o texto dela | `primaryContainer` / `onPrimaryContainer` |
| A bolha do contato / o texto dela | `surfaceContainerHighest` / `onSurface` |
| A citação dentro da bolha | `surfaceContainer`, com a borda em `primary` |
| A conversa escolhida na lista | `secondaryContainer` / `onSecondaryContainer` |
| Não lidas, "digitando", verificado | `primary` |
| Textos de apoio (hora, estado) | `onSurfaceVariant` |
| O QR | preto sobre branco nos dois temas (`qrDark`, `qrLight`), porque os leitores esperam assim |

## Formas

- O canto do tema vale nos cartões, diálogos, chips, campos e no botão flutuante (até 16). Com canto de 12 ou mais, os botões são pílulas; abaixo disso, retângulos com o canto do tema (o Old Days é reto e compacto).
- As bolhas têm o canto do `ChirpStyle` e a "cauda" embaixo, do lado de quem falou.

## Componentes

- Botões: o principal é o `FilledButton`, o secundário o tonal, o terciário o `TextButton`. Sem `OutlinedButton` nem `ElevatedButton`.
- O texto vem do `textTheme`, sem `fontSize` à mão. O número de segurança usa a fonte monoespaçada do sistema.
- Barra de cima: a `ChirpAppBar` nas telas que rolam por baixo dela (a lista e a conversa); a `AppBar` nas outras.
- Adicionar contato: o `FloatingActionButton.extended` da lista.
- Ajustes: cartões com `SwitchListTile` (e `RadioListTile` num `RadioGroup` para escolher um entre vários, como as notificações); claro e escuro num `SegmentedButton` (só os ícones abaixo de 300 px); os temas numa grade de `ThemeSwatch`.
- Avisos: `SnackBar` para o que passou, `MaterialBanner` para o que continua (sem rede).

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

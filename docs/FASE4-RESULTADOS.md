# Fase 4: UI nova em Material 3

O que a fase 4 do `docs/PLANO.md` (seção 13 e seção 10) pediu, o que foi feito e o que ficou. A fase vai em partes, uma por commit.

## Feito

- **Temas por semente** (`lib/src/ui/theme/`): os oito da seção 10.1 (Sunny Lutino, Wild Grey, Skylight, Old Days, Human, Symbian, Foundation e Mighty Cats) são um `ChirpThemeSpec` cada: a semente, a variante do M3, uma terciária quando a personalidade pede (a bochecha laranja do Wild Grey, a beringela do Human), os cantos, a densidade e as bolhas. O `ColorScheme.fromSeed` faz o resto, com contraste garantido.
- **`ChirpStyle`**, a `ThemeExtension` com o formato das bolhas (o canto e a "cauda"). A `MessageBubble` lê dele.
- **A forma vem do tema**: cartões, diálogos, chips, campos e o botão flutuante seguem o canto de cada tema; botões são pílulas com cantos grandes e retângulos com pequenos (o Old Days é reto e compacto).
- **Aparência** no perfil (`AppearanceCard`): claro, escuro ou o do sistema, e o tema, numa grade de amostras com as cores de cada um. Muda na hora; se não gravar, volta e avisa.
- **Efeito vidro**, opcional e desligado por padrão: a barra da lista e a da conversa ficam translúcidas e borram o que rola por baixo. Some sozinho quando o sistema pede menos animação ou mais contraste, e nunca fica atrás de texto longo (só o título e os botões estão nele).
- **Cor do sistema**: um nono tema, gerado da cor de destaque do aparelho (a paleta do papel de parede no Android 12+, a cor de destaque no Windows, no macOS e no Linux, pelo `dynamic_color`, sem rede). Aparece primeiro, e só onde existe; escolhido num aparelho e aberto em outro sem cor, vira o padrão. No Linux sem cor escolhida, o portal responde (-1, -1, -1) e o plugin devolve um amarelo inventado (`0xFFFFFF01`), que o `system_accent.dart` descarta.
- **No núcleo** (`appearance.rs`, migração 4): a aparência fica no banco cifrado, como o resto. Um id de tema estranho (de uma versão mais nova) vira o padrão. Ela vale ao abrir, e volta ao padrão quando o banco é apagado.
- **A casca pela largura** (`ShellTemplate`): no celular e em janelas estreitas, a lista, com a conversa por cima; a partir de 840 px (a janela "expandida" do M3), a lista e a conversa lado a lado, com a escolhida marcada; a partir de 1200 px, o contato num terceiro painel, que o X ou o Esc fecham. A busca abre o resultado ao lado.
- **Atalhos** na tela principal: Ctrl+N (ou Cmd+N) adicionar contato, Ctrl+K buscar, Alt+↑ e Alt+↓ trocar de conversa, Esc fechar o painel. Na conversa, o Esc larga a resposta ou a edição (antes, só o X da barra).
- **`docs/DESIGN.md`**: os papéis do `ColorScheme`, as formas, os componentes, o layout e o teclado de cada tela.
- 20 textos novos nos sete idiomas (os nomes dos temas são nomes próprios e ficam iguais).

## Conferido

- Rust: 77 testes, `clippy -D warnings` e `fmt`.
- Dart: 189 testes. O `golden_test` guarda seis imagens de referência (`test/goldens/`): a lista, a conversa e a aparência no celular, no claro e no escuro, e o computador com três colunas (Old Days) e duas com vidro (Foundation escuro). O `design_test` confere o texto pelo `textTheme`, a dica em todo botão de ícone, nenhum emoji nos sete idiomas e os temas do plano. A cor do sistema: aparece primeiro e pinta o app com ela; sem ela, some e vira o padrão. O vidro: a chave grava, a lista começa abaixo da barra, o contraste passa na conversa, some com menos animação e cabe nas janelas pequenas. O `shell_test` passa as três larguras, os atalhos e a busca ao lado, com contraste e rótulos com duas e três colunas. O `appearance_test` passa os oito temas, no claro e no escuro, pelo contraste na lista e numa conversa com bolhas dos dois lados; e a aparência na janela mínima e num celular pequeno, com rótulos.
- `integration_test/storage_test.dart` no Linux: escolher o Old Days escuro, fechar e reabrir pelo SQLCipher de verdade traz o tema de volta.

## Decidido

- **Sem navegação embaixo no celular, por enquanto.** O M3 pede de três a cinco destinos, e hoje há um (as conversas; o perfil é uma página, pelo avatar). Ela entra quando houver "Por perto" (fase 8) e os ajustes virarem uma seção.
- **O `accessibility_test` da seção 10 virou os testes de cada tela**: o contraste e os rótulos já passam em todas, nos dois temas e em cada um dos oito temas, e o `design_test` cobre o que se confere no código.

## Falta

- O canvas no Claude Design (seção 10.3). O `DESIGN.md` foi escrito a partir do app, não do canvas.
- As imagens de referência usam a fonte dos testes (caixas): conferem o desenho, não as letras.

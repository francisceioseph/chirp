# Fase 4: UI nova em Material 3

O que a fase 4 do `docs/PLANO.md` (seção 13 e seção 10) pediu, o que foi feito e o que ficou. A fase vai em partes, uma por commit.

## Feito

- **Temas por semente** (`lib/src/ui/theme/`): os oito da seção 10.1 (Sunny Lutino, Wild Grey, Skylight, Old Days, Human, Symbian, Foundation e Mighty Cats) são um `ChirpThemeSpec` cada: a semente, a variante do M3, uma terciária quando a personalidade pede (a bochecha laranja do Wild Grey, a beringela do Human), os cantos, a densidade e as bolhas. O `ColorScheme.fromSeed` faz o resto, com contraste garantido.
- **`ChirpStyle`**, a `ThemeExtension` com o formato das bolhas (o canto e a "cauda"). A `MessageBubble` lê dele.
- **A forma vem do tema**: cartões, diálogos, chips, campos e o botão flutuante seguem o canto de cada tema; botões são pílulas com cantos grandes e retângulos com pequenos (o Old Days é reto e compacto).
- **Aparência** no perfil (`AppearanceCard`): claro, escuro ou o do sistema, e o tema, numa grade de amostras com as cores de cada um. Muda na hora; se não gravar, volta e avisa.
- **No núcleo** (`appearance.rs`, migração 4): a aparência fica no banco cifrado, como o resto. Um id de tema estranho (de uma versão mais nova) vira o padrão. Ela vale ao abrir, e volta ao padrão quando o banco é apagado.
- 15 textos novos nos sete idiomas (os nomes dos temas são nomes próprios e ficam iguais).

## Conferido

- Rust: 77 testes, `clippy -D warnings` e `fmt`.
- Dart: 162 testes. O `appearance_test` passa os oito temas, no claro e no escuro, pelo contraste na lista e numa conversa com bolhas dos dois lados; e a aparência na janela mínima e num celular pequeno, com rótulos.
- `integration_test/storage_test.dart` no Linux: escolher o Old Days escuro, fechar e reabrir pelo SQLCipher de verdade traz o tema de volta.

## Falta

- O efeito vidro (a coluna já está no banco, sem a chave na tela).
- A cor dinâmica do sistema (Android 12+).
- O `ShellTemplate`: três colunas no computador, navegação embaixo no celular.
- Os testes `golden_test`, `accessibility_test` e `design_test` da seção 10, e o canvas e o `DESIGN.md` da seção 10.3.

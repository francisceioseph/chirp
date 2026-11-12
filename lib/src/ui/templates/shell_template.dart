// lib/src/ui/templates/shell_template.dart
//
// A casca do app pela largura da janela (docs/PLANO.md, 10.2): no celular e em
// janelas estreitas, só a lista (a conversa abre por cima); a partir de 840 px, a
// lista e a conversa lado a lado; a partir de 1200 px, também o painel do contato.
import 'package:material_ui/material_ui.dart';

class ShellTemplate extends StatelessWidget {
  const ShellTemplate({
    super.key,
    required this.list,
    required this.placeholder,
    this.conversation,
    this.details,
  });

  /// A lista de conversas, com o Scaffold dela (barra e botão de adicionar).
  final Widget list;

  /// A conversa aberta, ou o [placeholder] quando nenhuma está.
  final Widget? conversation;
  final Widget placeholder;

  /// O painel do contato, só com três colunas.
  final Widget? details;

  static const twoColumns = 840.0;
  static const threeColumns = 1200.0;
  static const listWidth = 340.0;
  static const detailsWidth = 360.0;

  static int columnsFor(double width) => width >= threeColumns
      ? 3
      : width >= twoColumns
      ? 2
      : 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(constraints.maxWidth);
        if (columns == 1) return list;
        final details = this.details;
        // Um Scaffold por fora, para os avisos aparecerem uma vez só, embaixo de tudo.
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: listWidth, child: list),
              const VerticalDivider(width: 1),
              Expanded(child: conversation ?? placeholder),
              if (columns == 3 && details != null) ...[
                const VerticalDivider(width: 1),
                SizedBox(width: detailsWidth, child: details),
              ],
            ],
          ),
        );
      },
    );
  }
}

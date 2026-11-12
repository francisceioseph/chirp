// lib/src/ui/atoms/identity_avatar.dart
//
// O avatar gerado: uma grade 5×5 espelhada, desenhada a partir da semente que o núcleo
// tira da chave pública. A mesma chave dá sempre o mesmo desenho, e as cores vêm do
// tema (uma das três famílias do colorScheme). Decorativo: o nome vai no texto ao lado.
import 'package:material_ui/material_ui.dart';

class IdentityAvatar extends StatelessWidget {
  const IdentityAvatar({super.key, required this.seed, this.size = 72});

  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch ((seed >> 15) % 3) {
      0 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      1 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return ExcludeSemantics(
      child: ClipOval(
        child: CustomPaint(
          size: Size.square(size),
          painter: _GridPainter(
            cells: avatarCells(seed),
            background: background,
            foreground: foreground,
          ),
        ),
      ),
    );
  }
}

/// As 25 casas (linha a linha) ligadas pela semente: as 15 da metade esquerda e do
/// meio vêm dos bits, e a direita espelha.
List<bool> avatarCells(int seed) => [
  for (var row = 0; row < 5; row++)
    for (var col = 0; col < 5; col++)
      (seed >> (row * 3 + (col < 3 ? col : 4 - col))) & 1 == 1,
];

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.cells,
    required this.background,
    required this.foreground,
  });

  final List<bool> cells;
  final Color background;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    // Uma margem de uma casa em volta, para o círculo não cortar o desenho.
    final cell = size.width / 7;
    final paint = Paint()..color = foreground;
    for (var i = 0; i < cells.length; i++) {
      if (!cells[i]) continue;
      final x = (i % 5 + 1) * cell;
      final y = (i ~/ 5 + 1) * cell;
      canvas.drawRect(Rect.fromLTWH(x, y, cell + 0.5, cell + 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.background != background ||
      old.foreground != foreground ||
      !_same(old.cells, cells);

  static bool _same(List<bool> a, List<bool> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

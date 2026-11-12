// lib/src/ui/atoms/cockatiel.dart
//
// A calopsita do Chirp, desenhada à mão nas cores do tema: a crista, a bochecha e o
// olho. Aparece nos estados vazios. Decorativa: o texto ao lado diz o que importa.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/chirp_style.dart';

class Cockatiel extends StatelessWidget {
  const Cockatiel({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _CockatielPainter(
          halo: scheme.primaryContainer,
          crest: scheme.primary,
          face: scheme.surfaceContainerLowest,
          body: scheme.surfaceContainerHigh,
          cheek: ChirpStyle.of(context).cheek,
          eye: scheme.onSurface,
          beak: scheme.outline,
        ),
      ),
    );
  }
}

class _CockatielPainter extends CustomPainter {
  _CockatielPainter({
    required this.halo,
    required this.crest,
    required this.face,
    required this.body,
    required this.cheek,
    required this.eye,
    required this.beak,
  });

  final Color halo, crest, face, body, cheek, eye, beak;

  @override
  void paint(Canvas canvas, Size size) {
    // Desenhado numa caixa de 148, e escalado.
    canvas.scale(size.width / 148);
    final fill = Paint()..isAntiAlias = true;
    canvas.drawCircle(const Offset(74, 74), 72, fill..color = halo);
    final stroke = Paint()
      ..color = crest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(70, 38)
        ..cubicTo(62, 20, 66, 10, 72, 6)
        ..cubicTo(70, 18, 76, 28, 80, 36),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(78, 36)
        ..cubicTo(80, 22, 88, 14, 96, 14)
        ..cubicTo(88, 22, 86, 30, 86, 40),
      stroke,
    );
    // O corpo, embaixo, e a cabeça por cima.
    canvas.save();
    canvas.clipPath(
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(74, 74), radius: 72)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(76, 132), width: 84, height: 44),
      fill..color = body,
    );
    canvas.restore();
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(76, 86), width: 80, height: 84),
      fill..color = face,
    );
    canvas.drawCircle(const Offset(92, 82), 11, fill..color = cheek);
    canvas.drawCircle(const Offset(84, 66), 6, fill..color = eye);
    canvas.drawCircle(const Offset(86, 64), 2, fill..color = face);
    canvas.drawPath(
      Path()
        ..moveTo(104, 70)
        ..cubicTo(116, 72, 118, 82, 108, 88)
        ..cubicTo(104, 84, 102, 78, 104, 70)
        ..close(),
      fill..color = beak,
    );
    // Um aceno: três riscos curtos ao lado da cabeça.
    final wave = Paint()
      ..color = crest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 5 + i * math.pi / 8;
      final from = Offset(30 + 10 * math.cos(angle), 60 + 10 * math.sin(angle));
      final to = Offset(30 + 18 * math.cos(angle), 60 + 18 * math.sin(angle));
      canvas.drawLine(from, to, wave);
    }
  }

  @override
  bool shouldRepaint(_CockatielPainter old) =>
      old.halo != halo || old.crest != crest || old.cheek != cheek;
}

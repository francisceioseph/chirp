// lib/src/ui/molecules/voice_note.dart
//
// Uma nota de voz dentro da bolha: tocar ou parar, o progresso e o tempo. Enquanto o
// arquivo não chega inteiro, a bolha mostra o FileCard (baixar, o progresso).
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../file_text.dart';

class VoiceNote extends StatelessWidget {
  const VoiceNote({
    super.key,
    required this.color,
    this.seed = 0,
    this.duration,
    this.position,
    this.onPlay,
    this.onStop,
  });

  /// A cor do texto da bolha.
  final Color color;

  /// O desenho das barras (o id da mensagem): cada nota tem o seu, sempre o mesmo.
  final int seed;

  /// Quanto dura (`null` enquanto o núcleo não diz).
  final Duration? duration;

  /// Onde está, se é esta que toca.
  final Duration? position;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final playing = position != null;
    final total = duration;
    final at = position ?? Duration.zero;
    final progress = total == null || total == Duration.zero
        ? 0.0
        : (at.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final time = playing
        ? voiceTime(at)
        : total == null
        ? ''
        : voiceTime(total);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: playing ? l10n.voiceStop : l10n.voicePlay,
          color: color,
          onPressed: playing ? onStop : onPlay,
          icon: Icon(playing ? Icons.stop : Icons.play_arrow),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: l10n.voiceNote,
                value: '${(progress * 100).round()}%',
                child: CustomPaint(
                  size: const Size(150, 28),
                  painter: _Wave(seed: seed, progress: progress, color: color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time.isEmpty ? l10n.voiceNote : '${l10n.voiceNote} · $time',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// As barras da nota: alturas tiradas do [seed], as já tocadas na cor cheia.
class _Wave extends CustomPainter {
  _Wave({required this.seed, required this.progress, required this.color});

  final int seed;
  final double progress;
  final Color color;

  static const _bars = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _bars;
    final width = step * 0.55;
    var s = seed * 2654435761 % 4294967296 + 1;
    for (var i = 0; i < _bars; i++) {
      s = (s * 1103515245 + 12345) % 2147483648;
      final level = 0.25 + (s % 1000) / 1000 * 0.75;
      final height = size.height * level;
      final played = (i + 0.5) / _bars <= progress;
      final paint = Paint()
        ..color = played ? color : color.withValues(alpha: 0.35)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width;
      final x = i * step + step / 2;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2 + width / 2),
        Offset(x, (size.height + height) / 2 - width / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Wave old) =>
      old.progress != progress || old.color != color || old.seed != seed;
}

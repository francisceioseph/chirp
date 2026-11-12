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
    this.duration,
    this.position,
    this.onPlay,
    this.onStop,
  });

  /// A cor do texto da bolha.
  final Color color;

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
              SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  value: progress,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.24),
                  semanticsLabel: l10n.voiceNote,
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

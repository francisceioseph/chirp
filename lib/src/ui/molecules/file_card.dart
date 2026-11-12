// lib/src/ui/molecules/file_card.dart
//
// Um arquivo dentro da bolha: a miniatura (de quem mandou) ou o ícone do tipo, o nome
// e o tamanho, e o que dá para fazer agora (baixar, o progresso, salvar, tentar de
// novo). Numa foto inteira, tocar abre a foto.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../file_text.dart';

class FileCard extends StatelessWidget {
  const FileCard({
    super.key,
    required this.file,
    required this.mine,
    required this.color,
    this.onDownload,
    this.onSave,
    this.onView,
  });

  final ChatFile file;

  /// Mandado por mim (já está aqui inteiro).
  final bool mine;

  /// A cor do texto da bolha.
  final Color color;
  final VoidCallback? onDownload;
  final VoidCallback? onSave;
  final VoidCallback? onView;

  /// Os botões na cor do texto da bolha: a primária sobre o fundo da bolha (a minha
  /// é `primaryContainer`) não tem contraste.
  ButtonStyle get _button => TextButton.styleFrom(foregroundColor: color);

  IconData get _icon => switch (file.mime.split('/').first) {
    'image' => Icons.image_outlined,
    'audio' => Icons.audiotrack_outlined,
    'video' => Icons.movie_outlined,
    'text' => Icons.description_outlined,
    _ => Icons.insert_drive_file_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final thumbnail = file.thumbnail;
    final done = file.state == FileState.done;
    final canView = done && file.isImage && onView != null;
    final preview = thumbnail != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              // Um tamanho mínimo: a bolha não pula enquanto a miniatura carrega.
              constraints: const BoxConstraints(
                minWidth: 120,
                minHeight: 90,
                maxWidth: 240,
                maxHeight: 240,
              ),
              child: Image.memory(
                thumbnail,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                excludeFromSemantics: true,
              ),
            ),
          )
        : null;
    final muted = color.withValues(alpha: 0.72);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (preview != null) ...[
          if (canView)
            Semantics(
              container: true,
              button: true,
              label: l10n.fileView(file.name),
              excludeSemantics: true,
              child: InkWell(
                onTap: onView,
                borderRadius: BorderRadius.circular(8),
                child: preview,
              ),
            )
          else
            preview,
          const SizedBox(height: 6),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (preview == null) ...[
              Icon(_icon, color: color),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    fileSize(context, file.size),
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!mine) ..._status(context, muted),
        if (done && onSave != null)
          TextButton.icon(
            style: _button,
            onPressed: onSave,
            icon: const Icon(Icons.save_alt, size: 18),
            label: Text(l10n.fileSave),
          ),
      ],
    );
  }

  List<Widget> _status(BuildContext context, Color muted) {
    final l10n = context.l10n;
    final small = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: muted);
    return switch (file.state) {
      FileState.done => const [],
      FileState.waiting => [
        TextButton.icon(
          style: _button,
          onPressed: onDownload,
          icon: const Icon(Icons.download, size: 18),
          label: Text(l10n.fileDownload),
        ),
      ],
      FileState.downloading => [
        const SizedBox(height: 6),
        SizedBox(
          width: 180,
          child: LinearProgressIndicator(
            // Sem animação sem fim: parado em 0 enquanto o contato não aparece.
            value: file.progress,
            semanticsLabel: l10n.fileDownload,
            semanticsValue: l10n.fileProgress((file.progress * 100).round()),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          file.received == 0
              ? l10n.fileWaiting
              : l10n.fileProgress((file.progress * 100).round()),
          style: small,
        ),
      ],
      FileState.failed => [
        const SizedBox(height: 4),
        Text(l10n.fileFailed, style: small),
        TextButton.icon(
          style: _button,
          onPressed: onDownload,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l10n.fileRetry),
        ),
      ],
    };
  }
}

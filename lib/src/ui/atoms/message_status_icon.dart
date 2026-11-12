// lib/src/ui/atoms/message_status_icon.dart
//
// O estado de uma mensagem minha: na fila (relógio), entregue (um tique) e lida (dois
// tiques, na cor primária).
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';

String statusLabel(ChirpLocalizations l10n, MessageStatus status) =>
    switch (status) {
      MessageStatus.pending => l10n.statusPending,
      MessageStatus.delivered => l10n.statusDelivered,
      MessageStatus.read => l10n.statusRead,
    };

class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    super.key,
    required this.status,
    this.size = 16,
    this.color,
  });

  final MessageStatus status;
  final double size;

  /// A cor de entregue e na fila; lida usa a primária.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = color ?? scheme.onSurfaceVariant;
    final (icon, tint) = switch (status) {
      MessageStatus.pending => (Icons.schedule, muted),
      MessageStatus.delivered => (Icons.done, muted),
      MessageStatus.read => (Icons.done_all, scheme.primary),
    };
    return Tooltip(
      message: statusLabel(context.l10n, status),
      child: Icon(
        icon,
        size: size,
        color: tint,
        semanticLabel: statusLabel(context.l10n, status),
      ),
    );
  }
}

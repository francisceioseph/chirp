// lib/src/ui/atoms/message_status_icon.dart
//
// O estado de uma mensagem minha: na fila (relógio), na caixa postal do contato (a
// caixa de correio), entregue (um tique) e lida (dois tiques, na cor primária).
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';

String statusLabel(
  ChirpLocalizations l10n,
  MessageStatus status, {
  bool inMailbox = false,
}) => switch (status) {
  MessageStatus.pending when inMailbox => l10n.statusInMailbox,
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
    this.inMailbox = false,
  });

  final MessageStatus status;
  final bool inMailbox;
  final double size;

  /// A cor de entregue e na fila; lida usa a primária.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = color ?? scheme.onSurfaceVariant;
    final (icon, tint) = switch (status) {
      MessageStatus.pending when inMailbox => (
        Icons.markunread_mailbox_outlined,
        muted,
      ),
      MessageStatus.pending => (Icons.schedule, muted),
      MessageStatus.delivered => (Icons.done, muted),
      MessageStatus.read => (Icons.done_all, scheme.primary),
    };
    final label = statusLabel(context.l10n, status, inMailbox: inMailbox);
    return Tooltip(
      message: label,
      child: Icon(icon, size: size, color: tint, semanticLabel: label),
    );
  }
}

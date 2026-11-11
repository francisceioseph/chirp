// lib/src/ui/molecules/conversation_tile.dart
//
// Uma conversa na lista: o avatar, o nome, a última mensagem (ou "digitando…"), a
// hora e as não lidas. Sem mensagens, mostra o estado do contato (verificado ou não).
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../atoms/message_status_icon.dart';
import '../time_format.dart';

String contactName(ChirpLocalizations l10n, Contact contact) =>
    contact.displayName.isEmpty ? l10n.contactUnnamed : contact.displayName;

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    this.typing = false,
    this.onTap,
    this.now,
    this.selected = false,
  });

  final Conversation conversation;
  final bool typing;

  /// A conversa aberta ao lado (com duas colunas).
  final bool selected;
  final VoidCallback? onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final contact = conversation.contact;
    final last = conversation.last;
    final name = contactName(l10n, contact);
    final unread = conversation.unread;

    final Widget subtitle;
    if (typing) {
      subtitle = Text(
        l10n.typing,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.primary, fontStyle: FontStyle.italic),
      );
    } else if (last != null) {
      final text = switch (last) {
        ChatMessage(kind: MessageKind.nudge) => l10n.nudgePreview,
        ChatMessage(deleted: true) => l10n.messageDeleted,
        _ => last.text.replaceAll('\n', ' '),
      };
      subtitle = Row(
        children: [
          if (last.outgoing) ...[
            MessageStatusIcon(status: last.status, size: 16),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              last.outgoing ? '${l10n.you}: $text' : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: unread > 0
                  ? TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
            ),
          ),
        ],
      );
    } else {
      final (icon, status, color) = !contact.established
          ? (Icons.hourglass_top, l10n.contactPending, scheme.onSurfaceVariant)
          : contact.verified
          ? (Icons.verified_user, l10n.contactVerified, scheme.primary)
          : (
              Icons.shield_outlined,
              l10n.contactUnverified,
              scheme.onSurfaceVariant,
            );
      subtitle = Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(child: Text(status, overflow: TextOverflow.ellipsis)),
        ],
      );
    }

    return ListTile(
      selected: selected,
      selectedTileColor: scheme.secondaryContainer,
      selectedColor: scheme.onSecondaryContainer,
      leading: IdentityAvatar(seed: contact.avatarSeed, size: 40),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle,
      trailing: last == null && unread == 0
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (last != null)
                  Text(
                    messageTime(context, last.receivedAt, now: now),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: unread > 0 ? scheme.primary : null,
                    ),
                  ),
                if (unread > 0) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: l10n.unreadCount(unread),
                    excludeSemantics: true,
                    child: Badge.count(
                      count: unread,
                      backgroundColor: scheme.primary,
                      textColor: scheme.onPrimary,
                    ),
                  ),
                ],
              ],
            ),
      onTap: onTap,
    );
  }
}

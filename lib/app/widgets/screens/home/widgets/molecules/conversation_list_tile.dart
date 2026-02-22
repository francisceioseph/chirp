import 'package:chirp/app/widgets/screens/home/widgets/atoms/unread_badge.dart';
import 'package:chirp/domain/entities/conversation.dart';
import 'package:chirp/app/widgets/atoms/chirp_avatar.dart';
import 'package:flutter/material.dart';

class ConversationListTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      leading: ChirpAvatar(
        radius: 24,
        name: conversation.title,
        type: conversation.type == ConversationType.group
            ? AvatarType.flock
            : AvatarType.tiel,
        imageUrl: conversation.avatar,
        badge: _buildStatusBadge(colorScheme),
      ),
      title: Text(
        conversation.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        conversation.lastMessageText ?? "Inicie esse pio...",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDate(conversation.dateUpdated),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          UnreadBadge(count: conversation.unreadCount),
        ],
      ),
    );
  }

  Widget? _buildStatusBadge(ColorScheme colorScheme) {
    return null;
  }

  String _formatDate(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}

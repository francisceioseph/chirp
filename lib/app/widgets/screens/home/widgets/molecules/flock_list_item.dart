import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/tiel_status_badge.dart';
import 'package:flutter/material.dart';

class FlockListItem extends StatelessWidget {
  final Conversation conversation;
  final String? activeChatId;
  final void Function() onTap;
  final void Function() onAddFriendshipTap;

  String get avatarUrl => conversation.avatar;

  const FlockListItem({
    super.key,
    required this.conversation,
    required this.activeChatId,
    required this.onTap,
    required this.onAddFriendshipTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = activeChatId == conversation.id;

    final statusText = conversation.statusText;
    final badgeColor = conversation.getStatusColor(theme.colorScheme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.8)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(conversation.avatar),
              ),
            ),
            if (conversation is Tiel)
              Positioned(
                bottom: 0,
                right: 0,
                child: TielStatusBadge(
                  badgeColor: badgeColor,
                  status: (conversation as Tiel).status,
                ),
              ),
          ],
        ),
        title: Text(
          conversation.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          statusText,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: _buildTrailingAction(context, theme),
      ),
    );
  }

  Widget? _buildTrailingAction(BuildContext context, ThemeData theme) {
    if (conversation is! Tiel) {
      return null;
    }

    final tiel = conversation as Tiel;

    return switch (tiel.status) {
      .discovered => IconButton(
        onPressed: onAddFriendshipTap,
        icon: Icon(Icons.person_add_alt_1_rounded),
        tooltip: "Solicitar Amizade",
      ),

      .pending => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.orangeAccent),
        ),
      ),

      .connected => Icon(
        Icons.chat_bubble_outline_rounded,
        color: theme.colorScheme.primary.withValues(alpha: 0.5),
        size: 20,
      ),

      _ => null,
    };
  }
}

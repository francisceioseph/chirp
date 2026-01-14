import 'package:chirp/models/tiel.dart';
import 'package:chirp/widgets/screens/home/widgets/tiel_status_badge.dart';
import 'package:flutter/material.dart';

class FlockListItem extends StatelessWidget {
  final Conversation conversation;
  final String? activeChatId;
  final void Function()? onTap;

  String get avatarUrl => conversation.avatar;

  const FlockListItem({
    super.key,
    required this.conversation,
    required this.activeChatId,
    required this.onTap,
  });

  String _getStatusText() {
    if (conversation is Tiel) {
      final tiel = conversation as Tiel;

      return switch (tiel.status) {
        .online => "Estou online",
        .connected => "Voando juntos...",
        .away => "Relaxing...",
        .disconnected => "Asas paradas...",
        .error => "Vish, algo deu errado!",
      };
    }

    if (conversation is Flock) {
      final flock = conversation as Flock;
      return "${flock.tielIds.length} tiels no bando";
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = activeChatId == conversation.id;

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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Avatar com borda sutil
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      backgroundImage: NetworkImage(avatarUrl),
                    ),

                    if (conversation is Tiel)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: TielStatusBadge(
                          status: (conversation as Tiel).status,
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.name,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

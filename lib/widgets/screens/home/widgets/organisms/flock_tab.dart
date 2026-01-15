import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/widgets/screens/home/widgets/organisms/flock_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlockTab extends StatelessWidget {
  const FlockTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChirpController>();
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Seu Bando",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.2,
                ),
                child: Text(
                  "${controller.allConversations.length}",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: FlockList(
            conversations: controller.allConversations,
            activeChatId: null,
            onItemTap: (conversation) {
              controller.selectChat(conversation.id);
              Navigator.pushNamed(context, '/chat', arguments: conversation.id);
            },
            onRequestFriendship: (tiel) {
              controller.requestFriendship(tiel);
            },
          ),
        ),
      ],
    );
  }
}

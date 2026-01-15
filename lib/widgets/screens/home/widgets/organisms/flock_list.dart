import 'package:chirp/models/tiel.dart';
import 'package:chirp/widgets/screens/home/widgets/molecules/flock_list_item.dart';
import 'package:flutter/material.dart';

class FlockList extends StatelessWidget {
  final List<Conversation> conversations;
  final String? activeChatId;
  final void Function(Conversation conversation) onItemTap;
  final void Function(Tiel tiel) onRequestFriendship;

  const FlockList({
    super.key,
    required this.conversations,
    required this.activeChatId,
    required this.onItemTap,
    required this.onRequestFriendship,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];

        return FlockListItem(
          conversation: conversation,
          activeChatId: activeChatId,
          onTap: () {
            onItemTap(conversation);
          },
          onAddFriendshipTap: () {
            if (conversation is Tiel && conversation.status == .discovered) {
              onRequestFriendship(conversation);
            }
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Divider(
          height: 1,
          thickness: 0.5,
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        );
      },
    );
  }
}

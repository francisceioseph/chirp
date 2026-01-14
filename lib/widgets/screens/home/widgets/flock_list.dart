import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/models/tiel.dart';
import 'package:chirp/widgets/screens/home/widgets/flock_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlockList extends StatelessWidget {
  final List<Conversation> conversations;

  const FlockList({super.key, required this.conversations});

  @override
  Widget build(BuildContext context) {
    final chirpCtrl = context.watch<ChirpController>();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];

        return FlockListItem(
          conversation: conversation,
          activeChatId: chirpCtrl.activeChatId,
          onTap: () {
            chirpCtrl.selectChat(conversation.id);
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

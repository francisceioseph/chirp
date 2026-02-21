import 'package:flutter/material.dart';

class FlockTab extends StatelessWidget {
  const FlockTab({super.key});

  @override
  Widget build(BuildContext context) {
    // final chirpCtrl = context.watch<ChirpController>();
    // final friendshipCtrl = context.watch<FriendshipController>();

    // final theme = Theme.of(context);

    // return Column(
    //   children: [
    //     Padding(
    //       padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    //       child: Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         children: [
    //           Text(
    //             "Seu Bando",
    //             style: theme.textTheme.titleLarge?.copyWith(
    //               fontWeight: FontWeight.bold,
    //               color: theme.colorScheme.onSurface,
    //             ),
    //           ),
    //           CircleAvatar(
    //             radius: 12,
    //             backgroundColor: theme.colorScheme.primary.withValues(
    //               alpha: 0.2,
    //             ),
    //             child: Text(
    //               "${chirpCtrl.allConversations.length}",
    //               style: TextStyle(
    //                 fontSize: 12,
    //                 color: theme.colorScheme.primary,
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),

    //     Expanded(
    //       child: FlockList(
    //         conversations: chirpCtrl.allConversations,
    //         activeChatId: null,
    //         onItemTap: (conversation) {
    //           chirpCtrl.selectChat(conversation.id);
    //           Navigator.pushNamed(context, '/chat', arguments: conversation.id);
    //         },
    //         onRequestFriendship: (tiel) {
    //           friendshipCtrl.requestFriendship(tiel);
    //         },
    //       ),
    //     ),
    //   ],
    // );

    return Placeholder();
  }
}

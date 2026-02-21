import 'package:flutter/material.dart';

class FlockPanel extends StatelessWidget {
  const FlockPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Placeholder();

    // TODO: RESTORE THIS PANEL LATER
    // final chirpCtrl = context.watch<ChirpController>();
    // final friendshipCtrl = context.watch<FriendshipController>();

    // return ChirpPanel(
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       const ColumnLabel(label: "Bando"),
    //       Expanded(
    //         child: ListenableBuilder(
    //           listenable: chirpCtrl,
    //           builder: (context, _) {
    //             return FlockList(
    //               activeChatId: chirpCtrl.activeChatId,
    //               conversations: chirpCtrl.allConversations,
    //               onItemTap: (conversation) =>
    //                   chirpCtrl.selectChat(conversation.id),
    //               onRequestFriendship: (tiel) =>
    //                   friendshipCtrl.requestFriendship(tiel),
    //             );
    //           },
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}

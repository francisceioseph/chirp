import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/widgets/atoms/glass_panel.dart';
import 'package:chirp/widgets/screens/home/widgets/atoms/column_label.dart';
import 'package:chirp/widgets/screens/home/widgets/organisms/flock_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlockPanel extends StatelessWidget {
  const FlockPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final chirpCtrl = context.watch<ChirpController>();

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ColumnLabel(label: "Bando"),
          Expanded(
            child: ListenableBuilder(
              listenable: chirpCtrl,
              builder: (context, _) {
                return FlockList(
                  activeChatId: chirpCtrl.activeChatId,
                  conversations: chirpCtrl.allConversations,
                  onItemTap: (conversation) {
                    chirpCtrl.selectChat(conversation.id);
                  },
                  onRequestFriendship: (tiel) {
                    chirpCtrl.requestFriendship(tiel);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

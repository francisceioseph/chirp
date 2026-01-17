import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/models/tiel.dart';
import 'package:chirp/widgets/atoms/glass_panel.dart';
import 'package:chirp/widgets/screens/home/widgets/atoms/column_label.dart';
import 'package:chirp/widgets/screens/home/widgets/organisms/message_input.dart';
import 'package:chirp/widgets/screens/home/widgets/organisms/message_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final chirpCtrl = context.watch<ChirpController>();
    final activeChatId = chirpCtrl.activeChatId;

    if (activeChatId == null) {
      return const GlassPanel(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.question_answer_outlined, size: 48),
              SizedBox(height: 16),
              Text("Selecione uma Tiel para chirpar"),
            ],
          ),
        ),
      );
    }

    final messages = chirpCtrl.getMessagesFor(activeChatId);
    final activeChat = chirpCtrl.allConversations.firstWhere(
      (c) => c.id == activeChatId,
    );

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ColumnLabel(label: "Mensagens"),
          Expanded(child: MessageList(messages: messages)),
          MessageInput(
            isEnabled: _canSendChat(activeChat),
            onSend: (text) {
              chirpCtrl.sendChirp(activeChatId, text);
            },
            onAttachFile: () {
              chirpCtrl.pickAndOfferFile(activeChatId);
            },
          ),
        ],
      ),
    );
  }

  bool _canSendChat(Conversation conversation) {
    if (conversation is Tiel) {
      return conversation.status == .connected;
    }

    if (conversation is Flock) {
      return true;
    }

    return false;
  }
}

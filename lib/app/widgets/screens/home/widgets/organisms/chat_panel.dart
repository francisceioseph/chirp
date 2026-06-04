import 'package:chirp/app/controllers/chat_controller.dart';
import 'package:chirp/app/widgets/atoms/chirp_panel.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/column_label.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/empty_state.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/message_input.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/message_list.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:flutter/material.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final chatCtrl = getIt<ChatController>();

    return ListenableBuilder(
      listenable: chatCtrl,
      builder: (context, _) {
        final conversation = chatCtrl.conversation;
        final messages = chatCtrl.messages;

        if (conversation == null && messages.isEmpty) {
          return ChirpPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ColumnLabel(label: "Mensagens"),
                Expanded(
                  child: EmptyState(
                    icon: Icons.message_outlined,
                    text: "Nenhuma mensagem nessa conversa",
                  ),
                ),
              ],
            ),
          );
        }

        return ChirpPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ColumnLabel(label: "Mensagens"),
              Expanded(child: MessageList(messages: messages)),
              MessageInput(
                isEnabled: true,
                onSend: (text) {
                  chatCtrl.sendChirp(
                    conversationId: conversation!.id,
                    targetId: conversation.targetId,
                    text: text,
                  );
                },
                onAttachFile: () {
                  if (conversation != null) {
                    chatCtrl.pickAndOfferFile(conversation.targetId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

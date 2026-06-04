import 'package:chirp/app/controllers/chat_controller.dart';
import 'package:chirp/app/widgets/atoms/chirp_panel.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/message_input.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/message_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final chatCtrl = context.watch<ChatController>();
    final theme = Theme.of(context);

    final conversation = chatCtrl.conversation;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.read<ChatController>().selectedConversationId = null;
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            if (conversation?.avatar != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(conversation!.avatar),
              ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation?.title ?? "Tiel Desconhecida",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Conexão Segura",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ChirpPanel(
              child: Column(
                children: [
                  Expanded(child: MessageList(messages: chatCtrl.messages)),

                  MessageInput(
                    onSend: (text) {
                      final conversation = chatCtrl.conversation;

                      if (conversation != null) {
                        chatCtrl.sendChirp(
                          conversationId: conversation.id,
                          text: text,
                          targetId: conversation.targetId,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

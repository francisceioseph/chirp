import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/app/widgets/atoms/glass_panel.dart';
import 'package:chirp/app/widgets/molecules/stacked_orbs.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/message_input.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/message_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChirpController>();
    final theme = Theme.of(context);

    final conversation = controller.getConversationFor(conversationId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.read<ChirpController>().selectChat(null);
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
                  conversation?.name ?? "Tiel Desconhecida",
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
          const StackedOrbs(),

          SafeArea(
            bottom: false,
            child: GlassPanel(
              child: Column(
                children: [
                  Expanded(
                    child: MessageList(
                      messages: controller.getMessagesFor(conversationId),
                    ),
                  ),

                  MessageInput(
                    onSend: (text) =>
                        controller.sendChirp(conversationId, text),
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

import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/widgets/components/glass_panel.dart';
import 'package:chirp/widgets/screens/home/widgets/column_label.dart';
import 'package:chirp/widgets/screens/home/widgets/message_list.dart';
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

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ColumnLabel(label: "Mensagens"),
          Expanded(child: MessageList(messages: messages)),
        ],
      ),
    );
  }
}

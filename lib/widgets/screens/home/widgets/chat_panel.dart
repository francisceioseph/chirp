import 'package:chirp/widgets/components/glass_panel.dart';
import 'package:chirp/widgets/screens/home/widgets/column_label.dart';
import 'package:flutter/material.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const ColumnLabel(label: "Mensagens")],
      ),
    );
  }
}

// lib/src/ui/organisms/chat_settings_card.dart
//
// A privacidade das conversas: os recibos de leitura e o "digitando". Desligar vale
// para os dois lados, como no WhatsApp.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';

class ChatSettingsCard extends StatefulWidget {
  const ChatSettingsCard({super.key, required this.store});

  final ProfileStore store;

  @override
  State<ChatSettingsCard> createState() => _ChatSettingsCardState();
}

class _ChatSettingsCardState extends State<ChatSettingsCard> {
  ChatSettings? _settings;

  @override
  void initState() {
    super.initState();
    widget.store
        .chatSettings()
        .then((s) {
          if (mounted) setState(() => _settings = s);
        })
        .catchError((Object _) {});
  }

  Future<void> _set(ChatSettings settings) async {
    final before = _settings;
    setState(() => _settings = settings);
    try {
      await widget.store.setChatSettings(settings);
    } on CoreException {
      if (mounted) setState(() => _settings = before);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = _settings;
    if (settings == null) return const SizedBox.shrink();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.chatSettingsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            title: Text(l10n.readReceipts),
            subtitle: Text(l10n.readReceiptsHelp),
            value: settings.readReceipts,
            onChanged: (value) => _set(
              ChatSettings(readReceipts: value, typing: settings.typing),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.typingIndicator),
            subtitle: Text(l10n.typingIndicatorHelp),
            value: settings.typing,
            onChanged: (value) => _set(
              ChatSettings(readReceipts: settings.readReceipts, typing: value),
            ),
          ),
        ],
      ),
    );
  }
}

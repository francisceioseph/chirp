// lib/src/ui/organisms/message_actions.dart
//
// As opções de uma mensagem, numa folha de baixo: as reações numa fileira e, embaixo,
// responder, copiar, editar e apagar (para mim, ou para todos enquanto dá).
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/reaction_icon.dart';

enum MessageAction { reply, copy, edit, deleteForMe, deleteForEveryone }

/// O que foi escolhido: uma ação, ou uma reação (de 1 a reactionKinds).
typedef MessageChoice = ({MessageAction? action, int? reaction});

Future<MessageChoice?> showMessageActions(
  BuildContext context,
  ChatMessage message,
) => showModalBottomSheet<MessageChoice>(
  context: context,
  showDragHandle: true,
  // A lista inteira cabe numa janela comum; numa pequena, ela rola.
  isScrollControlled: true,
  builder: (context) => _MessageActions(message: message),
);

class _MessageActions extends StatelessWidget {
  const _MessageActions({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = message.kind == MessageKind.text && !message.deleted;
    void pick({MessageAction? action, int? reaction}) =>
        Navigator.of(context).pop((action: action, reaction: reaction));
    Widget tile(MessageAction action, IconData icon, String label) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => pick(action: action),
    );
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (text)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    for (var kind = 1; kind <= reactionKinds; kind++)
                      IconButton(
                        tooltip: reactionLabel(l10n, kind),
                        isSelected: message.myReaction == kind,
                        style: message.myReaction == kind
                            ? IconButton.styleFrom(
                                backgroundColor: scheme.primaryContainer,
                              )
                            : null,
                        onPressed: () => pick(reaction: kind),
                        icon: Icon(reactionIcon(kind), color: scheme.primary),
                      ),
                  ],
                ),
              ),
            if (text) ...[
              tile(MessageAction.reply, Icons.reply, l10n.reply),
              tile(MessageAction.copy, Icons.copy, l10n.copyText),
            ],
            if (message.canEdit)
              tile(MessageAction.edit, Icons.edit, l10n.editMessage),
            tile(
              MessageAction.deleteForMe,
              Icons.delete_outline,
              l10n.deleteForMe,
            ),
            if (message.canDeleteForEveryone)
              tile(
                MessageAction.deleteForEveryone,
                Icons.delete_forever_outlined,
                l10n.deleteForEveryone,
              ),
          ],
        ),
      ),
    );
  }
}

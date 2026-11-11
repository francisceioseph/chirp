// lib/src/ui/organisms/erase_dialog.dart
//
// A confirmação de apagar tudo: não tem volta, então pergunta antes, e o botão de
// apagar não é o padrão.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

Future<bool> confirmErase(BuildContext context) async {
  final l10n = context.l10n;
  final erase = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_forever_outlined),
      title: Text(l10n.eraseTitle),
      content: Text(l10n.eraseBody),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.eraseConfirm),
        ),
      ],
    ),
  );
  return erase ?? false;
}

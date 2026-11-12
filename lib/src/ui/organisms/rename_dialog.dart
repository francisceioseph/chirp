// lib/src/ui/organisms/rename_dialog.dart
//
// Trocar o nome do perfil. O diálogo fica aberto até o núcleo aceitar, e mostra o erro
// se ele recusar.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../failure_text.dart';
import '../molecules/name_field.dart';

/// [rename] devolve a falha, ou nulo se deu certo.
Future<void> showRenameDialog(
  BuildContext context, {
  required String current,
  required Future<CoreFailure?> Function(String name) rename,
}) => showDialog<void>(
  context: context,
  builder: (context) => _RenameDialog(current: current, rename: rename),
);

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current, required this.rename});

  final String current;
  final Future<CoreFailure?> Function(String name) rename;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _name = TextEditingController(text: widget.current);
  CoreFailure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final failure = await widget.rename(_name.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
    return AlertDialog(
      title: Text(l10n.renameTitle),
      content: SizedBox(
        width: 360,
        child: NameField(
          controller: _name,
          autofocus: true,
          errorText: failure == null ? null : failureText(l10n, failure),
          onSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.save)),
      ],
    );
  }
}

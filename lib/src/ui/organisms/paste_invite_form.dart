// lib/src/ui/organisms/paste_invite_form.dart
//
// Colar o convite de outra pessoa (o link que ela mandou). Ler o QR pela câmera vem
// numa versão seguinte; por enquanto, o link.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../failure_text.dart';

class PasteInviteForm extends StatefulWidget {
  const PasteInviteForm({super.key, required this.onAdd});

  /// Faz o aperto de mão; devolve o contato ou lança CoreException.
  final Future<Contact> Function(String link) onAdd;

  @override
  State<PasteInviteForm> createState() => _PasteInviteFormState();
}

class _PasteInviteFormState extends State<PasteInviteForm> {
  final _link = TextEditingController();
  bool _busy = false;
  CoreFailure? _failure;

  @override
  void initState() {
    super.initState();
    _link.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy || _link.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await widget.onAdd(_link.text);
    } on CoreException catch (error) {
      if (mounted) setState(() => _failure = error.failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _link,
          enabled: !_busy,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          keyboardType: TextInputType.url,
          minLines: 1,
          maxLines: 4,
          onSubmitted: (_) => _add(),
          decoration: InputDecoration(
            labelText: l10n.pasteLabel,
            helperText: l10n.pasteHelp,
            errorText: failure == null ? null : failureText(l10n, failure),
            errorMaxLines: 4,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy || _link.text.trim().isEmpty ? null : _add,
          child: _busy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Flexible(child: Text(l10n.pasteConnecting)),
                  ],
                )
              : Text(l10n.pasteAdd),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.qrScanLater,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

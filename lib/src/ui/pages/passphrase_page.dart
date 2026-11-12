// lib/src/ui/pages/passphrase_page.dart
//
// Sem cofre no sistema, o banco fica preso a uma senha: criar (com a confirmação e o
// aviso de que não há como recuperar) ou digitar para abrir.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/chirp_mark.dart';
import '../atoms/panel_text.dart';
import '../failure_text.dart';
import '../molecules/passphrase_field.dart';
import '../templates/centered_panel.dart';

class PassphrasePage extends StatefulWidget {
  const PassphrasePage({
    super.key,
    required this.creating,
    required this.minChars,
    required this.onSubmit,
    this.onErase,
    this.failure,
    this.busy = false,
  });

  final bool creating;
  final int minChars;
  final ValueChanged<String> onSubmit;

  /// Só ao abrir: esqueci a senha, apagar tudo.
  final VoidCallback? onErase;
  final CoreFailure? failure;
  final bool busy;

  @override
  State<PassphrasePage> createState() => _PassphrasePageState();
}

class _PassphrasePageState extends State<PassphrasePage> {
  final _passphrase = TextEditingController();
  final _confirm = TextEditingController();

  /// O erro conferido aqui antes de mandar ao núcleo (curta, ou não bate).
  String? _localError;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.busy) return;
    final l10n = context.l10n;
    final text = _passphrase.text;
    String? error;
    if (widget.creating && text.characters.length < widget.minChars) {
      error = l10n.passphraseTooShort(widget.minChars);
    } else if (widget.creating && text != _confirm.text) {
      error = l10n.passphraseMismatch;
    } else if (text.isEmpty) {
      return;
    }
    setState(() => _localError = error);
    if (error != null) return;
    // Os campos se esvaziam ao mandar: se a senha não servir, digita-se de novo.
    _passphrase.clear();
    _confirm.clear();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = widget.failure;
    final error =
        _localError ??
        (failure == null
            ? null
            : failureText(l10n, failure, minPassphraseChars: widget.minChars));
    return CenteredPanel(
      children: [
        const Center(child: ChirpMark(size: 72)),
        const SizedBox(height: 24),
        PanelTitle(
          widget.creating
              ? l10n.passphraseCreateTitle
              : l10n.passphraseUnlockTitle,
        ),
        if (widget.creating) ...[
          const SizedBox(height: 12),
          PanelBody(l10n.passphraseCreateBody),
        ],
        const SizedBox(height: 24),
        PassphraseField(
          controller: _passphrase,
          label: l10n.passphraseLabel,
          autofocus: true,
          errorText: widget.creating ? null : error,
          textInputAction: widget.creating
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: widget.creating ? null : (_) => _submit(),
        ),
        if (widget.creating) ...[
          const SizedBox(height: 16),
          PassphraseField(
            controller: _confirm,
            label: l10n.passphraseConfirmLabel,
            errorText: error,
            onSubmitted: (_) => _submit(),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.busy ? null : _submit,
          child: Text(
            widget.creating ? l10n.passphraseCreate : l10n.passphraseUnlock,
          ),
        ),
        if (widget.onErase case final onErase?) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.busy ? null : onErase,
            child: Text(l10n.passphraseForgot),
          ),
        ],
      ],
    );
  }
}

// lib/src/ui/molecules/passphrase_field.dart
//
// O campo de senha: escondida por padrão, com o botão de mostrar, e sem o teclado
// aprender nem sugerir o que se digita.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class PassphraseField extends StatefulWidget {
  const PassphraseField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PassphraseField> createState() => _PassphraseFieldState();
}

class _PassphraseFieldState extends State<PassphraseField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final toggle = _visible ? l10n.passphraseHide : l10n.passphraseShow;
    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        errorMaxLines: 3,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: toggle,
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

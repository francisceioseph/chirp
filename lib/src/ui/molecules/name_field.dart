// lib/src/ui/molecules/name_field.dart
//
// O campo do nome do perfil, no cadastro e no "trocar nome".
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

/// O máximo de caracteres, o mesmo que o núcleo aceita.
const maxNameChars = 64;

class NameField extends StatelessWidget {
  const NameField({
    super.key,
    required this.controller,
    this.errorText,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLength: maxNameChars,
      textCapitalization: TextCapitalization.words,
      enableIMEPersonalizedLearning: false,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: l10n.nameLabel,
        helperText: l10n.nameHelp,
        helperMaxLines: 3,
        errorText: errorText,
        errorMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

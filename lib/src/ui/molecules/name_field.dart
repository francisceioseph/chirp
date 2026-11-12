// lib/src/ui/molecules/name_field.dart
//
// O campo do nome do perfil, no cadastro e no "trocar nome".
import 'package:material_ui/material_ui.dart';

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
    this.label,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  /// O rótulo, quando não é o nome do perfil (o nome de um grupo).
  final String? label;

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
        labelText: label ?? l10n.nameLabel,
        helperText: label == null ? l10n.nameHelp : null,
        helperMaxLines: 3,
        errorText: errorText,
        errorMaxLines: 3,
      ),
    );
  }
}

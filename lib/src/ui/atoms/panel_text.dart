// lib/src/ui/atoms/panel_text.dart
//
// O título e o parágrafo das telas de uma coluna (CenteredPanel).
import 'package:flutter/material.dart';

/// Um título de tela, centrado.
class PanelTitle extends StatelessWidget {
  const PanelTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.headlineSmall,
    textAlign: TextAlign.center,
  );
}

/// Um parágrafo de tela, centrado e em cor secundária.
class PanelBody extends StatelessWidget {
  const PanelBody(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }
}

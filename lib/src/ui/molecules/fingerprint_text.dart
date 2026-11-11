// lib/src/ui/molecules/fingerprint_text.dart
//
// A impressão digital da chave: os 6 grupos de 5 dígitos, em fonte de largura fixa e
// em duas linhas de três, para comparar de olho. O leitor de tela lê grupo a grupo.
import 'package:flutter/material.dart';

class FingerprintText extends StatelessWidget {
  const FingerprintText({super.key, required this.fingerprint});

  final String fingerprint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = fingerprint.split(' ');
    final lines = [
      for (var i = 0; i < groups.length; i += 3)
        groups.skip(i).take(3).join('  '),
    ];
    return Semantics(
      label: groups.join(', '),
      excludeSemantics: true,
      child: SelectableText(
        lines.join('\n'),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier New', 'Menlo', 'Consolas'],
          letterSpacing: 1.5,
          height: 1.5,
        ),
      ),
    );
  }
}

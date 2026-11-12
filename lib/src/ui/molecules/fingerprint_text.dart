// lib/src/ui/molecules/fingerprint_text.dart
//
// Dígitos para comparar de olho: a impressão digital da chave (6 grupos de 5, em duas
// linhas de três) e o número de segurança (12 grupos, em três linhas de quatro), em
// fonte de largura fixa. O leitor de tela lê grupo a grupo.
import 'package:material_ui/material_ui.dart';

class FingerprintText extends StatelessWidget {
  const FingerprintText({
    super.key,
    required this.fingerprint,
    this.perLine = 3,
  });

  /// Os dígitos, com ou sem espaços.
  final String fingerprint;

  /// Quantos grupos de 5 por linha.
  final int perLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final digits = fingerprint.replaceAll(' ', '');
    final groups = [
      for (var i = 0; i < digits.length; i += 5)
        digits.substring(i, (i + 5).clamp(0, digits.length)),
    ];
    final lines = [
      for (var i = 0; i < groups.length; i += perLine)
        groups.skip(i).take(perLine).join('  '),
    ];
    return Semantics(
      label: groups.join(', '),
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
      ),
    );
  }
}

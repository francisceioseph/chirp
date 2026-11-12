// lib/src/ui/atoms/state_icon.dart
//
// O ícone grande de um estado (um problema, uma senha, um oi): num quadrado de cantos
// bem redondos, no tom que o estado pede. Decorativo: o título ao lado diz o estado.
import 'package:material_ui/material_ui.dart';

enum StateTone { primary, secondary, error }

class StateIcon extends StatelessWidget {
  const StateIcon(this.icon, {super.key, this.tone = StateTone.primary});

  final IconData icon;
  final StateTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      StateTone.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      StateTone.secondary => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      StateTone.error => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return ExcludeSemantics(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(icon, size: 36, color: foreground),
      ),
    );
  }
}

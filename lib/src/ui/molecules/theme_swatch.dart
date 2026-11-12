// lib/src/ui/molecules/theme_swatch.dart
//
// Um tema para escolher: as cores dele (no claro ou escuro de agora) e o nome. O
// escolhido ganha a borda e o "selecionado" do leitor de tela.
import 'package:material_ui/material_ui.dart';

import '../theme/chirp_theme.dart';

class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    super.key,
    required this.spec,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final ChirpThemeSpec spec;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  static const width = 84.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final own = chirpScheme(spec, theme.brightness);
    final corners = BorderRadius.circular(12);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: InkWell(
          onTap: onTap,
          borderRadius: corners,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  decoration: BoxDecoration(
                    color: own.surfaceContainerHighest,
                    borderRadius: corners,
                    border: Border.all(
                      color: selected ? scheme.primary : scheme.outlineVariant,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      for (final color in [
                        own.primary,
                        own.tertiary,
                        own.primaryContainer,
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(
                                  spec.style.bubbleRadius.clamp(2, 8),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

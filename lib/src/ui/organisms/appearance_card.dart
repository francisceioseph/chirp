// lib/src/ui/organisms/appearance_card.dart
//
// A aparência: claro, escuro ou o do sistema, e o tema. Muda na hora; se não gravar,
// volta e avisa.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../application/appearance_controller.dart';
import '../../core/chirp_core.dart';
import '../molecules/theme_swatch.dart';
import '../theme/chirp_theme.dart';
import '../theme_text.dart';

class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key, required this.controller});

  final AppearanceController controller;

  Future<void> _change(BuildContext context, Appearance next) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final text = context.l10n.appearanceNotSaved;
    if (!await controller.change(next)) {
      messenger?.showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.value;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.appearanceTitle, style: textTheme.titleMedium),
                const SizedBox(height: 12),
                Semantics(
                  container: true,
                  label: l10n.appearanceMode,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Estreito, só os ícones (o nome fica na dica e no leitor).
                      final narrow = constraints.maxWidth < 300;
                      ButtonSegment<AppearanceMode> segment(
                        AppearanceMode mode,
                        IconData icon,
                        String label,
                      ) => ButtonSegment(
                        value: mode,
                        icon: Icon(icon),
                        label: narrow ? null : Text(label),
                        tooltip: narrow ? label : null,
                      );
                      return SegmentedButton<AppearanceMode>(
                        showSelectedIcon: false,
                        segments: [
                          segment(
                            AppearanceMode.system,
                            Icons.brightness_auto_outlined,
                            l10n.modeSystem,
                          ),
                          segment(
                            AppearanceMode.light,
                            Icons.light_mode_outlined,
                            l10n.modeLight,
                          ),
                          segment(
                            AppearanceMode.dark,
                            Icons.dark_mode_outlined,
                            l10n.modeDark,
                          ),
                        ],
                        selected: {value.mode},
                        onSelectionChanged: (modes) =>
                            _change(context, value.copyWith(mode: modes.first)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.themeLabel, style: textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final spec in chirpThemes)
                      ThemeSwatch(
                        key: ValueKey(spec.id),
                        spec: spec,
                        name: themeName(l10n, spec.id),
                        selected: chirpThemeById(value.theme).id == spec.id,
                        onTap: () =>
                            _change(context, value.copyWith(theme: spec.id)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

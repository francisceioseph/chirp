import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final talkColor = isDark ? colorScheme.primary : const Color(0xFFC6A700);

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Chirp",
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: -1.0,
            ),
          ),
          Text(
            "Talk",
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: talkColor, // Cor ajustada aqui
              letterSpacing: -1.0,
              // Sombra sutil para destacar do fundo claro
              shadows: isDark
                  ? null
                  : [
                      Shadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
            ),
          ),
          const SizedBox(width: 16),
          _VersionBadge(isDark: isDark, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;

  const _VersionBadge({required this.isDark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        "BETA v1.0",
        style: TextStyle(
          color: isDark
              ? Colors.white54
              : colorScheme.primary.darken(0.25), // Mais legível no claro
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

extension ColorAlpha on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

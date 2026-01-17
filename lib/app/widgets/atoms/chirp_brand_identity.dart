import 'package:chirp/app/widgets/atoms/security_badge.dart';
import 'package:chirp/app/widgets/atoms/version_badge.dart';
import 'package:flutter/material.dart';

class ChirpBrandIdentity extends StatelessWidget {
  final CrossAxisAlignment alignment;
  final bool showVersion;
  final double fontSize;

  const ChirpBrandIdentity({
    super.key,
    this.alignment = CrossAxisAlignment.start,
    this.showVersion = true,
    this.fontSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final talkColor = isDark ? colorScheme.primary : const Color(0xFFC6A700);

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignment == CrossAxisAlignment.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Text(
              "Chirp",
              style: _titleStyle(theme, colorScheme.onSurface, 900),
            ),
            Text(
              "Talk",
              style: _titleStyle(
                theme,
                talkColor,
                300,
                isDark: isDark,
                shadowColor: colorScheme.primary,
              ),
            ),
            if (showVersion) ...[
              const SizedBox(width: 8),
              VersionBadge(isDark: isDark, colorScheme: colorScheme),
            ],
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 2.0),
          child: SecurityBadge(),
        ),
      ],
    );
  }

  TextStyle _titleStyle(
    ThemeData theme,
    Color color,
    int weight, {
    bool isDark = true,
    Color? shadowColor,
  }) {
    return theme.textTheme.displaySmall!.copyWith(
      fontSize: fontSize,
      fontWeight: weight == 900 ? FontWeight.w900 : FontWeight.w300,
      color: color,
      letterSpacing: -1.0,
      shadows: (!isDark && shadowColor != null)
          ? [Shadow(color: shadowColor.withValues(alpha: 0.2), blurRadius: 10)]
          : null,
    );
  }
}

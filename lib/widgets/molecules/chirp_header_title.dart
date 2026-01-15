import 'package:chirp/widgets/molecules/chirp_easter_egg.dart';
import 'package:chirp/widgets/atoms/security_badge.dart';
import 'package:chirp/widgets/atoms/version_badge.dart';
import 'package:flutter/material.dart';

class ChirpHeaderTitle extends StatefulWidget {
  const ChirpHeaderTitle({super.key});

  @override
  State<ChirpHeaderTitle> createState() => _ChirpHeaderTitleState();
}

class _ChirpHeaderTitleState extends State<ChirpHeaderTitle> {
  int _counter = 0;
  DateTime? _lastClick;

  void _handleEasterEgg() {
    final now = DateTime.now();
    if (_lastClick != null &&
        now.difference(_lastClick!) > const Duration(seconds: 2)) {
      _counter = 0;
    }
    _lastClick = now;
    _counter++;

    if (_counter == 7) {
      _counter = 0;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          content: const ChirpEasterEgg(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final talkColor = isDark ? colorScheme.primary : const Color(0xFFC6A700);

    return GestureDetector(
      onTap: _handleEasterEgg,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                const SizedBox(width: 8),
                VersionBadge(isDark: isDark, colorScheme: colorScheme),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 2.0, top: 2.0),
              child: SecurityBadge(),
            ),
          ],
        ),
      ),
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
      fontSize: 28,
      fontWeight: weight == 900 ? FontWeight.w900 : FontWeight.w300,
      color: color,
      letterSpacing: -1.0,
      shadows: (!isDark && shadowColor != null)
          ? [Shadow(color: shadowColor.withValues(alpha: 0.2), blurRadius: 10)]
          : null,
    );
  }
}

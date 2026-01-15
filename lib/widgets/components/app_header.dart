import 'package:chirp/widgets/components/header/easter_egg.dart';
import 'package:chirp/widgets/components/header/security_badge.dart';
import 'package:chirp/widgets/components/header/version_badge.dart';
import 'package:flutter/material.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  int _counter = 0;
  DateTime? _lastClick;

  void _handleEasterEgg() {
    final now = DateTime.now();

    // Reseta o contador se demorar mais de 2 segundos entre cliques
    if (_lastClick != null &&
        now.difference(_lastClick!) > const Duration(seconds: 2)) {
      _counter = 0;
    }

    _lastClick = now;
    _counter++;

    if (_counter == 7) {
      _counter = 0; // Reseta para poder ver de novo
      _showEasterEggModal();
    }
  }

  void _showEasterEggModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        content: EasterEgg(),
      ),
    );
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
        padding: const EdgeInsets.only(
          left: 8.0,
          bottom: 20.0,
        ), // Ajustado bottom para equilíbrio
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    color: talkColor,
                    letterSpacing: -1.0,
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
                const SizedBox(width: 12),
                VersionBadge(isDark: isDark, colorScheme: colorScheme),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2.0, top: 2.0),
              child: SecurityBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

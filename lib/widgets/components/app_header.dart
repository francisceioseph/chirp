import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(
                  "assets/images/mystical_eye.png",
                  height: 180,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Beware, beware. God sees all.",
              textAlign: TextAlign.center,
              style: GoogleFonts.medievalSharp(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
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
                _VersionBadge(isDark: isDark, colorScheme: colorScheme),
              ],
            ),

            // A nova linha da tecnologia
            Padding(
              padding: const EdgeInsets.only(left: 2.0, top: 2.0),
              child: Row(
                children: [
                  Icon(
                    Icons
                        .verified_user_rounded, // Ícone sutil de escudo/verificado
                    size: 10,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Tecnologia Secure Chirp \u2122",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

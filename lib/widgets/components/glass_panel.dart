import 'dart:ui';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassPanel({super.key, required this.child, this.borderRadius = 12.0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final outlineColor = isDark ? colorScheme.primary : colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : colorScheme.onSurface.withValues(alpha: 0.35),
            blurRadius: isDark ? 40 : 25,
            spreadRadius: isDark ? -10 : -5,
            offset: Offset(0, isDark ? 20 : 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
              child: Container(
                color: isDark
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.4),
                    colorScheme.surfaceTint.withValues(
                      alpha: isDark ? 0.1 : 0.02,
                    ),
                  ],
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  width: isDark ? 0.8 : 1.1,
                  color: outlineColor.withValues(alpha: isDark ? 0.2 : 0.15),
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      (isDark ? colorScheme.primary : Colors.white).withValues(
                        alpha: 0.4,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            child,
          ],
        ),
      ),
    );
  }
}

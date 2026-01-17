import 'dart:ui';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool
  forceMobileLayout; // Opcional: para testar o modo mobile no desktop

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 12.0,
    this.forceMobileLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800 || forceMobileLayout;

    final outlineColor = isDark ? colorScheme.primary : colorScheme.onSurface;

    return Container(
      margin: isMobile ? EdgeInsets.zero : const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: isMobile
            ? BorderRadius.zero
            : BorderRadius.circular(borderRadius),
        boxShadow: isMobile
            ? null
            : [
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
        borderRadius: isMobile
            ? BorderRadius.zero
            : BorderRadius.circular(borderRadius),
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

            if (!isMobile)
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

import 'dart:ui';
import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:flutter/material.dart';

class ChirpPanel extends StatelessWidget {
  final Widget child;
  final bool forceMobileLayout;

  const ChirpPanel({
    super.key,
    required this.child,
    this.forceMobileLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelTheme = theme.extension<ChirpPanelTheme>();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800 || forceMobileLayout;

    final decoration = isMobile
        ? panelTheme?.decoration?.copyWith(
            borderRadius: BorderRadius.zero,
            boxShadow: [],
          )
        : panelTheme?.decoration;

    final margin = isMobile
        ? EdgeInsets.zero
        : (panelTheme?.margin ?? const EdgeInsets.all(8));
    final blur = panelTheme?.blurSigma ?? 0.0;

    return Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: isMobile
            ? BorderRadius.zero
            : (decoration?.borderRadius?.resolve(Directionality.of(context)) ??
                  BorderRadius.zero),
        child: Stack(
          children: [
            if (blur > 0)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(color: Colors.transparent),
                ),
              ),

            if (panelTheme?.showTopGlow ?? false)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopGlowLine(primaryColor: theme.colorScheme.primary),
              ),

            child,
          ],
        ),
      ),
    );
  }
}

class _TopGlowLine extends StatelessWidget {
  final Color primaryColor;
  const _TopGlowLine({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            (isDark ? primaryColor : Colors.white).withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

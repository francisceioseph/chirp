import 'dart:ui';

import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:flutter/material.dart';

class DrawerBackground extends StatelessWidget {
  final ChirpPanelTheme? panelTheme;
  final Widget child;

  const DrawerBackground({super.key, this.panelTheme, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGlass = (panelTheme?.blurSigma ?? 0) > 0;

    if (!isGlass) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(left: BorderSide(color: theme.dividerColor)),
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: panelTheme!.blurSigma!,
          sigmaY: panelTheme!.blurSigma!,
        ),
        child: Container(
          decoration: panelTheme!.decoration?.copyWith(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(24),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.03,
                  child: Image.asset(
                    'assets/images/stardust.png',
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

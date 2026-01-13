import 'package:flutter/material.dart';
import 'liquid_orb.dart'; // Importe seu widget de esfera

class StackedOrbs extends StatelessWidget {
  const StackedOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: LiquidOrb(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.onSurface.withValues(alpha: 0.15), // Café sutil
            size: 400,
          ),
        ),

        Positioned(
          bottom: -150,
          left: 200,
          child: LiquidOrb(
            color: isDark
                ? colorScheme.secondary.withValues(alpha: 0.2)
                : colorScheme.primary.withValues(alpha: 0.2), // Cheddar sutil
            size: 500,
          ),
        ),

        if (!isDark)
          Positioned(
            top: 200,
            left: -100,
            child: LiquidOrb(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              size: 300,
            ),
          ),
      ],
    );
  }
}

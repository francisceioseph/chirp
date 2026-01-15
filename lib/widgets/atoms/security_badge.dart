import 'package:flutter/material.dart';

class SecurityBadge extends StatelessWidget {
  const SecurityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.verified_user_rounded,
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
    );
  }
}

import 'package:chirp/domain/entities/tiel.dart';
import 'package:flutter/material.dart';

class TielStatusBadge extends StatelessWidget {
  final TielStatus status;
  final Color badgeColor;

  const TielStatusBadge({
    super.key,
    required this.status,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.surface, width: 2),
        boxShadow: [
          if (status == TielStatus.connected)
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }
}

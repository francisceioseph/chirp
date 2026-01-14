import 'package:chirp/models/tiel.dart';
import 'package:flutter/material.dart';

class TielStatusBadge extends StatelessWidget {
  final TielStatus status;

  const TielStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color badgeColor = switch (status) {
      TielStatus.online => Colors.greenAccent,
      TielStatus.connected => theme.colorScheme.primary,
      TielStatus.away => Colors.amber,
      TielStatus.disconnected => Colors.blueGrey,
      TielStatus.error => theme.colorScheme.error,
    };

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.surface, width: 2),
        boxShadow: [
          if (status == TielStatus.connected || status == TielStatus.online)
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

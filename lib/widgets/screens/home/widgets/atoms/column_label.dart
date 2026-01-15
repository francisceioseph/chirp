import 'package:flutter/material.dart';

class ColumnLabel extends StatelessWidget {
  final String label;

  const ColumnLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.9),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

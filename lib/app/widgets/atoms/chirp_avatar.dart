import 'package:flutter/material.dart';

enum AvatarType { tiel, flock }

class ChirpAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AvatarType type;
  final double radius;
  final Widget? badge;

  const ChirpAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.type = AvatarType.tiel,
    this.radius = 16,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCircle(colorScheme, theme),
        if (badge != null) Positioned(bottom: -2, right: -2, child: badge!),
      ],
    );
  }

  Widget _buildCircle(ColorScheme colorScheme, ThemeData theme) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    if (type == AvatarType.flock) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          Icons.groups_rounded,
          size: radius * 1.2,
          color: colorScheme.primary,
        ),
      );
    }

    final initials = (name != null && name!.isNotEmpty)
        ? name![0].toUpperCase()
        : "?";

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.secondaryContainer,
      child: Text(
        initials,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

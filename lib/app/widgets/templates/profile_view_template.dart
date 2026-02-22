import 'package:chirp/app/widgets/atoms/chirp_avatar.dart';
import 'package:chirp/app/widgets/atoms/chirp_brand_identity.dart';
import 'package:flutter/material.dart';

class ProfileViewTemplate extends StatelessWidget {
  final String name;
  final String id;
  final String imageUrl;
  final List<Widget>? actions;

  const ProfileViewTemplate({
    super.key,
    required this.name,
    required this.id,
    required this.imageUrl,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeroAvatar(colorScheme),
          const SizedBox(height: 32),
          _buildIdentityHeader(theme, colorScheme),
          const SizedBox(height: 40),
          const Divider(thickness: 0.5, indent: 50, endIndent: 50),
          const SizedBox(height: 40),

          if (actions != null) ...[...actions!, const SizedBox(height: 40)],

          const Center(
            child: ChirpBrandIdentity(alignment: CrossAxisAlignment.center),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAvatar(ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: ChirpAvatar(
            name: name,
            imageUrl: imageUrl,
            radius: 65,
            heroTag: 'profile_avatar_$id',
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            id,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: colorScheme.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:chirp/app/widgets/screens/theme/atoms/theme_preview_thumbnail.dart';
import 'package:chirp/domain/entities/chirp_theme.dart';
import 'package:flutter/material.dart';

class ThemeSelectionTile extends StatelessWidget {
  final ChirpTheme chirpTheme;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeSelectionTile({
    super.key,
    required this.chirpTheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentBrightness = Theme.of(context).brightness;
    final previewTheme = currentBrightness == Brightness.light
        ? chirpTheme.light
        : chirpTheme.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: previewTheme.colorScheme.primary, width: 2)
              : Border.all(color: Colors.transparent),
          color: isSelected
              ? previewTheme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ThemePreviewThumbnail(
              themeData: previewTheme,
              isSelected: isSelected,
            ),
            const SizedBox(height: 12),
            Text(
              chirpTheme.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              chirpTheme.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

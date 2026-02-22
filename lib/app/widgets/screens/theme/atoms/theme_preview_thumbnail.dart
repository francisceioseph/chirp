import 'package:flutter/material.dart';

class ThemePreviewThumbnail extends StatelessWidget {
  final ThemeData themeData;
  final bool isSelected;

  const ThemePreviewThumbnail({
    super.key,
    required this.themeData,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = themeData.colorScheme;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colors.primary : colors.outlineVariant,
          width: isSelected ? 4 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            right: 15,
            bottom: 15,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

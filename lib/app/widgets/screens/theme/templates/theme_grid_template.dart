import 'package:chirp/app/widgets/screens/theme/molecules/theme_selection_tile.dart';
import 'package:chirp/domain/entities/chirp_theme.dart';
import 'package:flutter/material.dart';

class ThemeGridTemplate extends StatelessWidget {
  final List<ChirpTheme> themes;
  final void Function(ChirpTheme theme) onThemeSelected;
  final String selectedThemeId;

  const ThemeGridTemplate({
    super.key,
    required this.themes,
    required this.selectedThemeId,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Personalize seu bando",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Escolha um estilo que combine com sua Tiel. Cada tema altera cores, transparências e a alma do ChirpTalk.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final chirpTheme = themes[index];
              return ThemeSelectionTile(
                chirpTheme: chirpTheme,
                isSelected: chirpTheme.id == selectedThemeId,
                onTap: () => onThemeSelected(chirpTheme),
              );
            }, childCount: themes.length),
          ),
        ),
      ],
    );
  }
}

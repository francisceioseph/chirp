import 'package:chirp/app/controllers/theme_controller.dart';
import 'package:chirp/app/themes/chirp_theme_catalog.dart';
import 'package:chirp/app/widgets/screens/theme/templates/theme_grid_template.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:flutter/material.dart';

class ThemeSelectorScreen extends StatelessWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = getIt<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Temas"), centerTitle: false),
      body: ListenableBuilder(
        listenable: themeCtrl,
        builder: (context, _) {
          return ThemeGridTemplate(
            themes: ChirpThemeCatalog.all,
            selectedThemeId: themeCtrl.currentThemeId,
            onThemeSelected: (theme) {
              themeCtrl.setTheme(theme.id);
            },
          );
        },
      ),
    );
  }
}

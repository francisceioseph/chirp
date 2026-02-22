import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WildGreyGlassTheme {
  static const Color yellow = Color(0xFFFBC02D);
  static const Color cheek = Color(0xFFE64A19);
  static const Color grey = Color(0xFF263238);
  static const Color surface = Color(0xFF37474F);
  static const Color text = Color(0xFFECEFF1);

  static ThemeData get theme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: yellow,
        brightness: Brightness.dark,
        primary: yellow,
        secondary: cheek,
        surface: surface,
      ),
      scaffoldBackgroundColor: grey,
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(grey, text),
      tabBarTheme: TabBarThemeData(
        labelColor: yellow,
        unselectedLabelColor: text.withValues(alpha: 0.5),
        indicatorColor: yellow,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 35,
          margin: const EdgeInsets.all(8),
          showTopGlow: true,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                yellow.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(color: yellow.withValues(alpha: 0.2)),
          ),
        ),
      ],
    );
  }
}

import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SunnyLutinoGlassTheme {
  static const Color cheek = Color(0xFFF57C00);
  static const Color white = Color(0xFFFDFDF5);
  static const Color text = Color(0xFF42210B);

  static ThemeData get theme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cheek,
        primary: cheek,
        surface: white,
      ),
      scaffoldBackgroundColor: white,
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(white, text),
      cardTheme: ChirpThemeBase.baseCardTheme(
        Colors.white.withValues(alpha: 0.8),
      ),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(cheek, Colors.white),
      tabBarTheme: TabBarThemeData(
        labelColor: cheek,
        unselectedLabelColor: text.withValues(alpha: 0.6),
        indicatorColor: cheek,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 10,
          margin: const EdgeInsets.all(8),
          showTopGlow: true,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cheek.withValues(alpha: 0.2)),
          ),
        ),
      ],
    );
  }
}

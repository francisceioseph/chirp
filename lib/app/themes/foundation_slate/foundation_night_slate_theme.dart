import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FoundationNightSlateTheme {
  static const Color bg = Color(0xFF1A1D21);
  static const Color sidebar = Color(0xFF121417);
  static const Color accent = Color(0xFFFBC02D);

  static ThemeData get theme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(bg, Colors.white),
      cardTheme: ChirpThemeBase.baseCardTheme(sidebar, radius: 4),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        accent,
        bg,
        radius: 4,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: EdgeInsets.zero,
          showTopGlow: false,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
        ),
      ],
    );
  }
}

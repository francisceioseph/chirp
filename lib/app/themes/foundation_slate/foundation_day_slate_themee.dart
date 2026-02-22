import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FoundationDaySlateTheme {
  static const Color bg = Color(0xFFF9FAFB);
  static const Color sidebar = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFF57C00);
  static const Color text = Color(0xFF111827);

  static ThemeData get theme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        surface: sidebar,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(sidebar, text),
      cardTheme: ChirpThemeBase.baseCardTheme(sidebar, radius: 4),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        accent,
        Colors.white,
        radius: 4,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: EdgeInsets.zero,
          showTopGlow: false,
          decoration: BoxDecoration(
            color: sidebar,
            border: Border(
              right: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

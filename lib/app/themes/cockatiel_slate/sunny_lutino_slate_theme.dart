import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SunnyLutinoSlateTheme extends ChirpThemeBase {
  static const Color primary = Color(0xFFF57C00);
  static const Color background = Color(0xFFFCFCF7);
  static const Color surface = Color(0xFFF4F4F0);
  static const Color text = Color(0xFF2D1708);

  static ThemeData get theme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, surface: surface),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(background, text),
      cardTheme: ChirpThemeBase.baseCardTheme(surface, radius: 8),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        primary,
        Colors.white,
        radius: 8,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0, // Performance máxima
          margin: EdgeInsets.zero,
          showTopGlow: false,
          decoration: BoxDecoration(
            color: surface,
            border: Border(
              bottom: BorderSide(color: text.withValues(alpha: 0.05)),
            ),
          ),
        ),
      ],
    );
  }
}

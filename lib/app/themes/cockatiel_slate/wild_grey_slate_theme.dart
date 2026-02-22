import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WildGreySlateTheme extends ChirpThemeBase {
  static const Color accent = Color(0xFFFBC02D); // Amarelo crista
  static const Color bg = Color(0xFF1E272C); // Cinza azulado profundo
  static const Color surface = Color(0xFF263238); // Cinza chumbo
  static const Color text = Color(0xFFECEFF1);

  static ThemeData get theme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: accent,
        surface: surface,
      ),
      textTheme: GoogleFonts.workSansTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(bg, text),
      cardTheme: ChirpThemeBase.baseCardTheme(surface, radius: 12),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        accent,
        bg,
        radius: 12,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}

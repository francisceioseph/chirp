import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SymbianNightSlateTheme extends ChirpThemeBase {
  static const Color midnightBlue = Color(0xFF001221);
  static const Color nokiaSteel = Color(0xFF1A2A35);
  static const Color nokiaCyan = Color(0xFF00E5FF);

  static ThemeData get theme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnightBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: nokiaCyan,
        brightness: Brightness.dark,
        primary: nokiaCyan,
        surface: nokiaSteel,
      ),
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(midnightBlue, nokiaCyan),
      cardTheme: ChirpThemeBase.baseCardTheme(nokiaSteel, radius: 10),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        nokiaCyan,
        midnightBlue,
        radius: 10,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.all(4),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: nokiaSteel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: nokiaCyan.withValues(alpha: 0.2)),
          ),
        ),
      ],
    );
  }
}

import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OldNightsSlateTheme extends ChirpThemeBase {
  static const Color winBlack = Color(0xFF000000);
  static const Color winGreen = Color(0xFF00FF00);
  static const Color winPurple = Color(0xFF800080);

  static ThemeData get theme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: winBlack,
      colorScheme: ColorScheme.fromSeed(
        seedColor: winGreen,
        brightness: Brightness.dark,
        primary: winGreen,
        surface: Color(0xFF121212),
      ),
      textTheme: GoogleFonts.vt323TextTheme(
        base.textTheme,
      ), // Fonte pixelada para o look retrô total
      appBarTheme: ChirpThemeBase.baseAppBar(winBlack, winGreen),
      cardTheme: ChirpThemeBase.baseCardTheme(winBlack, radius: 0),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        winBlack,
        winGreen,
        radius: 0,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.all(2),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: winBlack,
            border: Border.all(color: winGreen, width: 1),
          ),
        ),
      ],
    );
  }
}

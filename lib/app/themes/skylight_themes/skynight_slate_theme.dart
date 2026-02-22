import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkyNightSlateTheme extends ChirpThemeBase {
  static const Color skypeDarkBlue = Color(0xFF00AFF0);
  static const Color deepNight = Color(0xFF04151E);
  static const Color surfaceBlue = Color(0xFF082736);

  static ThemeData get theme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepNight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: skypeDarkBlue,
        brightness: Brightness.dark,
        surface: surfaceBlue,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(deepNight, Colors.white),
      cardTheme: ChirpThemeBase.baseCardTheme(surfaceBlue, radius: 12),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        skypeDarkBlue,
        Colors.white,
        radius: 20,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: surfaceBlue,
            border: Border(left: BorderSide(color: skypeDarkBlue, width: 4)),
          ),
        ),
      ],
    );
  }
}

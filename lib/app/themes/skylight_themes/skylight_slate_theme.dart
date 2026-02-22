import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkylightSlateTheme extends ChirpThemeBase {
  static const Color skypeBlue = Color(0xFF00AFF0);
  static const Color cloudWhite = Color(0xFFF0F4F8);
  static const Color darkText = Color(0xFF003E51);

  static ThemeData get theme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: skypeBlue,
        primary: skypeBlue,
        surface: cloudWhite,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(skypeBlue, Colors.white),
      cardTheme: ChirpThemeBase.baseCardTheme(cloudWhite, radius: 12),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        skypeBlue,
        Colors.white,
        radius: 20,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: skypeBlue, width: 4),
            ), // A barrinha lateral clássica
          ),
        ),
      ],
    );
  }
}

import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OldDaysSlateTheme extends ChirpThemeBase {
  static const Color winGrey = Color(0xFFC0C0C0);
  static const Color winDark = Color(0xFF808080);
  static const Color winBlue = Color(0xFF000080); // Cor da barra de título

  static ThemeData get theme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: winGrey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: winBlue,
        primary: winBlue,
        surface: winGrey,
      ),
      textTheme: GoogleFonts.notoSansTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(winBlue, Colors.white),
      cardTheme: ChirpThemeBase.baseCardTheme(winGrey, radius: 0),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        winGrey,
        Colors.black,
        radius: 0,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.all(2),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: winGrey,
            border: Border.all(
              color: Colors.white,
              width: 1,
            ), // Simula o efeito 3D antigo
          ),
        ),
      ],
    );
  }
}

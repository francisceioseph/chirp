import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HumanDaySlateTheme extends ChirpThemeBase {
  static const Color aubergine = Color(0xFF4D1F40);
  static const Color canonicalOrange = Color(0xFFE95420);
  static const Color warmGrey = Color(0xFF333333);
  static const Color lightText = Color(0xFFAEA79F);

  static ThemeData get theme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: aubergine,
      colorScheme: ColorScheme.fromSeed(
        seedColor: canonicalOrange,
        brightness: Brightness.dark,
        primary: canonicalOrange,
        surface: warmGrey,
      ),
      textTheme: GoogleFonts.ubuntuTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(aubergine, Colors.white),
      cardTheme: ChirpThemeBase.baseCardTheme(warmGrey, radius: 6),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        canonicalOrange,
        Colors.white,
        radius: 4,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.only(left: 6),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            border: const Border(
              left: BorderSide(color: canonicalOrange, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

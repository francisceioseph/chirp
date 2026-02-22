import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HumanNightSlateTheme extends ChirpThemeBase {
  static const Color charcoal = Color(0xFF300A24);
  static const Color darkCarbon = Color(0xFF2C2C2C);
  static const Color ubuntuOrange = Color(0xFFE95420);

  static ThemeData get theme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: charcoal,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ubuntuOrange,
        brightness: Brightness.dark,
        primary: ubuntuOrange,
        surface: darkCarbon,
      ),
      textTheme: GoogleFonts.ubuntuTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(charcoal, Colors.white),
      cardTheme: ChirpThemeBase.baseCardTheme(darkCarbon, radius: 4),
      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        ubuntuOrange,
        Colors.white,
        radius: 4,
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.only(left: 6),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: const Border(
              left: BorderSide(color: ubuntuOrange, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}

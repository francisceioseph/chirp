import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/themes/chirp_theme_base.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SymbianDaySlateTheme extends ChirpThemeBase {
  static const Color nokiaBlue = Color(0xFF003580);
  static const Color nokiaSurface = Color(0xFFE6E9ED);
  static const Color nokiaActive = Color(0xFF00A1E4);
  static const Color nokiaText = Color(0xFF001530);

  static ThemeData get theme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: nokiaBlue,
        primary: nokiaBlue,
        secondary: nokiaActive,
        surface: nokiaSurface,
      ),
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
      appBarTheme: ChirpThemeBase.baseAppBar(nokiaBlue, Colors.white),
      cardTheme: ChirpThemeBase.baseCardTheme(nokiaSurface, radius: 8),

      elevatedButtonTheme: ChirpThemeBase.baseButtonTheme(
        nokiaBlue,
        Colors.white,
        radius: 12,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: nokiaBlue,
        unselectedLabelColor: nokiaText.withValues(alpha: 0.5),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 4, color: nokiaActive),
        ),
      ),

      extensions: [
        ChirpPanelTheme(
          blurSigma: 0,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          showTopGlow: false,
          decoration: BoxDecoration(
            color: nokiaSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: nokiaBlue.withValues(alpha: 0.1)),
          ),
        ),
      ],
    );
  }
}

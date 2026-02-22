import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class ChirpThemeBase {
  static AppBarTheme baseAppBar(Color bg, Color fg) => AppBarTheme(
    backgroundColor: bg.withValues(alpha: 0.8),
    foregroundColor: fg,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.urbanist(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: fg,
    ),
  );

  static CardThemeData baseCardTheme(Color color, {double radius = 24}) =>
      CardThemeData(
        color: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      );

  static ElevatedButtonThemeData baseButtonTheme(
    Color bg,
    Color fg, {
    double radius = 16,
  }) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class MightyCatsNightSlateTheme {
  static ThemeData get theme {
    final base = ThemeData.dark();

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0A84FF),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: ColorScheme.dark(
        surface: const Color(0xFF2C2C2E),
        onSurface: Colors.white,
        primary: const Color(0xFF0A84FF),
        secondary: const Color(0xFF64D2FF),
        outline: Colors.white10,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 8,
        shadowColor: Colors.black,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF242426),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineSmall: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: GoogleFonts.inter(
          color: Colors.white38,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

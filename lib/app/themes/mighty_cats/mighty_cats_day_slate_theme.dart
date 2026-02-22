import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class MightyCatsDaySlateTheme {
  static ThemeData get theme {
    final base = ThemeData.light();

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF007AFF),
      scaffoldBackgroundColor: const Color(0xFFE0E0E0),
      colorScheme: ColorScheme.light(
        surface: const Color(0xFFF5F5F7),
        onSurface: Colors.black87,
        primary: const Color(0xFF0066CC),
        secondary: const Color(0xFF8E8E93),
        outline: Colors.black26,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFBDBDBD),
        foregroundColor: Colors.black87,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white70, width: 1),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          shadows: [
            const Shadow(
              offset: Offset(0, 1),
              color: Colors.white,
              blurRadius: 0,
            ),
          ],
        ),
        headlineSmall: GoogleFonts.inter(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: GoogleFonts.inter(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: GoogleFonts.inter(
          color: Colors.black45,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

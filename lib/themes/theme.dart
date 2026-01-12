import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class ChirpThemes {
  static const Color _lutinoYellow = Color(0xFFFFD700);
  static const Color _lutinoCheek = Color(0xFFFF7043);
  static const Color _lutinoWhite = Color(0xFFF9F9F9);
  static const Color _lutinoText = Color(0xFF424242);

  static const Color _wildYellow = Color(0xFFFBC02D);
  static const Color _wildCheek = Color(0xFFE64A19);
  static const Color _wildGrey = Color(0xFF263238);
  static const Color _wildSurface = Color(0xFF37474F);
  static const Color _wildText = Color(0xFFECEFF1);

  static ThemeData get sunnyLutino {
    var base = ThemeData.light();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lutinoYellow,
        primary: _lutinoYellow,
        onPrimary: Colors.white,
        secondary: _lutinoCheek,
        surface: _lutinoWhite,
        background: _lutinoWhite,
      ),
      scaffoldBackgroundColor: _lutinoWhite,
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme),
      appBarTheme: _baseAppBar(_lutinoWhite, _lutinoText),
      cardTheme: _baseCardTheme(Colors.white.withOpacity(0.8)), 
      elevatedButtonTheme: _baseButtonTheme(_lutinoYellow, Colors.white),
    );
  }

  static ThemeData get greyWild {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _wildYellow,
        brightness: Brightness.dark,
        primary: _wildYellow,
        onPrimary: _wildGrey,
        secondary: _wildCheek,
        surface: _wildSurface,
        background: _wildGrey,
      ),
      scaffoldBackgroundColor: _wildGrey,
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme),
      appBarTheme: _baseAppBar(_wildGrey, _wildText),
      cardTheme: _baseCardTheme(_wildSurface.withOpacity(0.6)),
      elevatedButtonTheme: _baseButtonTheme(_wildYellow, _wildGrey),
    );
  }

  static AppBarTheme _baseAppBar(Color bg, Color fg) => AppBarTheme(
        backgroundColor: bg.withOpacity(0.1),
        foregroundColor: fg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.urbanist(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      );

  static CardThemeData _baseCardTheme(Color color) => CardThemeData(
        color: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      );

  static ElevatedButtonThemeData _baseButtonTheme(Color bg, Color fg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      );
}
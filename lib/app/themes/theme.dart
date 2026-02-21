import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chirp_panel_theme.dart';

abstract class ChirpThemes {
  static const Color _lutinoCheek = Color(0xFFF57C00);
  static const Color _lutinoWhite = Color(0xFFFDFDF5);
  static const Color _lutinoText = Color(0xFF42210B);

  static const Color _wildYellow = Color(0xFFFBC02D);
  static const Color _wildCheek = Color(0xFFE64A19);
  static const Color _wildGrey = Color(0xFF263238);
  static const Color _wildSurface = Color(0xFF37474F);
  static const Color _wildText = Color(0xFFECEFF1);

  static const Color _slateBg = Color(0xFF1A1D21);
  static const Color _slateSidebar = Color(0xFF121417);

  static ThemeData get sunnyLutino {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lutinoCheek,
        primary: _lutinoCheek,
        surface: _lutinoWhite,
      ),
      scaffoldBackgroundColor: _lutinoWhite,
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme),
      appBarTheme: _baseAppBar(_lutinoWhite, _lutinoText),
      cardTheme: _baseCardTheme(
        Colors.white.withValues(alpha: 0.8),
        radius: 24,
      ),
      elevatedButtonTheme: _baseButtonTheme(
        _lutinoCheek,
        Colors.white,
        radius: 16,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _lutinoCheek,
        unselectedLabelColor: _lutinoText.withValues(alpha: 0.6),
        indicatorColor: _lutinoCheek,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 10,
          margin: const EdgeInsets.all(8),
          showTopGlow: true,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _lutinoCheek.withValues(alpha: 0.2)),
          ),
        ),
      ],
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
        secondary: _wildCheek,
        surface: _wildSurface,
      ),
      scaffoldBackgroundColor: _wildGrey,
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme),
      appBarTheme: _baseAppBar(_wildGrey, _wildText),
      cardTheme: _baseCardTheme(
        _wildSurface.withValues(alpha: 0.6),
        radius: 24,
      ),
      elevatedButtonTheme: _baseButtonTheme(_wildYellow, _wildGrey, radius: 16),
      tabBarTheme: TabBarThemeData(
        labelColor: _wildYellow,
        unselectedLabelColor: _wildText.withValues(alpha: 0.5),
        indicatorColor: _wildYellow,
        indicatorSize:
            TabBarIndicatorSize.label, // Fica mais elegante no Desktop
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 35,
          margin: const EdgeInsets.all(8),
          showTopGlow: true,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                _wildYellow.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(color: _wildYellow.withValues(alpha: 0.2)),
          ),
        ),
      ],
    );
  }

  static ThemeData get slateFlat {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _slateBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _wildYellow,
        brightness: Brightness.dark,
        surface: _slateBg,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: _baseAppBar(_slateBg, Colors.white),
      cardTheme: _baseCardTheme(_slateSidebar, radius: 4),
      elevatedButtonTheme: _baseButtonTheme(_wildYellow, _wildGrey, radius: 4),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.3),
        indicatorColor: _wildYellow, // O detalhe de cor que quebra a sobriedade
      ),
      extensions: [
        ChirpPanelTheme(
          blurSigma: 0, // Sem blur para performance e foco
          margin: EdgeInsets.zero, // Painéis encostados
          showTopGlow: false,
          decoration: BoxDecoration(
            color: _slateBg,
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static AppBarTheme _baseAppBar(Color bg, Color fg) => AppBarTheme(
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

  static CardThemeData _baseCardTheme(Color color, {double radius = 24}) =>
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

  static ElevatedButtonThemeData _baseButtonTheme(
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

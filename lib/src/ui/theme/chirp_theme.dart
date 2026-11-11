// lib/src/ui/theme/chirp_theme.dart
//
// O tema do Chirp: Material 3 a partir de um ChirpThemeSpec. O theme/ é o único lugar
// com cor escrita à mão; os widgets pegam tudo do colorScheme e do ChirpStyle (o
// privacy_test confere).
import 'package:flutter/material.dart';

import 'chirp_themes.dart';

export 'chirp_style.dart';
export 'chirp_themes.dart';

/// O QR fica escuro sobre claro nos dois temas: leitores de QR esperam assim.
const qrDark = Color(0xFF000000);
const qrLight = Color(0xFFFFFFFF);

ColorScheme chirpScheme(ChirpThemeSpec spec, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: spec.seed,
    brightness: brightness,
    dynamicSchemeVariant: spec.variant,
  );
  final tertiary = spec.tertiary;
  if (tertiary == null) return scheme;
  // A terciária vem da semente dela, com os mesmos tons da primária de lá.
  final accent = ColorScheme.fromSeed(
    seedColor: tertiary,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );
  return scheme.copyWith(
    tertiary: accent.primary,
    onTertiary: accent.onPrimary,
    tertiaryContainer: accent.primaryContainer,
    onTertiaryContainer: accent.onPrimaryContainer,
  );
}

ThemeData chirpTheme(Brightness brightness, {ChirpThemeSpec? spec}) {
  spec ??= chirpThemes.first;
  final scheme = chirpScheme(spec, brightness);
  final corners = BorderRadius.circular(spec.radius);
  final rounded = RoundedRectangleBorder(borderRadius: corners);
  // Com cantos grandes, os botões são pílulas, como no M3; com pequenos, seguem o tema.
  final OutlinedBorder button = spec.radius >= 12
      ? const StadiumBorder()
      : RoundedRectangleBorder(borderRadius: corners);
  final buttonStyle = ButtonStyle(shape: WidgetStatePropertyAll(button));
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: spec.density,
    extensions: [spec.style],
    cardTheme: CardThemeData(shape: rounded),
    dialogTheme: DialogThemeData(shape: rounded),
    chipTheme: ChipThemeData(shape: rounded),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: buttonStyle),
    segmentedButtonTheme: SegmentedButtonThemeData(style: buttonStyle),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.radius.clamp(2, 16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: corners),
    ),
  );
}

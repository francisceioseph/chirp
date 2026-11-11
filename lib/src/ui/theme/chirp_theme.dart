// lib/src/ui/theme/chirp_theme.dart
//
// O tema do Chirp: Material 3 a partir de uma semente. É o único lugar com cor escrita
// à mão; os widgets pegam tudo do colorScheme (o privacy_test confere). As outras
// sementes (Wild Grey, Skylight, Old Days...) entram na fase 4 (docs/PLANO.md, 10.1).
import 'package:flutter/material.dart';

/// O amarelo-queijo da calopsita lutino, o tema padrão.
const lutinoSeed = Color(0xFFFFC107);

/// O QR fica escuro sobre claro nos dois temas: leitores de QR esperam assim.
const qrDark = Color(0xFF000000);
const qrLight = Color(0xFFFFFFFF);

ThemeData chirpTheme(Brightness brightness, {Color seed = lutinoSeed}) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
  );
}

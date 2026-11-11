// lib/src/ui/theme/chirp_themes.dart
//
// Os temas do Chirp são sementes com personalidade (docs/PLANO.md, 10.1): cada um diz
// a semente, a variante do M3, uma terciária quando a personalidade pede, os cantos,
// a densidade e as bolhas. O Material 3 faz o resto, com o contraste garantido.
import 'package:flutter/material.dart';

import 'chirp_style.dart';

@immutable
class ChirpThemeSpec {
  const ChirpThemeSpec({
    required this.id,
    required this.seed,
    required this.variant,
    required this.radius,
    this.tertiary,
    this.density = VisualDensity.standard,
    this.style = const ChirpStyle(),
  });

  /// O id gravado no banco (minúsculas e hífens).
  final String id;
  final Color seed;
  final DynamicSchemeVariant variant;

  /// A semente da terciária (a bochecha laranja da calopsita cinza, por exemplo).
  final Color? tertiary;

  /// O canto dos cartões, diálogos e campos.
  final double radius;
  final VisualDensity density;
  final ChirpStyle style;
}

/// Na ordem em que a escolha mostra; o primeiro é o padrão.
const chirpThemes = <ChirpThemeSpec>[
  // O amarelo-queijo da calopsita lutino.
  ChirpThemeSpec(
    id: 'lutino',
    seed: Color(0xFFFFC107),
    variant: DynamicSchemeVariant.fidelity,
    radius: 16,
    style: ChirpStyle(bubbleRadius: 18, tailRadius: 4),
  ),
  // A calopsita cinza, com a bochecha laranja.
  ChirpThemeSpec(
    id: 'wild-grey',
    seed: Color(0xFF8D8D8D),
    tertiary: Color(0xFFF08A24),
    variant: DynamicSchemeVariant.neutral,
    radius: 16,
    style: ChirpStyle(bubbleRadius: 18, tailRadius: 4),
  ),
  // O azul dos mensageiros dos anos 2000.
  ChirpThemeSpec(
    id: 'skylight',
    seed: Color(0xFF2F7FD8),
    variant: DynamicSchemeVariant.vibrant,
    radius: 12,
    style: ChirpStyle(bubbleRadius: 14, tailRadius: 3),
  ),
  // O cinza e o azul-marinho de um desktop de 2000: cantos retos e compacto.
  ChirpThemeSpec(
    id: 'old-days',
    seed: Color(0xFF0A246A),
    variant: DynamicSchemeVariant.neutral,
    radius: 2,
    density: VisualDensity.compact,
    style: ChirpStyle(bubbleRadius: 3, tailRadius: 0),
  ),
  // O laranja e a beringela de um Linux antigo.
  ChirpThemeSpec(
    id: 'human',
    seed: Color(0xFFDD4814),
    tertiary: Color(0xFF77216F),
    variant: DynamicSchemeVariant.tonalSpot,
    radius: 10,
    style: ChirpStyle(bubbleRadius: 12, tailRadius: 3),
  ),
  // O verde dos celulares de teclas.
  ChirpThemeSpec(
    id: 'symbian',
    seed: Color(0xFF52A43A),
    variant: DynamicSchemeVariant.content,
    radius: 6,
    density: VisualDensity.compact,
    style: ChirpStyle(bubbleRadius: 8, tailRadius: 2),
  ),
  // O azul-petróleo e o dourado das capas de ficção científica.
  ChirpThemeSpec(
    id: 'foundation',
    seed: Color(0xFF1F6F78),
    tertiary: Color(0xFFC9A227),
    variant: DynamicSchemeVariant.tonalSpot,
    radius: 20,
    style: ChirpStyle(bubbleRadius: 22, tailRadius: 6),
  ),
  // O alumínio escovado com o azul-água dos botões.
  ChirpThemeSpec(
    id: 'mighty-cats',
    seed: Color(0xFFA7B1BC),
    tertiary: Color(0xFF3A8EE6),
    variant: DynamicSchemeVariant.neutral,
    radius: 8,
    style: ChirpStyle(bubbleRadius: 12, tailRadius: 4),
  ),
];

/// O tema de um id; um id desconhecido (de uma versão mais nova) vira o padrão.
ChirpThemeSpec chirpThemeById(String id) =>
    chirpThemes.firstWhere((t) => t.id == id, orElse: () => chirpThemes.first);

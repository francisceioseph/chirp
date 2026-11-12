// lib/src/ui/theme/chirp_style.dart
//
// O que o Material 3 não diz e cada tema do Chirp diz: o formato das bolhas, e o
// efeito vidro, se escolhido. Os widgets leem pelo `ChirpStyle.of(context)`.
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

@immutable
class ChirpStyle extends ThemeExtension<ChirpStyle> {
  const ChirpStyle({
    this.bubbleRadius = 16,
    this.tailRadius = 4,
    this.glass = false,
    this.reachable = const Color(0xFF2E7D32),
  });

  /// O canto redondo das bolhas.
  final double bubbleRadius;

  /// O canto do lado de quem falou (a "cauda").
  final double tailRadius;

  /// O efeito vidro foi escolhido (veja [glassOn]).
  final bool glass;

  /// O anel de quem está ao alcance agora (o verde de "conectado" dos mensageiros
  /// antigos), com contraste no claro e no escuro: o `chirpTheme` escolhe.
  final Color reachable;

  static ChirpStyle of(BuildContext context) =>
      Theme.of(context).extension<ChirpStyle>() ?? const ChirpStyle();

  /// O vidro vale agora: escolhido, e o sistema não pede menos animação nem mais
  /// contraste (o vidro mexe com o que passa por baixo e tira contraste).
  static bool glassOn(BuildContext context) =>
      of(context).glass &&
      !MediaQuery.disableAnimationsOf(context) &&
      !MediaQuery.highContrastOf(context);

  /// A bolha de uma mensagem: a cauda fica embaixo, do lado de quem mandou.
  BorderRadius bubble({required bool mine}) => BorderRadius.only(
    topLeft: Radius.circular(bubbleRadius),
    topRight: Radius.circular(bubbleRadius),
    bottomLeft: Radius.circular(mine ? bubbleRadius : tailRadius),
    bottomRight: Radius.circular(mine ? tailRadius : bubbleRadius),
  );

  @override
  ChirpStyle copyWith({
    double? bubbleRadius,
    double? tailRadius,
    bool? glass,
    Color? reachable,
  }) => ChirpStyle(
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    tailRadius: tailRadius ?? this.tailRadius,
    glass: glass ?? this.glass,
    reachable: reachable ?? this.reachable,
  );

  @override
  ChirpStyle lerp(ChirpStyle? other, double t) {
    if (other == null) return this;
    return ChirpStyle(
      bubbleRadius: lerpDouble(bubbleRadius, other.bubbleRadius, t)!,
      tailRadius: lerpDouble(tailRadius, other.tailRadius, t)!,
      glass: t < 0.5 ? glass : other.glass,
      reachable: Color.lerp(reachable, other.reachable, t)!,
    );
  }
}

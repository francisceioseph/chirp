// lib/src/ui/theme/chirp_style.dart
//
// O que o Material 3 não diz e cada tema do Chirp diz: o formato das bolhas. Os
// widgets leem pelo `ChirpStyle.of(context)`.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

@immutable
class ChirpStyle extends ThemeExtension<ChirpStyle> {
  const ChirpStyle({this.bubbleRadius = 16, this.tailRadius = 4});

  /// O canto redondo das bolhas.
  final double bubbleRadius;

  /// O canto do lado de quem falou (a "cauda").
  final double tailRadius;

  static ChirpStyle of(BuildContext context) =>
      Theme.of(context).extension<ChirpStyle>() ?? const ChirpStyle();

  /// A bolha de uma mensagem: a cauda fica embaixo, do lado de quem mandou.
  BorderRadius bubble({required bool mine}) => BorderRadius.only(
    topLeft: Radius.circular(bubbleRadius),
    topRight: Radius.circular(bubbleRadius),
    bottomLeft: Radius.circular(mine ? bubbleRadius : tailRadius),
    bottomRight: Radius.circular(mine ? tailRadius : bubbleRadius),
  );

  @override
  ChirpStyle copyWith({double? bubbleRadius, double? tailRadius}) => ChirpStyle(
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    tailRadius: tailRadius ?? this.tailRadius,
  );

  @override
  ChirpStyle lerp(ChirpStyle? other, double t) {
    if (other == null) return this;
    return ChirpStyle(
      bubbleRadius: lerpDouble(bubbleRadius, other.bubbleRadius, t)!,
      tailRadius: lerpDouble(tailRadius, other.tailRadius, t)!,
    );
  }
}

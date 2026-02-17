import 'package:flutter/material.dart';

class ChirpPanelTheme extends ThemeExtension<ChirpPanelTheme> {
  final BoxDecoration? decoration;
  final double? blurSigma;
  final EdgeInsetsGeometry margin;
  final bool showTopGlow;

  ChirpPanelTheme({
    this.decoration,
    this.blurSigma,
    required this.margin,
    this.showTopGlow = false,
  });

  @override
  ChirpPanelTheme copyWith({
    BoxDecoration? decoration,
    double? blurSigma,
    EdgeInsetsGeometry? margin,
    bool? showTopGlow,
  }) => ChirpPanelTheme(
    decoration: decoration ?? this.decoration,
    blurSigma: blurSigma ?? this.blurSigma,
    margin: margin ?? this.margin,
    showTopGlow: showTopGlow ?? this.showTopGlow,
  );

  @override
  ChirpPanelTheme lerp(ThemeExtension<ChirpPanelTheme>? other, double t) {
    if (other is! ChirpPanelTheme) return this;

    return ChirpPanelTheme(
      decoration: BoxDecoration.lerp(decoration, other.decoration, t),
      blurSigma:
          (blurSigma ?? 0) + ((other.blurSigma ?? 0) - (blurSigma ?? 0)) * t,
      margin: EdgeInsetsGeometry.lerp(margin, other.margin, t)!,
      showTopGlow: t < 0.5 ? showTopGlow : other.showTopGlow,
    );
  }
}

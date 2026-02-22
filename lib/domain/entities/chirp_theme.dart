import 'package:flutter/material.dart';

enum ChirpThemeFamily {
  lutino,
  wild,
  skylight,
  oldDays,
  human,
  symbian,
  foundation,
}

class ChirpTheme {
  final String id;
  final String name;
  final String description;
  final ChirpThemeFamily family;
  final ThemeData light;
  final ThemeData dark;

  const ChirpTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.family,
    required this.light,
    required this.dark,
  });
}

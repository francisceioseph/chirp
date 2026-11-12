// As regras de desenho da seção 10 do plano que se conferem no código: o texto pelo
// textTheme, todo botão de ícone com dica (o nome no leitor de tela), nenhum emoji
// em texto fixo e os temas como o plano pede. As cores e os botões ficam no
// privacy_test; o contraste e os rótulos de cada tela, nos testes delas.
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/src/ui/theme/chirp_theme.dart';

List<File> _ui() => [
  for (final file in Directory('lib/src/ui').listSync(recursive: true))
    if (file is File && file.path.endsWith('.dart')) file,
];

/// O trecho de [source] da chamada que abre em [start] até o parêntese que fecha.
String _call(String source, int start) {
  var depth = 0;
  for (var i = source.indexOf('(', start); i < source.length; i++) {
    if (source[i] == '(') depth++;
    if (source[i] == ')' && --depth == 0) return source.substring(start, i);
  }
  return source.substring(start);
}

bool _emoji(int rune) =>
    (rune >= 0x1F000 && rune <= 0x1FAFF) ||
    (rune >= 0x2600 && rune <= 0x27BF) ||
    rune == 0xFE0F;

void main() {
  test('o tamanho do texto vem do textTheme', () {
    final found = [
      for (final file in _ui())
        if (file.readAsStringSync().contains('fontSize:')) file.path,
    ];
    expect(found, isEmpty);
  });

  test('todo botão de ícone tem dica', () {
    final found = <String>[];
    for (final file in _ui()) {
      final source = file.readAsStringSync();
      for (final match in RegExp(
        r'\bIconButton(\.(filled|filledTonal|outlined))?\(',
      ).allMatches(source)) {
        if (!_call(source, match.start).contains('tooltip:')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          found.add('${file.path}:${line + 1}');
        }
      }
    }
    expect(found, isEmpty);
  });

  test('nenhum emoji nos textos dos sete idiomas', () {
    final found = <String>[];
    for (final file in Directory('lib/l10n').listSync()) {
      if (!file.path.endsWith('.arb')) continue;
      final messages = jsonDecode((file as File).readAsStringSync()) as Map;
      messages.forEach((key, value) {
        if (value is String && value.runes.any(_emoji)) {
          found.add('${file.path}: $key');
        }
      });
    }
    expect(found, isEmpty);
  });

  group('os temas', () {
    test('os oito do plano, com o Lutino de padrão', () {
      expect(chirpThemes.map((t) => t.id), [
        'lutino',
        'wild-grey',
        'skylight',
        'old-days',
        'human',
        'symbian',
        'foundation',
        'mighty-cats',
      ]);
    });

    test('cada um em Material 3, com o ChirpStyle e o canto dele', () {
      for (final spec in chirpThemes) {
        for (final brightness in Brightness.values) {
          final theme = chirpTheme(brightness, spec: spec);
          expect(theme.useMaterial3, isTrue);
          expect(theme.colorScheme.brightness, brightness);
          expect(
            theme.extension<ChirpStyle>()?.bubbleRadius,
            spec.style.bubbleRadius,
          );
          final card = theme.cardTheme.shape! as RoundedRectangleBorder;
          // Os cartões são um degrau mais redondos que os campos (o M3 Expressive).
          expect(card.borderRadius, BorderRadius.circular(spec.radius + 8));
        }
      }
    });

    test('a terciária vem da semente dela quando o tema tem uma', () {
      for (final spec in chirpThemes.where((t) => t.tertiary != null)) {
        final plain = ColorScheme.fromSeed(
          seedColor: spec.seed,
          dynamicSchemeVariant: spec.variant,
        );
        expect(
          chirpScheme(spec, Brightness.light).tertiary,
          isNot(plain.tertiary),
        );
      }
    });
  });
}

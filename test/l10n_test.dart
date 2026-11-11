// Todos os idiomas têm as mesmas mensagens e os mesmos marcadores do modelo em inglês.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';

import 'helpers.dart';

Map<String, String> _messages(String code) {
  final arb = jsonDecode(
    File('lib/l10n/chirp_$code.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    for (final entry in arb.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

Set<String> _placeholders(String message) => {
  for (final match in RegExp(r'\{(\w+)[,}]').allMatches(message)) match[1]!,
};

void main() {
  final codes = [
    for (final locale in ChirpLocalizations.supportedLocales)
      locale.languageCode,
  ];
  final template = _messages('en');

  test('os sete idiomas do Psito estão aqui', () {
    expect(codes.toSet(), {'en', 'pt', 'es', 'fr', 'de', 'ru', 'zh'});
  });

  for (final code in codes) {
    test('$code tem as mesmas mensagens e marcadores do modelo', () {
      final messages = _messages(code);
      expect(messages.keys.toSet(), template.keys.toSet());
      for (final entry in template.entries) {
        expect(
          _placeholders(messages[entry.key]!),
          _placeholders(entry.value),
          reason: entry.key,
        );
      }
    });

    for (final (name, available) in [('cadastro', true), ('senha', false)]) {
      testWidgets('$code: $name cabe num celular pequeno', (tester) async {
        tester.platformDispatcher.localesTestValue = [Locale(code)];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        setWindow(tester, 320, 568);
        await pumpChirp(tester, vault: FakeVault(available: available));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$code: o perfil cabe num celular pequeno', (tester) async {
      tester.platformDispatcher.localesTestValue = [Locale(code)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      setWindow(tester, 320, 568);
      final (core, vault) = await withProfile('Calopsita com um nome longo');
      await pumpChirp(tester, core: core, vault: vault);
      expect(tester.takeException(), isNull);
    });
  }
}

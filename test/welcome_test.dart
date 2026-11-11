import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  testWidgets('mostra a promessa e a versão do núcleo', (tester) async {
    await pumpChirp(tester);
    expect(find.text(l10n.welcomeTitle), findsOneWidget);
    expect(find.text(l10n.welcomeBody), findsOneWidget);
    expect(find.text(l10n.coreVersion('9.9.9', 1)), findsOneWidget);
  });

  testWidgets('diz quando o núcleo não abriu', (tester) async {
    await pumpChirp(tester, core: const FakeCore(null));
    expect(find.text(l10n.coreUnavailable), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('cabe na janela mínima no tema ${brightness.name}', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      setWindow(tester, 240, 160);
      await pumpChirp(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('o texto passa no contraste e tem rótulos', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpChirp(tester);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}

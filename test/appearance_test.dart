// A aparência da fase 4: os temas por semente, o claro e o escuro, gravados no banco
// e de volta ao padrão quando o banco é apagado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/application/appearance_controller.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:psito_chirp/src/ui/theme/chirp_theme.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> openProfile(WidgetTester tester) async {
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    return core.store!;
  }

  Future<void> showAppearance(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text(l10n.themeLabel),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  ThemeData current(WidgetTester tester) =>
      Theme.of(tester.element(find.text(l10n.appearanceTitle)));

  group('AppearanceController', () {
    test('lê a do banco, grava a nova e volta ao padrão sem banco', () async {
      final store = FakeStore()
        ..savedAppearance = const Appearance(
          theme: 'human',
          mode: AppearanceMode.dark,
        );
      final controller = AppearanceController();
      await controller.attach(store);
      expect(controller.value.theme, 'human');

      expect(
        await controller.change(controller.value.copyWith(theme: 'symbian')),
        isTrue,
      );
      expect(store.savedAppearance.theme, 'symbian');

      await controller.attach(null);
      expect(controller.value, const Appearance());
    });

    test('se não grava, volta a de antes', () async {
      final store = FakeStore()..appearanceFails = true;
      final controller = AppearanceController();
      await controller.attach(store);
      var changes = 0;
      controller.addListener(() => changes++);
      expect(
        await controller.change(const Appearance(theme: 'skylight')),
        isFalse,
      );
      expect(controller.value, const Appearance());
      expect(changes, 2);
    });
  });

  test('os temas têm ids diferentes, e um desconhecido vira o padrão', () {
    expect(chirpThemes.map((t) => t.id).toSet(), hasLength(chirpThemes.length));
    expect(chirpThemes, hasLength(8));
    expect(chirpThemeById('de-uma-versao-nova').id, 'lutino');
  });

  testWidgets('escolher o tema e o escuro muda o app e grava', (tester) async {
    final store = await openProfile(tester);
    await showAppearance(tester);
    expect(
      ChirpStyle.of(tester.element(find.text(l10n.themeLabel))),
      chirpThemeById('lutino').style,
    );

    await tester.tap(find.bySemanticsLabel(l10n.themeSkylight));
    await tester.pumpAndSettle();
    expect(store.savedAppearance.theme, 'skylight');
    expect(
      ChirpStyle.of(tester.element(find.text(l10n.themeLabel))).bubbleRadius,
      chirpThemeById('skylight').style.bubbleRadius,
    );

    await tester.tap(find.text(l10n.modeDark));
    await tester.pumpAndSettle();
    expect(store.savedAppearance.mode, AppearanceMode.dark);
    expect(current(tester).brightness, Brightness.dark);
  });

  testWidgets('se não grava, avisa e volta', (tester) async {
    final store = await openProfile(tester);
    store.appearanceFails = true;
    await showAppearance(tester);
    await tester.tap(find.bySemanticsLabel(l10n.themeHuman));
    await tester.pumpAndSettle();
    expect(find.text(l10n.appearanceNotSaved), findsOneWidget);
    expect(store.savedAppearance.theme, 'lutino');
  });

  testWidgets('a aparência gravada vale ao abrir', (tester) async {
    final (core, vault) = await withProfile();
    core.store!.savedAppearance = const Appearance(
      theme: 'old-days',
      mode: AppearanceMode.dark,
    );
    await pumpChirp(tester, core: core, vault: vault);
    final theme = Theme.of(tester.element(find.text(l10n.appName).first));
    expect(theme.brightness, Brightness.dark);
    expect(theme.visualDensity, VisualDensity.compact);
  });

  for (final spec in chirpThemes) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${spec.id} no ${brightness.name}: contraste na lista e na conversa',
        (tester) async {
          final (core, vault) = await withProfile();
          core.store!
            ..savedAppearance = Appearance(
              theme: spec.id,
              mode: brightness == Brightness.dark
                  ? AppearanceMode.dark
                  : AppearanceMode.light,
            )
            ..someoneJoined('Canela');
          final store = core.store!;
          store.incoming(1, 'Oi, tudo bem?');
          await store.sendText(1, 'Tudo, e você?');
          final handle = tester.ensureSemantics();
          await pumpChirp(tester, core: core, vault: vault);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await tester.tap(find.text('Canela'));
          await tester.pumpAndSettle();
          expect(find.text('Oi, tudo bem?'), findsOneWidget);
          expect(find.text('Tudo, e você?'), findsOneWidget);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        },
      );
    }
  }

  for (final (w, h) in [(240.0, 160.0), (320.0, 568.0)]) {
    testWidgets('a aparência cabe em ${w.toInt()}×${h.toInt()}', (
      tester,
    ) async {
      setWindow(tester, w, h);
      final handle = tester.ensureSemantics();
      await openProfile(tester);
      await showAppearance(tester);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}

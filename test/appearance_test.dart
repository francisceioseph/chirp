// A aparência da fase 4: os temas por semente, o claro e o escuro, gravados no banco
// e de volta ao padrão quando o banco é apagado.
import 'dart:ui' show AccessibilityFeatures;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/application/appearance_controller.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:psito_chirp/src/ui/molecules/theme_swatch.dart';
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
      ChirpStyle.of(tester.element(find.text(l10n.themeLabel))).bubbleRadius,
      chirpThemeById('lutino').style.bubbleRadius,
    );

    await tester.tap(find.bySemanticsLabel(l10n.themeSkylight));
    await tester.pumpAndSettle();
    expect(store.savedAppearance.theme, 'skylight');
    expect(
      ChirpStyle.of(tester.element(find.text(l10n.themeLabel))).bubbleRadius,
      chirpThemeById('skylight').style.bubbleRadius,
    );

    await tester.ensureVisible(find.text(l10n.modeDark));
    await tester.pumpAndSettle();
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
    final theme = Theme.of(
      tester.element(find.byTooltip(l10n.profileTitle).first),
    );
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

  group('cor do sistema', () {
    const accent = Color(0xFF7B1FA2);

    testWidgets('aparece primeiro, e escolher usa a cor de destaque', (
      tester,
    ) async {
      final (core, vault) = await withProfile();
      await pumpChirp(tester, core: core, vault: vault, accent: accent);
      await tester.tap(find.byTooltip(l10n.profileTitle));
      await tester.pumpAndSettle();
      await showAppearance(tester);
      final swatches = find.byType(ThemeSwatch);
      expect(tester.widget<ThemeSwatch>(swatches.first).spec.id, 'system');

      await tester.tap(find.bySemanticsLabel(l10n.themeSystem));
      await tester.pumpAndSettle();
      expect(core.store!.savedAppearance.theme, 'system');
      expect(
        current(tester).colorScheme.primary,
        chirpScheme(systemTheme(accent), Brightness.light).primary,
      );
    });

    testWidgets('sem a cor do sistema, não aparece e vira o padrão', (
      tester,
    ) async {
      final (core, vault) = await withProfile();
      core.store!.savedAppearance = const Appearance(theme: 'system');
      await pumpChirp(tester, core: core, vault: vault);
      await tester.tap(find.byTooltip(l10n.profileTitle));
      await tester.pumpAndSettle();
      await showAppearance(tester);
      expect(find.bySemanticsLabel(l10n.themeSystem), findsNothing);
      expect(
        current(tester).colorScheme.primary,
        chirpScheme(chirpThemes.first, Brightness.light).primary,
      );
    });
  });

  group('efeito vidro', () {
    Future<FakeStore> withGlass(WidgetTester tester) async {
      final (core, vault) = await withProfile();
      final store = core.store!
        ..savedAppearance = const Appearance(glass: true)
        ..someoneJoined('Canela');
      store.incoming(1, 'Oi, tudo bem?');
      await pumpChirp(tester, core: core, vault: vault);
      return store;
    }

    Scaffold scaffoldOf(WidgetTester tester, String text) => tester.widget(
      find.ancestor(of: find.text(text), matching: find.byType(Scaffold)).first,
    );

    testWidgets('a chave grava o vidro', (tester) async {
      final store = await openProfile(tester);
      await tester.scrollUntilVisible(
        find.text(l10n.glassEffect),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(l10n.glassEffect));
      await tester.pumpAndSettle();
      expect(store.savedAppearance.glass, isTrue);
    });

    testWidgets('a lista e a conversa passam por baixo da barra borrada', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await withGlass(tester);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(scaffoldOf(tester, 'Canela').extendBodyBehindAppBar, isTrue);
      // A primeira conversa começa abaixo da barra, não atrás dela.
      final bar = tester.getBottomLeft(find.byType(AppBar));
      expect(tester.getTopLeft(find.text('Canela')).dy, greaterThan(bar.dy));

      await tester.tap(find.text('Canela'));
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('com menos animação pedida, o vidro some', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const _Features(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await withGlass(tester);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(scaffoldOf(tester, 'Canela').extendBodyBehindAppBar, isFalse);
    });

    for (final (w, h) in [(240.0, 160.0), (320.0, 568.0)]) {
      testWidgets('com vidro, cabe em ${w.toInt()}×${h.toInt()}', (
        tester,
      ) async {
        setWindow(tester, w, h);
        await withGlass(tester);
        await tester.tap(find.text('Canela'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

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

class _Features implements AccessibilityFeatures {
  const _Features({this.disableAnimations = false});

  @override
  final bool disableAnimations;

  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}

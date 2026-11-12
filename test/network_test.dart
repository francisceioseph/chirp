// A rede da fase 5 na tela: a internet e os retransmissores no perfil, com o que
// cada um revela, e o porquê de um contato não ser alcançado, na conversa.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> profile(WidgetTester tester) async {
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    return core.store!;
  }

  Future<void> show(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapShown(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a internet começa desligada, e ligar mostra os retransmissores',
    (tester) async {
      final store = await profile(tester);
      await show(tester, find.text(l10n.internetHelp));
      expect(find.text(l10n.networkLocalAlways), findsOneWidget);
      expect(find.text(l10n.relaysTitle), findsNothing);

      await tapShown(tester, find.text(l10n.internetToggle));
      expect(store.network.internet, isTrue);
      expect(store.networkRestarts, 1);
      await show(tester, find.text(l10n.relayStatusNone));
      expect(find.text(l10n.relaysHelp), findsOneWidget);
    },
  );

  testWidgets('um retransmissor estranho é recusado; um bom entra e sai', (
    tester,
  ) async {
    final store = await profile(tester);
    store.network = const NetworkSettings(internet: true);
    // Reabre o perfil, que lê os ajustes ao abrir.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextField, l10n.relayAddress);
    await show(tester, field);

    await tester.enterText(field, 'ftp://relay');
    await tapShown(tester, find.text(l10n.relayAdd));
    expect(find.text(l10n.relayInvalid), findsOneWidget);
    expect(store.network.relays, isEmpty);

    await tester.enterText(field, 'https://relay.example.org');
    await tapShown(tester, find.text(l10n.relayAdd));
    expect(store.network.relays, ['https://relay.example.org']);
    await show(tester, find.text(l10n.relayStatusWaiting));

    store.relayConnected = true;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text(l10n.relayStatusConnected), findsOneWidget);

    await tapShown(
      tester,
      find.byTooltip('${l10n.relayRemove}: https://relay.example.org'),
    );
    expect(store.network.relays, isEmpty);
  });

  group('o porquê na conversa', () {
    Future<FakeStore> unreachable(
      WidgetTester tester,
      NetworkSettings network,
    ) async {
      final (core, vault) = await withProfile();
      final store = core.store!
        ..network = network
        ..someoneJoined('Canela');
      await pumpChirp(tester, core: core, vault: vault);
      await tester.tap(find.text('Canela'));
      await tester.pumpAndSettle();
      store.reached(1, ContactReach.unreachable);
      await tester.pumpAndSettle();
      // Sem nada meu na fila, nada de aviso.
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      await tester.enterText(find.byType(TextField), 'oi');
      await tester.pump();
      await tester.tap(find.byTooltip(l10n.send));
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('só a rede local: diz para ligar a internet', (tester) async {
      final store = await unreachable(tester, const NetworkSettings());
      expect(find.text(l10n.unreachableLocalOnly), findsOneWidget);
      // Alcançado de novo, o aviso some.
      store.reached(1, ContactReach.lan);
      await tester.pumpAndSettle();
      expect(find.text(l10n.unreachableLocalOnly), findsNothing);
    });

    testWidgets('internet sem retransmissor: diz por que o direto falha', (
      tester,
    ) async {
      await unreachable(tester, const NetworkSettings(internet: true));
      expect(find.text(l10n.unreachableNoRelay), findsOneWidget);
    });

    testWidgets('com retransmissor: o contato parece desligado', (
      tester,
    ) async {
      await unreachable(
        tester,
        const NetworkSettings(
          internet: true,
          relays: ['https://relay.example.org'],
        ),
      );
      expect(find.text(l10n.unreachableOffline), findsOneWidget);
    });
  });

  testWidgets('o contato diz por onde foi alcançado', (tester) async {
    final (core, vault) = await withProfile();
    final store = core.store!..someoneJoined('Canela');
    store.reached(1, ContactReach.relay);
    await pumpChirp(tester, core: core, vault: vault);
    await tester.tap(find.text('Canela'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('${l10n.contactDetails}: Canela'));
    await tester.pumpAndSettle();
    await show(tester, find.text(l10n.reachRelay));
    expect(find.text(l10n.reachTitle), findsOneWidget);
  });

  for (final (w, h) in [(240.0, 160.0), (320.0, 568.0)]) {
    testWidgets('a rede e o aviso cabem em ${w.toInt()}×${h.toInt()}', (
      tester,
    ) async {
      setWindow(tester, w, h);
      final handle = tester.ensureSemantics();
      final (core, vault) = await withProfile();
      final store = core.store!
        ..network = const NetworkSettings(
          internet: true,
          relays: ['https://relay.example.org'],
        )
        ..someoneJoined('Canela');
      store.reached(1, ContactReach.unreachable);
      await store.sendText(1, 'oi');
      await pumpChirp(tester, core: core, vault: vault);
      await tester.tap(find.byTooltip(l10n.profileTitle));
      await tester.pumpAndSettle();
      await show(tester, find.text(l10n.relayAdd));
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Canela'));
      await tester.pumpAndSettle();
      // Em 240×160 o aviso sai da conversa (fica nos detalhes do contato).
      expect(
        find.text(l10n.unreachableOffline),
        findsNWidgets(h < 220 ? 0 : 1),
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}

// As notificações da fase 6: avisa o que chega com a conversa fora de vista, no modo
// escolhido (o nome por padrão), abre a conversa pelo clique e tira o aviso ao ler.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<(FakeStore, FakeNotifier)> ready(
    WidgetTester tester, {
    NotificationMode mode = NotificationMode.sender,
  }) async {
    final (core, vault) = await withProfile();
    final store = core.store!
      ..someoneJoined('Canela')
      ..someoneJoined('Pérola')
      ..notifications = mode;
    final notifier = FakeNotifier();
    await pumpChirp(tester, core: core, vault: vault, notifier: notifier);
    return (store, notifier);
  }

  Future<void> arrive(WidgetTester tester, FakeStore store, int contact) async {
    store.incoming(contact, 'Te espero na varanda');
    await tester.pumpAndSettle();
  }

  testWidgets('por padrão, o nome sem o texto', (tester) async {
    final (store, notifier) = await ready(tester);
    expect(notifier.inits, 1);
    await arrive(tester, store, 1);
    expect(notifier.shown[1], (
      title: 'Canela',
      body: l10n.notificationNewMessage,
    ));
  });

  testWidgets('com o texto, sem conteúdo, ou desligadas', (tester) async {
    final (store, notifier) = await ready(tester, mode: NotificationMode.full);
    await arrive(tester, store, 1);
    expect(notifier.shown[1], (title: 'Canela', body: 'Te espero na varanda'));

    store.notifications = NotificationMode.hidden;
    await arrive(tester, store, 2);
    expect(notifier.shown[2], (
      title: l10n.appName,
      body: l10n.notificationNewMessage,
    ));

    store.notifications = NotificationMode.off;
    notifier.shown.clear();
    await arrive(tester, store, 1);
    expect(notifier.shown, isEmpty);
  });

  testWidgets('desligadas, nem pede a permissão', (tester) async {
    final (_, notifier) = await ready(tester, mode: NotificationMode.off);
    expect(notifier.inits, 0);
  });

  testWidgets('o que já estava no banco ao abrir não avisa', (tester) async {
    final (core, vault) = await withProfile();
    core.store!
      ..someoneJoined('Canela')
      ..incoming(1, 'De ontem');
    final notifier = FakeNotifier();
    await pumpChirp(tester, core: core, vault: vault, notifier: notifier);
    expect(find.text('De ontem'), findsOneWidget);
    expect(notifier.shown, isEmpty);
  });

  testWidgets('a conversa aberta não avisa; fora de foco, avisa', (
    tester,
  ) async {
    final (store, notifier) = await ready(tester);
    await tester.tap(find.text('Canela'));
    await tester.pumpAndSettle();
    await arrive(tester, store, 1);
    expect(notifier.shown, isEmpty);

    // Outra conversa avisa mesmo com esta aberta.
    await arrive(tester, store, 2);
    expect(notifier.shown.keys, [2]);

    // Sem foco, a conversa aberta avisa e não marca como lida.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await arrive(tester, store, 1);
    expect(notifier.shown.keys, containsAll([1, 2]));
    expect(store.sent.where((m) => m.contactId == 1 && m.unread), hasLength(1));

    // De volta, conta como lida, e o aviso sai.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(notifier.shown.keys, [2]);
  });

  testWidgets('o clique abre a conversa, e ler tira o aviso', (tester) async {
    final (store, notifier) = await ready(tester);
    await arrive(tester, store, 2);
    expect(notifier.shown.keys, [2]);

    notifier.tap(2);
    await tester.pumpAndSettle();
    expect(find.text('Te espero na varanda'), findsOneWidget);
    expect(find.text(l10n.messageHint), findsOneWidget);
    expect(notifier.shown, isEmpty);
  });

  testWidgets('o modo se escolhe no perfil, e ligar pede a permissão', (
    tester,
  ) async {
    final (store, notifier) = await ready(tester, mode: NotificationMode.off);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    final hidden = find.text(l10n.notifyHidden);
    await tester.scrollUntilVisible(
      hidden,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.notifyHiddenHelp), findsOneWidget);
    await tester.tap(hidden);
    await tester.pumpAndSettle();
    expect(store.notifications, NotificationMode.hidden);
    expect(notifier.inits, 1);

    await tester.ensureVisible(find.text(l10n.notifyOff));
    await tester.tap(find.text(l10n.notifyOff));
    await tester.pumpAndSettle();
    expect(store.notifications, NotificationMode.off);
    expect(notifier.inits, 1);
  });

  for (final size in const [Size(240, 160), Size(320, 568)]) {
    testWidgets(
      'o cartão cabe em ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        setWindow(tester, size.width, size.height);
        await ready(tester);
        await tester.tap(find.byTooltip(l10n.profileTitle));
        await tester.pumpAndSettle();
        final full = find.text(l10n.notifyFull);
        await tester.scrollUntilVisible(
          full,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSemantics(
            find.byType(RadioListTile<NotificationMode>).first,
          ),
          matchesSemantics(
            label: '${l10n.notifyFull}\n${l10n.notifyFullHelp}',
            hasCheckedState: true,
            isInMutuallyExclusiveGroup: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
            hasSelectedState: true,
          ),
        );
      },
    );
  }
}

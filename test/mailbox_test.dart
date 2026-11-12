// A caixa postal da fase 7 na tela: ligar pelo código, as recusas, o estado, desligar
// perguntando antes, e a mensagem que espera na caixa do contato.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:psito_chirp/src/ui/atoms/message_status_icon.dart';

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

  Future<void> tapShown(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('o código errado é recusado; o certo liga, e desligar pergunta', (
    tester,
  ) async {
    final store = await profile(tester);
    final field = find.widgetWithText(TextField, l10n.mailboxCode);
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.mailboxHelp), findsOneWidget);

    await tester.enterText(field, 'chirp://invite#AAAA');
    await tapShown(tester, find.text(l10n.mailboxPair));
    expect(find.text(l10n.mailboxInvalid), findsOneWidget);

    await tester.enterText(field, 'chirp://mailbox#BB');
    await tapShown(tester, find.text(l10n.mailboxPair));
    expect(find.text(l10n.mailboxRefused), findsOneWidget);
    expect(store.mailboxState, isNull);

    await tester.enterText(field, ' ${FakeStore.mailboxLink}\n');
    await tapShown(tester, find.text(l10n.mailboxPair));
    expect(store.mailboxState, isNotNull);
    expect(find.text(l10n.mailboxPaired), findsOneWidget);
    expect(find.text(l10n.mailboxStatusWaiting), findsOneWidget);

    // Cancelar não desliga; confirmar desliga.
    await tapShown(tester, find.text(l10n.mailboxUnpair));
    expect(find.text(l10n.mailboxUnpairBody), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(store.mailboxState, isNotNull);

    await tapShown(tester, find.text(l10n.mailboxUnpair));
    await tester.tap(find.widgetWithText(FilledButton, l10n.mailboxUnpair));
    await tester.pumpAndSettle();
    expect(store.mailboxState, isNull);
    expect(find.text(l10n.mailboxCode), findsOneWidget);
  });

  testWidgets('a caixa que não respondeu aparece como problema', (
    tester,
  ) async {
    final store = await profile(tester);
    store.mailboxState = MailboxState(
      pairedAt: DateTime(2026, 11, 12, 9),
      lastFetch: DateTime(2026, 11, 12, 10),
      reachable: false,
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    final status = find.text(l10n.mailboxStatusUnreachable);
    await tester.scrollUntilVisible(
      status,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(status, findsOneWidget);
  });

  testWidgets('a mensagem na caixa do contato tem o próprio ícone e nome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: [
          ChirpLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: ChirpLocalizations.supportedLocales,
        home: const Scaffold(
          body: Row(
            children: [
              MessageStatusIcon(status: MessageStatus.pending, inMailbox: true),
              MessageStatusIcon(status: MessageStatus.pending),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.markunread_mailbox_outlined), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.statusInMailbox), findsOneWidget);
    expect(
      statusLabel(l10n, MessageStatus.delivered, inMailbox: true),
      l10n.statusDelivered,
    );
  });

  for (final size in const [Size(240, 160), Size(320, 568)]) {
    testWidgets(
      'o cartão cabe em ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        setWindow(tester, size.width, size.height);
        final store = await profile(tester);
        final pair = find.text(l10n.mailboxPair);
        await tester.scrollUntilVisible(
          pair,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        store.mailboxState = MailboxState(
          pairedAt: DateTime(2026, 11, 12, 9),
          reachable: false,
        );
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
        final unpair = find.text(l10n.mailboxUnpair);
        await tester.scrollUntilVisible(
          unpair,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}

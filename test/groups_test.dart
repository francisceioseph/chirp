// Os grupos (fase 9) na tela: criar, quem escreveu em cada bolha, a página do grupo
// (o admin muda, os outros só veem), sair, e tudo cabendo nas janelas pequenas.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> start(WidgetTester tester) async {
    final (core, vault) = await withProfile();
    final store = core.store!
      ..someoneJoined('Canela')
      ..someoneJoined('Pérola');
    await pumpChirp(tester, core: core, vault: vault);
    return store;
  }

  Future<void> details(WidgetTester tester, String name) async {
    await tester.tap(find.bySemanticsLabel('${l10n.contactDetails}: $name'));
    await tester.pumpAndSettle();
  }

  testWidgets('cria um grupo com dois contatos e escreve nele', (tester) async {
    final store = await start(tester);
    await tester.tap(find.byTooltip(l10n.groupNew));
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, l10n.groupCreate);
    // Sem nome e sem ninguém, o botão não acende.
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextField, l10n.groupName),
      'Calopsitas',
    );
    await tester.tap(find.text('Canela'));
    await tester.tap(find.text('Pérola'));
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();

    final group = store.groups.keys.single;
    expect(store.groups[group]!.members, [1, 2]);
    // A conversa do grupo abre: o nome, "Grupo", e sem chamar atenção nem anexo.
    expect(find.text('Calopsitas'), findsWidgets);
    expect(find.text(l10n.groupLabel), findsOneWidget);
    expect(find.byTooltip(l10n.nudge), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'oi, bando');
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.send));
    await tester.pumpAndSettle();
    expect(store.sent.last.contactId, group);
    expect(store.sent.last.text, 'oi, bando');
  });

  testWidgets('cada bolha do grupo diz quem escreveu, e não há reações', (
    tester,
  ) async {
    final store = await start(tester);
    final group = store.joinedGroup('Bando', [1, 2]);
    store.groupMessage(group, 1, 'piu');
    store.groupMessage(group, 2, 'piu piu');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bando'));
    await tester.pumpAndSettle();
    expect(find.text('Canela'), findsWidgets);
    expect(find.text('Pérola'), findsWidgets);
    await tester.longPress(find.text('piu piu'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reply), findsOneWidget);
    expect(find.byTooltip(l10n.reaction1), findsNothing);
  });

  testWidgets('o admin renomeia e tira; sair pergunta e fecha a conversa', (
    tester,
  ) async {
    final store = await start(tester);
    await tester.tap(find.byTooltip(l10n.groupNew));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, l10n.groupName),
      'Calopsitas',
    );
    await tester.tap(find.text('Canela'));
    await tester.tap(find.text('Pérola'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.groupCreate));
    await tester.pumpAndSettle();
    final group = store.groups.keys.single;
    await details(tester, 'Calopsitas');
    expect(find.text(l10n.groupMemberCount(2)), findsOneWidget);

    await tester.tap(find.text(l10n.groupRename));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Bando');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(find.text('Bando'), findsWidgets);

    await tester.tap(find.byTooltip('${l10n.groupRemove}: Pérola'));
    await tester.pumpAndSettle();
    expect(store.groups[group]!.members, [1]);
    expect(find.text(l10n.groupMemberCount(1)), findsOneWidget);

    final leave = find.text(l10n.groupLeave);
    await tester.ensureVisible(leave);
    await tester.pumpAndSettle();
    await tester.tap(leave);
    await tester.pumpAndSettle();
    expect(find.text(l10n.groupLeaveTitle('Bando')), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, l10n.groupLeave));
    await tester.pumpAndSettle();
    expect(store.groups[group]!.active, isFalse);
    expect(find.text(l10n.groupClosed), findsWidgets);
  });

  testWidgets('quem não é admin só vê, e o membro que não é contato é avisado', (
    tester,
  ) async {
    final store = await start(tester);
    store.joinedGroup('Bando', [1], strangers: ['Ana']);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bando'));
    await tester.pumpAndSettle();
    await details(tester, 'Bando');
    expect(find.text(l10n.groupNotConnected, findRichText: true), findsNothing);
    expect(find.textContaining(l10n.groupNotConnected), findsOneWidget);
    expect(find.text(l10n.groupAddMembers), findsNothing);
    expect(find.text(l10n.groupRename), findsNothing);
    expect(find.byTooltip('${l10n.groupRemove}: Canela'), findsNothing);
  });

  for (final (w, h) in [(240.0, 160.0), (320.0, 568.0)]) {
    testWidgets('o grupo cabe em ${w.toInt()}×${h.toInt()}', (tester) async {
      setWindow(tester, w, h);
      final handle = tester.ensureSemantics();
      final store = await start(tester);
      final group = store.joinedGroup('Bando', [1, 2], strangers: ['Ana']);
      store.groupMessage(group, 1, 'piu');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.groupNew));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bando'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await details(tester, 'Bando');
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}

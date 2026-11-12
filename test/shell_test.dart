// A casca pela largura (fase 4): estreita, a conversa abre por cima; a partir de
// 840 px, ao lado da lista; a partir de 1200 px, o contato num terceiro painel. E os
// atalhos da tela principal.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/ui/pages/add_contact_page.dart';
import 'package:psito_chirp/src/ui/pages/search_page.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> ready(WidgetTester tester, double width) async {
    setWindow(tester, width, 800);
    final (core, vault) = await withProfile();
    final store = core.store!
      ..someoneJoined('Canela')
      ..someoneJoined('Pérola');
    store
      ..incoming(1, 'Oi da Canela')
      ..incoming(2, 'Oi da Pérola');
    await pumpChirp(tester, core: core, vault: vault);
    return store;
  }

  Finder details(String name) =>
      find.bySemanticsLabel('${l10n.contactDetails}: $name');

  Future<void> keys(WidgetTester tester, List<LogicalKeyboardKey> combo) async {
    for (final key in combo) {
      await tester.sendKeyDownEvent(key);
    }
    for (final key in combo.reversed) {
      await tester.sendKeyUpEvent(key);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('estreita, a conversa abre por cima da lista', (tester) async {
    await ready(tester, 800);
    await tester.tap(find.text('Canela'));
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.profileTitle), findsNothing);
    expect(find.byTooltip('Voltar'), findsOneWidget);
  });

  testWidgets('com duas colunas, a conversa abre ao lado', (tester) async {
    await ready(tester, 1000);
    expect(find.text(l10n.conversationPick), findsOneWidget);
    await tester.tap(find.text('Canela'));
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.profileTitle), findsOneWidget);
    expect(find.text(l10n.messageHint), findsOneWidget);
    expect(find.text(l10n.conversationPick), findsNothing);
    expect(
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Canela').first,
              matching: find.byType(ListTile),
            ),
          )
          .selected,
      isTrue,
    );

    // Duas colunas não têm o painel: os detalhes abrem por cima.
    await tester.tap(details('Canela'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.safetyNumberTitle), findsOneWidget);
    expect(find.byTooltip(l10n.profileTitle), findsNothing);
  });

  testWidgets('com três colunas, os detalhes ficam ao lado e o Esc fecha', (
    tester,
  ) async {
    await ready(tester, 1300);
    await tester.tap(find.text('Canela'));
    await tester.pumpAndSettle();
    await tester.tap(details('Canela'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.safetyNumberTitle), findsOneWidget);
    expect(find.text(l10n.messageHint), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.close));
    await tester.pumpAndSettle();
    expect(find.text(l10n.safetyNumberTitle), findsNothing);

    await tester.tap(details('Canela'));
    await tester.pumpAndSettle();
    // Trocar de conversa fecha o painel do contato de antes.
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.safetyNumberTitle), findsNothing);

    await tester.tap(details('Pérola'));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await keys(tester, [LogicalKeyboardKey.escape]);
    expect(find.text(l10n.safetyNumberTitle), findsNothing);
  });

  testWidgets('Alt+setas trocam de conversa', (tester) async {
    await ready(tester, 1000);
    // A mais recente (Pérola) vem primeiro.
    await keys(tester, [
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.arrowDown,
    ]);
    expect(details('Pérola'), findsOneWidget);
    await keys(tester, [
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.arrowDown,
    ]);
    expect(details('Canela'), findsOneWidget);
    await keys(tester, [
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.arrowUp,
    ]);
    expect(details('Pérola'), findsOneWidget);
  });

  testWidgets('Ctrl+N adiciona e Ctrl+K busca', (tester) async {
    await ready(tester, 800);
    await keys(tester, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyN,
    ]);
    expect(find.byType(AddContactPage), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await keys(tester, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyK,
    ]);
    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('com duas colunas, um resultado da busca abre ao lado', (
    tester,
  ) async {
    await ready(tester, 1000);
    await tester.tap(find.byTooltip(l10n.searchMessages));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Canela');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oi da Canela').last);
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsNothing);
    expect(details('Canela'), findsOneWidget);
    expect(find.byTooltip(l10n.profileTitle), findsOneWidget);
  });

  for (final width in [1000.0, 1300.0]) {
    testWidgets('${width.toInt()} px passa no contraste e tem rótulos', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await ready(tester, width);
      await tester.tap(find.text('Canela'));
      await tester.pumpAndSettle();
      if (width > 1200) {
        await tester.tap(details('Canela'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}

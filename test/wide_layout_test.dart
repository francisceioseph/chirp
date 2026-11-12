// As telas de uma coluna em janela larga (840 px ou mais): o perfil vira os ajustes
// de um app de computador, com as seções à esquerda, e o convite mostra o código e o
// colar lado a lado. Abaixo disso, ficam como no celular (os outros testes, em 800 px).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<void> ready(WidgetTester tester) async {
    setWindow(tester, 1300, 800);
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault);
  }

  testWidgets('o perfil mostra as seções à esquerda e uma de cada vez', (
    tester,
  ) async {
    await ready(tester);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    final sections = find.byType(ListTile);
    for (final label in [
      l10n.chatSettingsTitle,
      l10n.notificationsTitle,
      l10n.downloadsTitle,
      l10n.networkTitle,
      l10n.appearanceTitle,
    ]) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
    expect(sections, findsAtLeastNWidgets(6));
    // Começa no perfil: nada das outras seções.
    expect(find.text(l10n.downloadsHelp), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, l10n.downloadsTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.downloadsHelp), findsOneWidget);
    expect(find.text(l10n.notificationsHelp), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, l10n.notificationsTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.notificationsHelp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o convite mostra o código e o colar juntos, sem abas', (
    tester,
  ) async {
    await ready(tester);
    await tester.tap(find.text(l10n.addContact));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
    expect(find.text(l10n.inviteTabShow), findsOneWidget);
    expect(find.text(l10n.inviteTabPaste), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'chirp://invite#Arlequim');
    await tester.pump();
    await tester.tap(find.text(l10n.pasteAdd));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactAdded('Arlequim')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('em 839 px, o convite volta às abas', (tester) async {
    setWindow(tester, 839, 700);
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault);
    await tester.tap(find.text(l10n.addContact));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
  });
}

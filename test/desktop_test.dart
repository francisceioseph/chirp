// O segundo plano no desktop (fase 6): a bandeja com os textos do idioma, fechar sem
// sair, abrir ao entrar no computador (já escondido) e a notificação que traz a
// janela de volta. No celular, nada disso aparece.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> profile(WidgetTester tester, FakeDesktop desktop) async {
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault, desktop: desktop);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    final card = find.text(l10n.keepRunning);
    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    return core.store!;
  }

  testWidgets('a bandeja liga ao abrir, com os textos do idioma', (
    tester,
  ) async {
    final desktop = FakeDesktop();
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault, desktop: desktop);
    expect(desktop.tray, (
      keepRunning: true,
      tooltip: l10n.appName,
      open: l10n.trayOpen(l10n.appName),
      quit: l10n.trayQuit,
    ));
  });

  testWidgets('desligar fecha de verdade, e religar volta a bandeja', (
    tester,
  ) async {
    final desktop = FakeDesktop();
    final store = await profile(tester, desktop);
    await tester.tap(find.text(l10n.keepRunning));
    await tester.pumpAndSettle();
    expect(store.running, isFalse);
    expect(desktop.tray?.keepRunning, isFalse);

    await tester.tap(find.text(l10n.keepRunning));
    await tester.pumpAndSettle();
    expect(store.running, isTrue);
    expect(desktop.tray?.keepRunning, isTrue);
  });

  testWidgets('abrir ao entrar no computador', (tester) async {
    final desktop = FakeDesktop();
    await profile(tester, desktop);
    final login = find.text(l10n.startAtLogin);
    await tester.ensureVisible(login);
    await tester.pumpAndSettle();
    expect(find.text(l10n.startAtLoginHelp), findsOneWidget);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(desktop.startsAtLogin, isTrue);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(desktop.startsAtLogin, isFalse);
  });

  testWidgets('sem o sistema deixar, a opção de abrir ao entrar some', (
    tester,
  ) async {
    await profile(tester, FakeDesktop(canStartAtLogin: false));
    expect(find.text(l10n.startAtLogin), findsNothing);
  });

  testWidgets('no celular, o cartão não aparece', (tester) async {
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(l10n.networkTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n.backgroundTitle), findsNothing);
  });

  testWidgets('aberto com o computador, fica escondido na bandeja', (
    tester,
  ) async {
    final desktop = FakeDesktop();
    final (core, vault) = await withProfile();
    await pumpChirp(
      tester,
      core: core,
      vault: vault,
      desktop: desktop,
      startHidden: true,
    );
    expect(desktop.visible, isFalse);
    expect(desktop.broughtToFront, 0);
  });

  testWidgets('escondido, aparece se a abertura precisar de quem usa', (
    tester,
  ) async {
    final desktop = FakeDesktop();
    await pumpChirp(tester, desktop: desktop, startHidden: true);
    expect(desktop.visible, isTrue);
    expect(desktop.broughtToFront, 1);
  });

  testWidgets('escondido sem a bandeja, a janela volta', (tester) async {
    final desktop = FakeDesktop();
    final (core, vault) = await withProfile();
    core.store!.running = false;
    await pumpChirp(
      tester,
      core: core,
      vault: vault,
      desktop: desktop,
      startHidden: true,
    );
    expect(desktop.visible, isTrue);
  });

  testWidgets('o clique na notificação traz a janela', (tester) async {
    final desktop = FakeDesktop();
    final notifier = FakeNotifier();
    final (core, vault) = await withProfile();
    final store = core.store!..someoneJoined('Canela');
    await pumpChirp(
      tester,
      core: core,
      vault: vault,
      desktop: desktop,
      notifier: notifier,
    );
    store.incoming(1, 'Oi');
    await tester.pumpAndSettle();
    notifier.tap(1);
    await tester.pumpAndSettle();
    expect(desktop.broughtToFront, 1);
  });

  for (final size in const [Size(240, 160), Size(320, 568)]) {
    testWidgets(
      'o cartão cabe em ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        setWindow(tester, size.width, size.height);
        await profile(tester, FakeDesktop());
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel(RegExp(l10n.keepRunning)), findsOneWidget);
      },
    );
  }
}

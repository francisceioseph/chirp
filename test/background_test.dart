// O segundo plano (fase 6). No desktop: a bandeja com os textos do idioma, fechar sem
// sair, abrir ao entrar no computador (já escondido) e a notificação que traz a
// janela de volta. No Android: o serviço com a notificação fixa e o pedido para ficar
// fora da economia de bateria. No iOS, nada disso aparece.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> profile(
    WidgetTester tester,
    FakeBackground background,
  ) async {
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault, background: background);
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

  testWidgets('liga ao abrir, com os textos do idioma', (tester) async {
    final background = FakeBackground();
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault, background: background);
    expect(background.running, (
      keepRunning: true,
      texts: (
        name: l10n.appName,
        open: l10n.trayOpen(l10n.appName),
        quit: l10n.trayQuit,
        receiving: l10n.receivingNow,
        channel: l10n.backgroundTitle,
      ),
    ));
  });

  testWidgets('desligar fecha de verdade, e religar volta', (tester) async {
    final background = FakeBackground();
    final store = await profile(tester, background);
    expect(find.text(l10n.keepRunningHelp), findsOneWidget);
    await tester.tap(find.text(l10n.keepRunning));
    await tester.pumpAndSettle();
    expect(store.running, isFalse);
    expect(background.running?.keepRunning, isFalse);

    await tester.tap(find.text(l10n.keepRunning));
    await tester.pumpAndSettle();
    expect(store.running, isTrue);
    expect(background.running?.keepRunning, isTrue);
  });

  testWidgets('abrir ao entrar no computador', (tester) async {
    final background = FakeBackground();
    await profile(tester, background);
    final login = find.text(l10n.startAtLogin);
    await tester.ensureVisible(login);
    await tester.pumpAndSettle();
    expect(find.text(l10n.startAtLoginHelp), findsOneWidget);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(background.startsAtLogin, isTrue);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(background.startsAtLogin, isFalse);
  });

  testWidgets('sem o sistema deixar, a opção de abrir ao entrar some', (
    tester,
  ) async {
    await profile(tester, FakeBackground(canStartAtLogin: false));
    expect(find.text(l10n.startAtLogin), findsNothing);
  });

  testWidgets('no iOS, o cartão não aparece', (tester) async {
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

  testWidgets('no Android, a notificação fixa e sem abrir ao entrar', (
    tester,
  ) async {
    await profile(tester, FakeBackground(tray: false));
    expect(find.text(l10n.keepRunningHelpMobile), findsOneWidget);
    expect(find.text(l10n.keepRunningHelp), findsNothing);
    expect(find.text(l10n.startAtLogin), findsNothing);
    expect(find.text(l10n.batteryTitle), findsNothing);
  });

  testWidgets('no Android, pede para sair da economia de bateria', (
    tester,
  ) async {
    final background = FakeBackground(tray: false, restricted: true);
    await profile(tester, background);
    final allow = find.text(l10n.batteryAllow);
    await tester.ensureVisible(allow);
    await tester.pumpAndSettle();
    expect(find.text(l10n.batteryHelp), findsOneWidget);
    await tester.tap(allow);
    await tester.pumpAndSettle();
    expect(background.batteryAsks, 1);

    // De volta dos ajustes do sistema, liberado: o pedido some.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(l10n.batteryAllow), findsNothing);
  });

  testWidgets('com o segundo plano desligado, nem pede a bateria', (
    tester,
  ) async {
    final background = FakeBackground(tray: false, restricted: true);
    final (core, vault) = await withProfile();
    core.store!.running = false;
    await pumpChirp(tester, core: core, vault: vault, background: background);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(l10n.keepRunning),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n.batteryAllow), findsNothing);
  });

  testWidgets('aberto com o computador, fica escondido na bandeja', (
    tester,
  ) async {
    final background = FakeBackground();
    final (core, vault) = await withProfile();
    await pumpChirp(
      tester,
      core: core,
      vault: vault,
      background: background,
      startHidden: true,
    );
    expect(background.visible, isFalse);
    expect(background.broughtToFront, 0);
  });

  testWidgets('escondido, aparece se a abertura precisar de quem usa', (
    tester,
  ) async {
    final background = FakeBackground();
    await pumpChirp(tester, background: background, startHidden: true);
    expect(background.visible, isTrue);
    expect(background.broughtToFront, 1);
  });

  testWidgets('escondido sem a bandeja, a janela volta', (tester) async {
    final background = FakeBackground();
    final (core, vault) = await withProfile();
    core.store!.running = false;
    await pumpChirp(
      tester,
      core: core,
      vault: vault,
      background: background,
      startHidden: true,
    );
    expect(background.visible, isTrue);
  });

  testWidgets('o clique na notificação traz a janela', (tester) async {
    final background = FakeBackground();
    final notifier = FakeNotifier();
    final (core, vault) = await withProfile();
    final store = core.store!..someoneJoined('Canela');
    await pumpChirp(
      tester,
      core: core,
      vault: vault,
      background: background,
      notifier: notifier,
    );
    store.incoming(1, 'Oi');
    await tester.pumpAndSettle();
    notifier.tap(1);
    await tester.pumpAndSettle();
    expect(background.broughtToFront, 1);
  });

  for (final tray in [true, false]) {
    for (final size in const [Size(240, 160), Size(320, 568)]) {
      final where = tray ? 'desktop' : 'Android';
      testWidgets(
        'o cartão cabe em ${size.width.toInt()}×${size.height.toInt()} no $where',
        (tester) async {
          setWindow(tester, size.width, size.height);
          await profile(tester, FakeBackground(tray: tray, restricted: !tray));
          expect(tester.takeException(), isNull);
          expect(
            find.bySemanticsLabel(RegExp(l10n.keepRunning)),
            findsOneWidget,
          );
          if (!tray) {
            final allow = find.text(l10n.batteryAllow);
            await tester.ensureVisible(allow);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}

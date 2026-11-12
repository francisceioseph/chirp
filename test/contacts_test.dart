// Os contatos da fase 2, com o núcleo falso: adicionar por link, o convite em QR,
// alguém que lê o nosso código, o número de segurança e o "verificado".
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> ready(WidgetTester tester) async {
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault);
    return core.store!;
  }

  Future<void> openAdd(WidgetTester tester) async {
    await tester.tap(find.text(l10n.addContact));
    await tester.pumpAndSettle();
  }

  Future<void> openPaste(WidgetTester tester) async {
    await openAdd(tester);
    await tester.tap(find.text(l10n.inviteTabPaste));
    await tester.pumpAndSettle();
  }

  testWidgets('a rede liga e a lista começa vazia', (tester) async {
    final store = await ready(tester);
    expect(store.networkStarted, isTrue);
    expect(find.text(l10n.contactsEmptyTitle), findsOneWidget);
  });

  testWidgets('colar um link adiciona o contato não verificado', (
    tester,
  ) async {
    final store = await ready(tester);
    await openPaste(tester);
    await tester.enterText(find.byType(TextField), ' chirp://invite#Arlequim ');
    await tester.pump();
    await tester.tap(find.text(l10n.pasteAdd));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactAdded('Arlequim')), findsOneWidget);
    expect(find.text('Arlequim'), findsOneWidget);
    expect(find.text(l10n.contactUnverified), findsOneWidget);
    expect(store.people.single.verified, isFalse);
  });

  testWidgets('cada falha do convite tem a mensagem dela', (tester) async {
    await ready(tester);
    await openPaste(tester);
    for (final (link, message) in [
      ('https://example.org', l10n.inviteInvalid),
      ('chirp://invite#refused', l10n.inviteRefused),
      ('chirp://invite#away', l10n.inviteUnreachable),
    ]) {
      await tester.enterText(find.byType(TextField), link);
      await tester.pump();
      await tester.tap(find.text(l10n.pasteAdd));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget, reason: link);
    }
  });

  testWidgets('o meu código é um QR, e o link vai para a área de '
      'transferência', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final store = await ready(tester);
    await openAdd(tester);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(store.invites, ['chirp://invite#qr0']);
    await tester.tap(find.text(l10n.inviteCopyLink));
    await tester.pumpAndSettle();
    expect(store.invites.last, 'chirp://invite#link1');
    expect(copied, 'chirp://invite#link1');
    expect(find.text(l10n.inviteLinkCopied), findsOneWidget);
    // O aviso sai sozinho, e o botão fica livre.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.inviteNewCode));
    await tester.tap(find.text(l10n.inviteNewCode));
    await tester.pumpAndSettle();
    expect(store.invites.last, 'chirp://invite#qr2');
  });

  testWidgets('quando alguém lê o meu código, a tela fecha e avisa', (
    tester,
  ) async {
    final store = await ready(tester);
    await openAdd(tester);
    store.someoneJoined('Pérola', verified: false);
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text(l10n.contactAdded('Pérola')), findsOneWidget);
    expect(find.text('Pérola'), findsOneWidget);
    // Quem mostrou o QR não conferiu a chave de quem leu.
    expect(find.text(l10n.contactUnverified), findsOneWidget);
  });

  testWidgets('o contato mostra o número de segurança e marca verificado', (
    tester,
  ) async {
    final store = await ready(tester);
    store.someoneJoined('Canela', verified: false);
    await tester.pumpAndSettle();
    // Tocar abre a conversa; o título dela abre os detalhes.
    await tester.tap(find.text('Canela'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sayHi('Canela')), findsOneWidget);
    await tester.tap(find.text('Canela'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.safetyNumberTitle), findsOneWidget);
    expect(find.text(l10n.safetyNumberHelp('Canela')), findsOneWidget);
    final number = await store.safetyNumber(1);
    final lines = [
      for (var i = 0; i < 60; i += 20)
        [for (var j = i; j < i + 20; j += 5) number.substring(j, j + 5)]
            .join('  '),
    ].join('\n');
    expect(find.text(lines), findsOneWidget);
    await tester.tap(find.text(l10n.markVerified));
    await tester.pumpAndSettle();
    expect((await store.contacts()).single.verified, isTrue);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactVerified), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactVerified), findsOneWidget);
  });

  testWidgets('sem rede, a lista aparece com o aviso e sem o botão', (
    tester,
  ) async {
    final (core, vault) = await withProfile();
    core.store!.networkFailure = CoreFailure.unreachable;
    await pumpChirp(tester, core: core, vault: vault);
    expect(find.textContaining(l10n.networkUnavailable), findsOneWidget);
    expect(find.text(l10n.addContact), findsNothing);
    core.store!.networkFailure = null;
    await tester.tap(find.text(l10n.tryAgain));
    await tester.pumpAndSettle();
    expect(find.text(l10n.addContact), findsOneWidget);
  });

  // As telas novas na janela mínima e num celular pequeno, nos dois temas, com
  // contraste e rótulos.
  final screens = <String, Future<void> Function(WidgetTester, FakeStore)>{
    'lista': (tester, store) async {
      store.someoneJoined('Calopsita com um nome bem comprido mesmo');
      await tester.pumpAndSettle();
    },
    'meu código': (tester, store) => openAdd(tester),
    'colar convite': (tester, store) => openPaste(tester),
    'contato': (tester, store) async {
      store.someoneJoined('Canela');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Canela'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Canela'));
      await tester.pumpAndSettle();
    },
  };
  for (final MapEntry(key: name, value: open) in screens.entries) {
    for (final brightness in Brightness.values) {
      for (final (w, h) in [(240.0, 160.0), (320.0, 568.0)]) {
        testWidgets('$name cabe em ${w.toInt()}×${h.toInt()} no tema '
            '${brightness.name}', (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          setWindow(tester, w, h);
          final store = await ready(tester);
          await open(tester, store);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('$name passa no contraste e tem rótulos', (tester) async {
      final handle = tester.ensureSemantics();
      final store = await ready(tester);
      await open(tester, store);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}

// As telas da abertura, montadas no app com o núcleo e o cofre falsos.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/ui/atoms/identity_avatar.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  testWidgets('cria o perfil e mostra a chave', (tester) async {
    await pumpChirp(tester);
    expect(find.text(l10n.welcomeTitle), findsOneWidget);
    final create = find.widgetWithText(FilledButton, l10n.onboardingCreate);
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Lutino');
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactsEmptyTitle), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    expect(find.text('Lutino'), findsOneWidget);
    expect(find.text(l10n.profileKeyLabel), findsOneWidget);
    expect(
      find.text('12345  67890  13579\n24680  11223  34455'),
      findsOneWidget,
    );
    expect(find.text(l10n.coreVersion('9.9.9', 1)), findsOneWidget);
    expect(find.byType(IdentityAvatar), findsWidgets);
  });

  testWidgets('troca o nome pelo diálogo', (tester) async {
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.renameTooltip));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, ' ');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(find.text(l10n.nameInvalid), findsOneWidget);
    await tester.enterText(field, 'Arlequim');
    await tester.tap(find.text(l10n.save));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Arlequim'), findsOneWidget);
  });

  testWidgets('sem cofre, cria a senha conferindo as duas', (tester) async {
    final core = FakeCore();
    await pumpChirp(tester, core: core, vault: FakeVault(available: false));
    expect(find.text(l10n.passphraseCreateTitle), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'curta');
    await tester.tap(find.text(l10n.passphraseCreate));
    await tester.pump();
    expect(find.text(l10n.passphraseTooShort(8)), findsOneWidget);
    await tester.enterText(fields.at(0), 'calopsita lutino');
    await tester.enterText(fields.at(1), 'calopsita arlequim');
    await tester.tap(find.text(l10n.passphraseCreate));
    await tester.pump();
    expect(find.text(l10n.passphraseMismatch), findsOneWidget);
    await tester.enterText(fields.at(1), 'calopsita lutino');
    await tester.tap(find.text(l10n.passphraseCreate));
    await tester.pumpAndSettle();
    expect(find.text(l10n.welcomeTitle), findsOneWidget);
    expect(core.storedPassphrase, 'calopsita lutino');
  });

  testWidgets('a senha começa escondida e o botão mostra', (tester) async {
    await pumpChirp(tester, vault: FakeVault(available: false));
    bool obscured() =>
        tester.widget<TextField>(find.byType(TextField).first).obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip(l10n.passphraseShow).first);
    await tester.pump();
    expect(obscured(), isFalse);
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.enableIMEPersonalizedLearning, isFalse);
    expect(field.enableSuggestions, isFalse);
  });

  testWidgets('a senha errada avisa e limpa o campo', (tester) async {
    final core = FakeCore();
    await (await core.createWithPassphrase('calopsita lutino'))
        .createProfile('Lutino');
    await pumpChirp(tester, core: core, vault: FakeVault(available: false));
    expect(find.text(l10n.passphraseUnlockTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'outra senha');
    await tester.tap(find.text(l10n.passphraseUnlock));
    await tester.pumpAndSettle();
    expect(find.text(l10n.passphraseWrong), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    await tester.enterText(find.byType(TextField), 'calopsita lutino');
    await tester.tap(find.text(l10n.passphraseUnlock));
    await tester.pumpAndSettle();
    expect(find.text(l10n.contactsEmptyTitle), findsOneWidget);
  });

  testWidgets('chave perdida: apagar pergunta antes', (tester) async {
    final (core, vault) = await withProfile();
    vault.key = null;
    await pumpChirp(tester, core: core, vault: vault);
    expect(find.text(l10n.problemKeyLostTitle), findsOneWidget);
    expect(find.text(l10n.tryAgain), findsNothing);
    await tester.tap(find.text(l10n.eraseEverything));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(core.store, isNotNull);
    await tester.tap(find.text(l10n.eraseEverything));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.eraseConfirm));
    await tester.pumpAndSettle();
    expect(core.store?.saved, isNull);
    expect(find.text(l10n.welcomeTitle), findsOneWidget);
  });

  testWidgets('diz quando o núcleo não abriu', (tester) async {
    await pumpChirp(tester, core: FakeCore(info: null));
    expect(find.text(l10n.coreUnavailable), findsOneWidget);
    expect(find.text(l10n.problemCoreBody), findsOneWidget);
  });

  // Cada tela, na janela mínima e num celular pequeno, nos dois temas, com
  // contraste e rótulos.
  final screens = <String, Future<(FakeCore, FakeVault)> Function()>{
    'cadastro': () async => (FakeCore(), FakeVault()),
    'senha nova': () async => (FakeCore(), FakeVault(available: false)),
    'perfil': withProfile,
    'chave perdida': () async {
      final (core, vault) = await withProfile();
      vault.key = null;
      return (core, vault);
    },
  };
  for (final MapEntry(key: name, value: setup) in screens.entries) {
    for (final brightness in Brightness.values) {
      for (final (w, h) in [(240.0, 160.0), (320.0, 568.0)]) {
        testWidgets('$name cabe em ${w.toInt()}×${h.toInt()} no tema '
            '${brightness.name}', (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          setWindow(tester, w, h);
          final (core, vault) = await setup();
          await pumpChirp(tester, core: core, vault: vault);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('$name passa no contraste e tem rótulos', (tester) async {
      final handle = tester.ensureSemantics();
      final (core, vault) = await setup();
      await pumpChirp(tester, core: core, vault: vault);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}

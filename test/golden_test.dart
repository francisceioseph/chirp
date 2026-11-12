// As telas principais em imagens de referência (fase 4): a lista, a conversa e a
// aparência no celular, nos dois temas, e o computador com duas e três colunas, em
// outros temas. A fonte dos testes desenha caixas: conferem o desenho, não o texto.
//
//   flutter test test/golden_test.dart --update-goldens   (depois de mudar a UI)
@Tags(['golden'])
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  /// Três conversas, a primeira com bolhas dos dois lados, uma citação e uma reação.
  /// As datas são antigas, para a hora sair sempre com o dia (e não depender de hoje).
  Future<FakeStore> conversations(
    WidgetTester tester, {
    required Size size,
    required Appearance appearance,
  }) async {
    setWindow(tester, size.width, size.height);
    final (core, vault) = await withProfile();
    final store = core.store!
      ..savedAppearance = appearance
      ..now = DateTime(2025, 3, 4, 10, 30)
      ..someoneJoined('Canela')
      ..someoneJoined('Pérola', verified: false)
      ..someoneJoined('Girassol');
    store.incoming(3, 'Até amanhã');
    store.incoming(2, 'Chegou o convite?');
    final hello = store.incoming(1, 'Oi! Tudo bem por aí?');
    final mine = await store.sendText(
      1,
      'Tudo ótimo, e você?',
      replyTo: hello.id,
    );
    store.deliver(1, read: true);
    await store.react(mine.id, 0);
    store.incoming(1, 'Também! Vamos marcar aquele café.');
    await pumpChirp(tester, core: core, vault: vault);
    return store;
  }

  Future<void> open(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  const phone = Size(390, 844);
  const light = Appearance(mode: AppearanceMode.light);
  const dark = Appearance(mode: AppearanceMode.dark);

  for (final (name, appearance) in [('claro', light), ('escuro', dark)]) {
    testWidgets('celular, lista e conversa, $name', (tester) async {
      await conversations(tester, size: phone, appearance: appearance);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/celular_lista_$name.png'),
      );
      await open(tester, 'Canela');
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/celular_conversa_$name.png'),
      );
    });
  }

  testWidgets('celular, aparência', (tester) async {
    await conversations(tester, size: phone, appearance: light);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.themeLabel));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/celular_aparencia.png'),
    );
  });

  testWidgets('computador, três colunas, Old Days claro', (tester) async {
    await conversations(
      tester,
      size: const Size(1300, 800),
      appearance: const Appearance(
        theme: 'old-days',
        mode: AppearanceMode.light,
      ),
    );
    await open(tester, 'Canela');
    await tester.tap(find.bySemanticsLabel('${l10n.contactDetails}: Canela'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/computador_tres_colunas.png'),
    );
  });

  testWidgets('computador, duas colunas, Foundation escuro com vidro', (
    tester,
  ) async {
    await conversations(
      tester,
      size: const Size(1000, 700),
      appearance: const Appearance(
        theme: 'foundation',
        mode: AppearanceMode.dark,
        glass: true,
      ),
    );
    await open(tester, 'Canela');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/computador_duas_colunas.png'),
    );
  });

  testWidgets('computador, perfil', (tester) async {
    await conversations(
      tester,
      size: const Size(1300, 800),
      appearance: light,
    );
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/computador_perfil.png'),
    );
  });

  testWidgets('computador, convite', (tester) async {
    await conversations(
      tester,
      size: const Size(1300, 800),
      appearance: light,
    );
    await tester.tap(find.text(l10n.addContact).first);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/computador_convite.png'),
    );
  });
}

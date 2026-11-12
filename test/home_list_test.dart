// A lista de conversas do redesign: os filtros (a partir de quatro conversas), os
// grupos por alcance, à la MSN, e a linha apagada de quem está fora de alcance.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> four(WidgetTester tester) async {
    final (core, vault) = await withProfile();
    final store = core.store!
      ..someoneJoined('Canela')
      ..someoneJoined('Pérola', verified: false)
      ..someoneJoined('Girassol')
      ..someoneJoined('Arlequim', verified: false);
    store.incoming(2, 'Chegou o convite?');
    await pumpChirp(tester, core: core, vault: vault);
    return store;
  }

  testWidgets('com poucas conversas, sem filtros', (tester) async {
    final (core, vault) = await withProfile();
    core.store!.someoneJoined('Canela');
    await pumpChirp(tester, core: core, vault: vault);
    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets('os filtros mostram só as não lidas, ou só os verificados', (
    tester,
  ) async {
    await four(tester);
    expect(find.byType(FilterChip), findsNWidgets(3));
    await tester.tap(find.text(l10n.filterUnread));
    await tester.pumpAndSettle();
    expect(find.text('Pérola'), findsOneWidget);
    expect(find.text('Canela'), findsNothing);

    await tester.tap(find.text(l10n.filterVerified));
    await tester.pumpAndSettle();
    expect(find.text('Canela'), findsOneWidget);
    expect(find.text('Girassol'), findsOneWidget);
    expect(find.text('Pérola'), findsNothing);
    expect(find.text('Arlequim'), findsNothing);

    await tester.tap(find.text(l10n.filterAll));
    await tester.pumpAndSettle();
    expect(find.text('Arlequim'), findsOneWidget);
  });

  testWidgets('em grupos só quando o alcance de todos já se sabe', (
    tester,
  ) async {
    final store = await four(tester);
    expect(find.text(l10n.groupReachable(2)), findsNothing);
    store
      ..reached(1, ContactReach.lan)
      ..reached(2, ContactReach.direct);
    await tester.pumpAndSettle();
    // Dois ainda sem resposta: sem grupos.
    expect(find.text(l10n.groupReachable(2)), findsNothing);
    store
      ..reached(3, ContactReach.unreachable)
      ..reached(4, ContactReach.unreachable);
    await tester.pumpAndSettle();
    expect(find.text(l10n.groupReachable(2)), findsOneWidget);
    expect(find.text(l10n.groupUnreachable(2)), findsOneWidget);
    // Quem está fora de alcance fica apagado; quem ainda não se sabe, não.
    final arlequim = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Arlequim'), matching: find.byType(Opacity))
          .first,
    );
    expect(arlequim.opacity, lessThan(1));
    final canela = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Canela'), matching: find.byType(Opacity))
          .first,
    );
    expect(canela.opacity, 1);
  });

  testWidgets('filtrando, um filtro sem nada diz isso', (tester) async {
    final store = await four(tester);
    await tester.tap(find.text(l10n.filterUnread));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pérola'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(store.people, hasLength(4));
    expect(find.text(l10n.filterEmpty), findsOneWidget);
  });
}

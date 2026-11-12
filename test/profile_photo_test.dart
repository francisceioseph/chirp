// A foto do perfil: escolher, trocar e tirar, quem vê, a chave de cada contato no modo
// "só os marcados", a foto dos contatos nos avatares, e o cartão nos tamanhos pequenos.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> profile(
    WidgetTester tester, {
    FakeFilePicker? picker,
    void Function(FakeStore store)? before,
  }) async {
    final (core, vault) = await withProfile();
    before?.call(core.store!);
    await pumpChirp(tester, core: core, vault: vault, filePicker: picker);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    return core.store!;
  }

  Future<void> tapShown(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('escolher, trocar e tirar a foto, e quem vê', (tester) async {
    final picker = FakeFilePicker(pick: '/fotos/eu.txt');
    final store = await profile(tester, picker: picker);
    expect(find.byType(Image), findsNothing);

    // Um arquivo que não é foto é recusado com o aviso.
    await tapShown(tester, find.text(l10n.photoChoose));
    expect(find.text(l10n.fileInvalid), findsOneWidget);
    expect(store.saved!.photo, isNull);

    picker.pick = '/fotos/eu.jpg';
    await tapShown(tester, find.text(l10n.photoChoose));
    expect(store.photoPaths, ['/fotos/eu.jpg']);
    expect(store.saved!.photo, isNotNull);
    // A foto aparece no cartão do perfil e no da foto.
    expect(find.byType(Image), findsWidgets);
    expect(find.text(l10n.photoChange), findsOneWidget);

    await tapShown(tester, find.text(l10n.photoChosen));
    expect(store.saved!.photoVisibility, PhotoVisibility.chosen);
    await tapShown(tester, find.text(l10n.photoNobody));
    expect(store.saved!.photoVisibility, PhotoVisibility.nobody);
    expect(find.text(l10n.photoRevokeNote), findsOneWidget);

    await tapShown(tester, find.text(l10n.photoRemove));
    expect(store.saved!.photo, isNull);
    expect(find.text(l10n.photoChoose), findsOneWidget);
  });

  testWidgets('a chave de cada contato só aparece no "só os marcados"', (
    tester,
  ) async {
    final (core, vault) = await withProfile();
    final store = core.store!..someoneJoined('Canela');
    await pumpChirp(tester, core: core, vault: vault);

    Future<void> openContact() async {
      await tester.tap(find.text('Canela'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('${l10n.contactDetails}: Canela'));
      await tester.pumpAndSettle();
    }

    await openContact();
    expect(find.text(l10n.photoAllowed), findsNothing);
    await store.setPhotoVisibility(PhotoVisibility.chosen);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();
    await openContact();
    await tapShown(tester, find.text(l10n.photoAllowed));
    expect(store.photoAllowed, {1});
    await tapShown(tester, find.text(l10n.photoAllowed));
    expect(store.photoAllowed, isEmpty);
  });

  testWidgets('a foto de um contato aparece na lista', (tester) async {
    final (core, vault) = await withProfile();
    final store = core.store!..someoneJoined('Canela');
    final c = store.people.single;
    store.people[0] = Contact(
      id: c.id,
      displayName: c.displayName,
      avatarSeed: c.avatarSeed,
      verified: c.verified,
      established: c.established,
      photo: FakeStore.fakeJpeg,
    );
    await pumpChirp(tester, core: core, vault: vault);
    expect(find.byType(Image), findsOneWidget);
  });

  for (final size in const [Size(240, 160), Size(320, 568)]) {
    testWidgets(
      'o cartão da foto cabe em ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        setWindow(tester, size.width, size.height);
        await profile(
          tester,
          before: (store) => store.saved = Profile(
            displayName: store.saved!.displayName,
            version: 1,
            fingerprint: store.saved!.fingerprint,
            avatarSeed: store.saved!.avatarSeed,
            photo: FakeStore.fakeJpeg,
          ),
        );
        final note = find.text(l10n.photoRevokeNote);
        await tester.scrollUntilVisible(
          note,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.photoRemove), findsOneWidget);
      },
    );
  }
}

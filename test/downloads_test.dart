// O baixar sozinho, no perfil: o limite e o "só de contatos verificados".
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/l10n/chirp_localizations.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';

import 'helpers.dart';

void main() {
  final l10n = lookupChirpLocalizations(const Locale('pt'));

  Future<FakeStore> openProfile(WidgetTester tester) async {
    final (core, vault) = await withProfile();
    await pumpChirp(tester, core: core, vault: vault);
    await tester.tap(find.byTooltip(l10n.profileTitle));
    await tester.pumpAndSettle();
    return core.store!;
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('começa em até 32 MB, de qualquer contato', (tester) async {
    await openProfile(tester);
    await reveal(tester, find.text(l10n.onlyVerified));
    expect(find.text(l10n.downloadsTitle), findsOneWidget);
    final medium = tester.widget<RadioGroup<AutoDownload>>(
      find.byType(RadioGroup<AutoDownload>),
    );
    expect(medium.groupValue, AutoDownload.medium);
    final verified = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, l10n.onlyVerified),
    );
    expect(verified.value, isFalse);
  });

  testWidgets('escolher grava, e "nunca" esconde o só verificados', (
    tester,
  ) async {
    final store = await openProfile(tester);
    final verified = find.widgetWithText(SwitchListTile, l10n.onlyVerified);
    await reveal(tester, verified);
    await tester.ensureVisible(verified);
    await tester.pumpAndSettle();
    await tester.tap(verified);
    await tester.pumpAndSettle();
    expect(store.autoDownload.limit, AutoDownload.medium);
    expect(store.autoDownload.onlyVerified, isTrue);

    await tester.ensureVisible(find.text(l10n.autoDownloadSmall));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.autoDownloadSmall));
    await tester.pumpAndSettle();
    expect(store.autoDownload.limit, AutoDownload.small);
    expect(store.autoDownload.onlyVerified, isTrue);

    await tester.ensureVisible(find.text(l10n.autoDownloadNever));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.autoDownloadNever));
    await tester.pumpAndSettle();
    expect(store.autoDownload.limit, AutoDownload.never);
    expect(find.text(l10n.onlyVerified), findsNothing);
  });

  for (final size in const [Size(240, 160), Size(320, 568)]) {
    testWidgets(
      'o cartão cabe em ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        setWindow(tester, size.width, size.height);
        await openProfile(tester);
        await reveal(tester, find.text(l10n.onlyVerifiedHelp));
        expect(tester.takeException(), isNull);
        final large = find.widgetWithText(
          RadioListTile<AutoDownload>,
          l10n.autoDownloadLarge,
        );
        await tester.ensureVisible(large);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(large),
          matchesSemantics(
            label: l10n.autoDownloadLarge,
            hasCheckedState: true,
            isInMutuallyExclusiveGroup: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
            hasSelectedState: true,
          ),
        );
      },
    );
  }
}

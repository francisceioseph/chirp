// A fase 1 de ponta a ponta, no aparelho de verdade: o núcleo em Rust, o SQLCipher e o
// cofre do sistema, numa pasta temporária e com uma entrada própria no cofre, sem
// tocar nos dados de quem usa.
//
//   flutter test integration_test -d linux
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:psito_chirp/chirp_app.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:psito_chirp/src/platform/key_vault.dart';
import 'package:psito_chirp/src/ui/molecules/fingerprint_text.dart';

import '../test/helpers.dart' show FakeVault;

const _name = 'Calopsita Lutino de Teste';

Future<void> _open(WidgetTester tester, ChirpCore core, KeyVault vault) async {
  // Uma chave nova a cada abertura: o app começa do zero, como ao reabrir.
  await tester.pumpWidget(ChirpApp(key: UniqueKey(), core: core, vault: vault));
  await tester.pumpAndSettle();
}

/// Escreve pelo controller do campo: no binding de integração, o `enterText` não
/// chega a um campo que já tem o foco da plataforma de verdade.
void _type(WidgetTester tester, Finder field, String text) {
  tester.widget<TextField>(field).controller!.text = text;
}

Future<void> _submit(WidgetTester tester, String text) async {
  _type(tester, find.byType(TextField).first, text);
  await tester.pump();
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

/// Espera o núcleo (o Argon2 leva um tempo de verdade) até [finder] aparecer.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Todos os bytes dos arquivos da pasta.
List<int> _bytes(Directory dir) => [
  for (final file in dir.listSync().whereType<File>())
    ...file.readAsBytesSync(),
];

bool _contains(List<int> haystack, List<int> needle) {
  outer:
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('chirp_it_'));
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('com o cofre: cria, reabre e não deixa texto no disco', (
    tester,
  ) async {
    final core = await BridgeCore.open(dir: dir.path);
    expect(core.info, isNotNull);
    final vault = SystemKeyVault(name: 'org.psito.chirp.integration-test');
    addTearDown(vault.delete);

    await _open(tester, core, vault);
    expect(core.storeState(), StoreState.keyInVault);
    expect(await vault.read(), hasLength(32));
    await _submit(tester, _name);
    expect(find.text(_name), findsOneWidget);
    final fingerprint = tester
        .widget<FingerprintText>(find.byType(FingerprintText))
        .fingerprint;
    expect(fingerprint, matches(RegExp(r'^\d{5}( \d{5}){5}$')));

    await _open(tester, core, vault);
    expect(find.text(_name), findsOneWidget);
    expect(
      tester.widget<FingerprintText>(find.byType(FingerprintText)).fingerprint,
      fingerprint,
    );

    final bytes = _bytes(dir);
    expect(bytes, isNotEmpty);
    expect(_contains(bytes, _name.codeUnits), isFalse);
    expect(_contains(bytes, 'SQLite format 3'.codeUnits), isFalse);
    expect(dir.listSync().map((f) => f.uri.pathSegments.last), ['chirp.db']);
  });

  testWidgets('sem cofre: a senha tranca, e só a certa abre', (tester) async {
    final core = await BridgeCore.open(dir: dir.path);
    final vault = FakeVault(available: false);

    await _open(tester, core, vault);
    final fields = find.byType(TextField);
    _type(tester, fields.at(0), 'calopsita lutino');
    _type(tester, fields.at(1), 'calopsita lutino');
    await tester.tap(find.byType(FilledButton));
    // O cadastro aparece, com o contador do nome.
    await _waitFor(tester, find.textContaining('/64'));
    expect(core.storeState(), StoreState.passphrase);
    await _submit(tester, _name);
    await _waitFor(tester, find.text(_name));
    expect(find.text(_name), findsOneWidget);

    await _open(tester, core, vault);
    await _submit(tester, 'outra senha qualquer');
    await _waitFor(
      tester,
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.errorText != null,
      ),
    );
    expect(find.text(_name), findsNothing);
    await _submit(tester, 'calopsita lutino');
    await _waitFor(tester, find.text(_name));
    expect(find.text(_name), findsOneWidget);

    final bytes = _bytes(dir);
    expect(_contains(bytes, _name.codeUnits), isFalse);
    expect(_contains(bytes, 'calopsita'.codeUnits), isFalse);
  });
}

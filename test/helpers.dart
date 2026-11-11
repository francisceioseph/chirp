// O apoio dos testes: um núcleo e um cofre falsos, em memória, e a montagem do app.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/chirp_app.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:psito_chirp/src/platform/key_vault.dart';

const testFingerprint = '12345 67890 13579 24680 11223 34455';

/// O núcleo em memória. O "banco" lembra a chave ou a senha com que nasceu, e recusa
/// as outras como o de verdade.
class FakeCore implements ChirpCore {
  FakeCore({
    this.info = const CoreInfo(version: '9.9.9', protocol: 1),
    this.failOpen,
  });

  @override
  final CoreInfo? info;

  /// Uma falha forçada ao abrir o banco.
  CoreFailure? failOpen;

  Uint8List? storedKey;
  String? storedPassphrase;
  FakeStore? store;
  int _keys = 0;

  @override
  int get minPassphraseChars => 8;

  @override
  StoreState storeState() => store == null
      ? StoreState.missing
      : storedPassphrase != null
      ? StoreState.passphrase
      : StoreState.keyInVault;

  @override
  Uint8List newStoreKey() => Uint8List.fromList(List.filled(32, ++_keys));

  @override
  Future<ProfileStore> openWithKey(Uint8List key) async {
    if (failOpen case final failure?) throw CoreException(failure);
    if (store == null) {
      storedKey = key;
      return store = FakeStore();
    }
    if (!listEquals(storedKey, key)) {
      throw const CoreException(CoreFailure.wrongKey);
    }
    return store!;
  }

  @override
  Future<ProfileStore> createWithPassphrase(String passphrase) async {
    if (store != null) throw const CoreException(CoreFailure.alreadyExists);
    if (passphrase.length < minPassphraseChars) {
      throw const CoreException(CoreFailure.weakPassphrase);
    }
    storedPassphrase = passphrase;
    return store = FakeStore();
  }

  @override
  Future<ProfileStore> openWithPassphrase(String passphrase) async {
    if (failOpen case final failure?) throw CoreException(failure);
    if (passphrase != storedPassphrase) {
      throw const CoreException(CoreFailure.wrongKey);
    }
    return store!;
  }

  @override
  Future<void> wipe() async {
    store = null;
    storedKey = null;
    storedPassphrase = null;
  }
}

class FakeStore implements ProfileStore {
  Profile? saved;

  @override
  Future<Profile?> profile() async => saved;

  @override
  Future<Profile> createProfile(String name) async {
    if (saved != null) throw const CoreException(CoreFailure.alreadyExists);
    return saved = _profile(name, 1);
  }

  @override
  Future<Profile> rename(String name) async =>
      saved = _profile(name, saved!.version + 1);

  static Profile _profile(String name, int version) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 64 || trimmed.contains('\n')) {
      throw const CoreException(CoreFailure.invalidName);
    }
    return Profile(
      displayName: trimmed,
      version: version,
      fingerprint: testFingerprint,
      avatarSeed: 0x5a5a5,
    );
  }
}

/// O cofre em memória; [available] falso faz de conta que o sistema não tem cofre.
class FakeVault implements KeyVault {
  FakeVault({this.available = true});

  bool available;
  Uint8List? key;

  @override
  Future<Uint8List?> read() async {
    if (!available) throw const VaultUnavailable();
    return key;
  }

  @override
  Future<void> write(Uint8List key) async {
    if (!available) throw const VaultUnavailable();
    this.key = key;
  }

  @override
  Future<void> delete() async {
    if (!available) throw const VaultUnavailable();
    key = null;
  }
}

/// Um núcleo e um cofre que já têm um perfil.
Future<(FakeCore, FakeVault)> withProfile([String name = 'Lutino']) async {
  final core = FakeCore();
  final vault = FakeVault();
  final key = core.newStoreKey();
  vault.key = key;
  await (await core.openWithKey(key)).createProfile(name);
  return (core, vault);
}

void setWindow(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> pumpChirp(
  WidgetTester tester, {
  FakeCore? core,
  FakeVault? vault,
}) async {
  await tester.pumpWidget(
    ChirpApp(core: core ?? FakeCore(), vault: vault ?? FakeVault()),
  );
  await tester.pumpAndSettle();
}

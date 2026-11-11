// O apoio dos testes: um núcleo e um cofre falsos, em memória, e a montagem do app.
import 'dart:async';

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

  /// A rede falsa: os contatos, os convites feitos e o que a rede responde.
  final List<Contact> people = [];
  final List<String> invites = [];
  bool networkStarted = false;
  CoreFailure? networkFailure;
  final _changes = StreamController<int>.broadcast();
  final Map<int, bool> _verified = {};

  /// Alguém leu um convite nosso.
  void someoneJoined(String name, {bool verified = true}) {
    final contact = Contact(
      id: people.length + 1,
      displayName: name,
      avatarSeed: people.length * 7919,
      verified: verified,
      established: true,
    );
    people.add(contact);
    _changes.add(contact.id);
  }

  @override
  Future<void> startNetwork() async {
    if (networkFailure case final failure?) throw CoreException(failure);
    networkStarted = true;
  }

  @override
  Future<void> stopNetwork() async => networkStarted = false;

  @override
  Future<String> createInvite({required bool qr}) async {
    final link = 'chirp://invite#${qr ? 'qr' : 'link'}${invites.length}';
    invites.add(link);
    return link;
  }

  /// `chirp://invite#nome` vira o contato "nome"; `#refused` e `#away` falham.
  @override
  Future<Contact> addContact(String link, {required bool scanned}) async {
    final trimmed = link.trim();
    if (!trimmed.startsWith('chirp://invite#')) {
      throw const CoreException(CoreFailure.invalidInvite);
    }
    final name = trimmed.substring('chirp://invite#'.length);
    if (name == 'refused') throw const CoreException(CoreFailure.inviteRefused);
    if (name == 'away') throw const CoreException(CoreFailure.unreachable);
    final contact = Contact(
      id: people.length + 1,
      displayName: name,
      avatarSeed: people.length * 7919,
      verified: scanned,
      established: true,
    );
    people.add(contact);
    return contact;
  }

  @override
  Future<List<Contact>> contacts() async => [
    for (final c in people)
      Contact(
        id: c.id,
        displayName: c.displayName,
        avatarSeed: c.avatarSeed,
        verified: _verified[c.id] ?? c.verified,
        established: c.established,
      ),
  ];

  @override
  Future<String> safetyNumber(int contactId) async =>
      List.generate(60, (i) => '${(i + contactId) % 10}').join();

  @override
  Future<Contact> setVerified(int contactId, {required bool verified}) async {
    _verified[contactId] = verified;
    return (await contacts()).firstWhere((c) => c.id == contactId);
  }

  @override
  Stream<int> contactChanges() => _changes.stream;

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

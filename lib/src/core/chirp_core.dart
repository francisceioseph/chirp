// lib/src/core/chirp_core.dart
//
// A porta para o núcleo em Rust. A UI só conhece o ChirpCore e o ProfileStore; o
// BridgeCore é a ponte gerada pelo flutter_rust_bridge (lib/src/bridge/), e os testes
// usam um falso. Os tipos da ponte não passam daqui.

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../bridge/api/info.dart' as bridge;
import '../bridge/api/store.dart' as bridge;
import '../bridge/error.dart' as bridge;
import '../bridge/frb_generated.dart';

/// A versão do núcleo e a do protocolo que ele fala no fio.
@immutable
class CoreInfo {
  const CoreInfo({required this.version, required this.protocol});

  final String version;
  final int protocol;
}

/// Como abrir o banco deste aparelho.
enum StoreState {
  /// Ainda não existe: é a primeira abertura.
  missing,

  /// A chave está no cofre do sistema.
  keyInVault,

  /// A chave vem de uma senha.
  passphrase,
}

/// O que deu errado no núcleo. Não carrega texto: a UI escolhe a mensagem.
enum CoreFailure {
  wrongKey,
  badKey,
  weakPassphrase,
  invalidName,
  alreadyExists,
  newerStore,
  noRandomness,
  storage,
}

class CoreException implements Exception {
  const CoreException(this.failure);

  final CoreFailure failure;

  @override
  String toString() => 'CoreException(${failure.name})';
}

/// O perfil deste aparelho.
@immutable
class Profile {
  const Profile({
    required this.displayName,
    required this.version,
    required this.fingerprint,
    required this.avatarSeed,
  });

  final String displayName;
  final int version;

  /// A impressão digital da identidade: 30 dígitos em 6 grupos de 5.
  final String fingerprint;

  /// A semente do avatar gerado a partir da chave.
  final int avatarSeed;
}

/// O que a UI pode pedir ao núcleo.
abstract interface class ChirpCore {
  /// Nulo quando a biblioteca nativa não abriu.
  CoreInfo? get info;

  /// O mínimo de caracteres de uma senha.
  int get minPassphraseChars;

  StoreState storeState();

  /// Uma chave nova para o banco, para guardar no cofre.
  Uint8List newStoreKey();

  Future<ProfileStore> openWithKey(Uint8List key);

  Future<ProfileStore> createWithPassphrase(String passphrase);

  Future<ProfileStore> openWithPassphrase(String passphrase);

  /// Apaga o banco deste aparelho.
  Future<void> wipe();
}

/// O banco aberto.
abstract interface class ProfileStore {
  Future<Profile?> profile();

  Future<Profile> createProfile(String name);

  Future<Profile> rename(String name);
}

/// O núcleo de verdade, pela ponte.
class BridgeCore implements ChirpCore {
  BridgeCore._(this.info, this._dir);

  @override
  final CoreInfo? info;

  /// A biblioteca nativa só abre uma vez por processo.
  static bool _initialized = false;

  /// A pasta de suporte do app, onde fica o banco.
  final String _dir;

  /// Abre a biblioteca nativa. Se ela faltar ou não carregar, o app abre do mesmo
  /// jeito e diz que o núcleo não iniciou, em vez de fechar sem explicação.
  ///
  /// [dir] troca a pasta do banco (os testes de integração usam uma temporária).
  static Future<BridgeCore> open({String? dir}) async {
    dir ??= (await getApplicationSupportDirectory()).path;
    try {
      if (!_initialized) {
        await RustLib.init();
        _initialized = true;
      }
      final info = bridge.coreInfo();
      return BridgeCore._(
        CoreInfo(version: info.version, protocol: info.protocol),
        dir,
      );
    } catch (error) {
      debugPrint('chirp: core failed to start: $error');
      return BridgeCore._(null, dir);
    }
  }

  @override
  int get minPassphraseChars => bridge.minPassphraseChars();

  @override
  StoreState storeState() => switch (bridge.storeState(dir: _dir)) {
    bridge.StoreState.missing => StoreState.missing,
    bridge.StoreState.keyInVault => StoreState.keyInVault,
    bridge.StoreState.passphrase => StoreState.passphrase,
  };

  @override
  Uint8List newStoreKey() => _guard(bridge.newStoreKey);

  @override
  Future<ProfileStore> openWithKey(Uint8List key) => _guardAsync(
    () async =>
        _BridgeStore(await bridge.ChirpStore.openWithKey(dir: _dir, key: key)),
  );

  @override
  Future<ProfileStore> createWithPassphrase(String passphrase) => _guardAsync(
    () async => _BridgeStore(
      await bridge.ChirpStore.createWithPassphrase(
        dir: _dir,
        passphrase: passphrase,
      ),
    ),
  );

  @override
  Future<ProfileStore> openWithPassphrase(String passphrase) => _guardAsync(
    () async => _BridgeStore(
      await bridge.ChirpStore.openWithPassphrase(
        dir: _dir,
        passphrase: passphrase,
      ),
    ),
  );

  @override
  Future<void> wipe() => _guardAsync(() => bridge.wipeStore(dir: _dir));
}

class _BridgeStore implements ProfileStore {
  _BridgeStore(this._store);

  final bridge.ChirpStore _store;

  @override
  Future<Profile?> profile() =>
      _guardAsync(() async => _profile(await _store.profile()));

  @override
  Future<Profile> createProfile(String name) => _guardAsync(
    () async => _profile(await _store.createProfile(name: name))!,
  );

  @override
  Future<Profile> rename(String name) =>
      _guardAsync(() async => _profile(await _store.rename(name: name))!);
}

Profile? _profile(bridge.Profile? p) => p == null
    ? null
    : Profile(
        displayName: p.displayName,
        version: p.version,
        fingerprint: p.fingerprint,
        avatarSeed: p.avatarSeed,
      );

CoreFailure _failure(bridge.CoreError error) => switch (error) {
  bridge.CoreError.wrongKey => CoreFailure.wrongKey,
  bridge.CoreError.badKey => CoreFailure.badKey,
  bridge.CoreError.weakPassphrase => CoreFailure.weakPassphrase,
  bridge.CoreError.invalidName => CoreFailure.invalidName,
  bridge.CoreError.alreadyExists => CoreFailure.alreadyExists,
  bridge.CoreError.newerStore => CoreFailure.newerStore,
  bridge.CoreError.noRandomness => CoreFailure.noRandomness,
  bridge.CoreError.storage => CoreFailure.storage,
};

T _guard<T>(T Function() call) {
  try {
    return call();
  } on bridge.CoreError catch (error) {
    throw CoreException(_failure(error));
  }
}

Future<T> _guardAsync<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on bridge.CoreError catch (error) {
    throw CoreException(_failure(error));
  }
}

// lib/src/platform/key_vault.dart
//
// O cofre do sistema, onde fica a chave do banco (docs/PLANO.md, 8): o Keychain no
// macOS e no iOS, o Keystore no Android, o Secret Service (libsecret) no Linux e o
// cofre de credenciais no Windows, todos pelo flutter_secure_storage. Quando o cofre
// não responde, o Chirp pede uma senha em vez de gravar a chave em claro.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// O cofre não está disponível (sem Secret Service, Keychain sem permissão...).
class VaultUnavailable implements Exception {
  const VaultUnavailable();

  @override
  String toString() => 'VaultUnavailable';
}

abstract interface class KeyVault {
  /// A chave guardada, ou nulo se não houver. Lança [VaultUnavailable].
  Future<Uint8List?> read();

  /// Guarda a chave, e confere lendo de volta. Lança [VaultUnavailable].
  Future<void> write(Uint8List key);

  /// Tira a chave do cofre. Lança [VaultUnavailable].
  Future<void> delete();
}

class SystemKeyVault implements KeyVault {
  SystemKeyVault({FlutterSecureStorage? storage, this.name = defaultName})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Só neste aparelho: fora do iCloud e dos backups, e só depois do primeiro
            // desbloqueio.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
            mOptions: MacOsOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const defaultName = 'org.psito.chirp.store-key';

  /// O nome da entrada no cofre (os testes de integração usam outro).
  final String name;

  final FlutterSecureStorage _storage;

  @override
  Future<Uint8List?> read() async {
    final value = await _call(() => _storage.read(key: name));
    if (value == null) return null;
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(Uint8List key) async {
    await _call(() => _storage.write(key: name, value: base64Encode(key)));
    final back = await read();
    if (back == null || !listEquals(back, key)) throw const VaultUnavailable();
  }

  @override
  Future<void> delete() => _call(() => _storage.delete(key: name));

  Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      // Nunca o conteúdo: só o tipo do erro.
      debugPrint('chirp: key vault failed: ${error.runtimeType}');
      throw const VaultUnavailable();
    }
  }
}

import 'dart:io';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/infrastructure/repositories/identity_prefs_repository.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

class IdentityService {
  final IdentityPrefsRepository _repository;
  static const _suffix = String.fromEnvironment("TIEL_ID", defaultValue: "");

  IdentityService(this._repository);

  Future<Identity> loadOrCreateIdentity() async {
    final savedIdentity = await _repository.get();

    if (savedIdentity != null) {
      return savedIdentity;
    }

    final id = const Uuid().v4();
    final name = await _buildDefaultName();

    final keyPair = SecureChirp.makeKeys();

    final newIdentity = Identity(
      id: id,
      name: name,
      publicKey: keyPair.pubKey,
      privateKey: keyPair.privKey,
    );

    await _repository.save(newIdentity);
    return newIdentity;
  }

  Future<Identity> signIn({
    required String nickname,
    required String email,
  }) async {
    final keyPair = SecureChirp.makeKeys();
    final id = const Uuid().v4();

    final identity = Identity(
      id: id,
      name: _sanitize(nickname),
      email: email,
      publicKey: keyPair.pubKey,
      privateKey: keyPair.privKey,
    );

    await _repository.save(identity);
    return identity;
  }

  Future<void> signOut() async {
    await _repository.clear();
  }

  Future<String> _buildDefaultName() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    String rawName = "Tiel";
    try {
      rawName = switch (Platform.operatingSystem) {
        'linux' => (await deviceInfo.linuxInfo).name,
        'windows' => (await deviceInfo.windowsInfo).computerName,
        'macos' => (await deviceInfo.macOsInfo).computerName,
        'android' => (await deviceInfo.androidInfo).model,
        'ios' => (await deviceInfo.iosInfo).name,
        _ => "Tiel",
      };
    } catch (_) {
      rawName = "Tiel_Guest";
    }

    return _sanitize(rawName);
  }

  String _sanitize(String name) {
    final clean = name
        .trim()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');

    final label = _suffix.isNotEmpty ? "_#$_suffix" : "";
    return "$clean$label";
  }
}

import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/infrastructure/repositories/identity_prefs_repository.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';

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
    final name = await _buildHardwareName();
    final keyPair = SecureChirp.makeKeys();

    final newIdentity = Identity(
      id: id,
      name: name,
      nickname: name,
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

    final hardwareName = await _buildHardwareName();

    final identity = Identity(
      id: id,
      name: hardwareName,
      nickname: _sanitize(nickname),
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

  Future<Identity> updateNickname(String newNickname) async {
    final current = await _repository.get();
    if (current == null) throw Exception("Identidade não encontrada");

    final updated = current.copyWith(nickname: _sanitize(newNickname));
    await _repository.save(updated);

    return updated;
  }

  Future<String> _buildHardwareName() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String hardwareName = "Chirper";

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        hardwareName = "${info.manufacturer} ${info.model}";
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        hardwareName = info.name;
      } else if (Platform.isMacOS) {
        hardwareName = (await deviceInfo.macOsInfo).computerName;
      } else if (Platform.isWindows) {
        hardwareName = (await deviceInfo.windowsInfo).computerName;
      } else if (Platform.isLinux) {
        hardwareName = (await deviceInfo.linuxInfo).name;
      }
    } catch (_) {
      hardwareName = "Guest";
    }

    return _generateUniqueName(hardwareName);
  }

  String _generateUniqueName(String base) {
    final randomSuffix = Random()
        .nextInt(0xFFFF)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(4, '0');

    final sanitizedBase = _sanitize(base);
    final envLabel = _suffix.isNotEmpty ? "_#$_suffix" : "";

    return "${sanitizedBase}_$randomSuffix$envLabel";
  }

  String _sanitize(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}

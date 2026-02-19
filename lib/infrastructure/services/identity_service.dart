import 'dart:io';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class IdentityService {
  static const _suffix = String.fromEnvironment("TIEL_ID", defaultValue: "");

  static String get _keyId => 'tiel_id$_suffix';
  static String get _keyName => 'tiel_name$_suffix';
  static String get _keyPublic => 'tiel_pub_key$_suffix';
  static String get _keyPrivate => 'tiel_priv_key$_suffix';

  static Future<Identity> getIdentity() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString(_keyId) ?? Uuid().v4();
    if (!prefs.containsKey(_keyId)) await prefs.setString(_keyId, id);

    final name = prefs.getString(_keyName) ?? await _buildTielName();
    if (!prefs.containsKey(_keyName)) await prefs.setString(_keyName, id);

    String? pubKey = prefs.getString(_keyPublic);
    String? privKey = prefs.getString(_keyPrivate);

    if (pubKey == null || privKey == null) {
      final keyPair = SecureChirp.makeKeys();
      pubKey = keyPair.pubKey;
      privKey = keyPair.privKey;

      await prefs.setString(_keyPublic, pubKey);
      await prefs.setString(_keyPrivate, privKey);
    }

    return Identity(id: id, name: name, publicKey: pubKey, privateKey: privKey);
  }

  static Future<String> _buildTielName() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    String rawName = switch (Platform.operatingSystem) {
      'linux' => (await deviceInfo.linuxInfo).name,
      'windows' => (await deviceInfo.windowsInfo).computerName,
      'macos' => (await deviceInfo.macOsInfo).computerName,
      'android' => (await deviceInfo.androidInfo).model,
      'ios' => (await deviceInfo.iosInfo).name,
      _ => "Tiel",
    };

    return _sanitize(rawName);
  }

  static String _sanitize(String name) {
    final clean = name
        .trim()
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');

    final label = _suffix.isNotEmpty ? "_#$_suffix" : "";
    return "$clean$label";
  }
}

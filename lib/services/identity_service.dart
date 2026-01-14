import 'dart:io';
import 'package:chirp/models/identity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class IdentityService {
  static String get _tielSuffix {
    const suffix = String.fromEnvironment("TIEL_ID", defaultValue: "");
    return suffix;
  }

  static Future<Identity> getIdentity() async {
    final id = await _getTielId();
    final name = await _getTielName();

    return Identity(id: id, name: name);
  }

  static Future<String> _getTielId() async {
    final String keyId = 'tiel_id$_tielSuffix';
    final prefs = await SharedPreferences.getInstance();

    String? id = prefs.getString(keyId);

    if (id == null) {
      id = Uuid().v4();
      await prefs.setString(keyId, id);
    }

    return id;
  }

  static Future<String> _getTielName() async {
    final String keyName = 'tiel_name$_tielSuffix';
    final prefs = await SharedPreferences.getInstance();

    String? name = prefs.getString(keyName);

    if (name == null) {
      name = await _buildTielName();
      await prefs.setString(keyName, name);
    }

    return name;
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

    final milis = DateTime.now().millisecondsSinceEpoch;

    return "${clean}_$milis";
  }
}

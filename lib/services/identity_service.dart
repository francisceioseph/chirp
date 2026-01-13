import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class IdentityService {
  static Future<String> getUniqueId() async {
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

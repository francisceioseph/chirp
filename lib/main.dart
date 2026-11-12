// lib/main.dart
//
// O Chirp sozinho: abre o núcleo em Rust e entrega ao ChirpApp, com o cofre do
// sistema. Os testes montam o ChirpApp com falsos, sem a biblioteca nativa.
import 'package:flutter/material.dart';

import 'chirp_app.dart';
import 'src/core/chirp_core.dart';
import 'src/logging.dart';
import 'src/platform/key_vault.dart';
import 'src/platform/notifier.dart';
import 'src/platform/system_accent.dart';

Future<void> main() async {
  silenceLogsInRelease();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChirpApp(
      core: await BridgeCore.open(),
      vault: SystemKeyVault(),
      systemAccent: readSystemAccent,
      notifier: SystemNotifier(),
    ),
  );
}

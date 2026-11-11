// lib/main.dart
//
// O Chirp sozinho: abre o núcleo em Rust e entrega ao ChirpApp. Os testes montam o
// ChirpApp com um núcleo falso, sem a biblioteca nativa.
import 'package:flutter/material.dart';

import 'chirp_app.dart';
import 'src/core/chirp_core.dart';
import 'src/logging.dart';

Future<void> main() async {
  silenceLogsInRelease();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChirpApp(core: await BridgeCore.open()));
}

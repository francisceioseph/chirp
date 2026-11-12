// lib/src/platform/microphone.dart
//
// A licença do microfone, para as notas de voz. No Android, pelo canal da
// MainActivity: o sistema pergunta na primeira vez. No iOS e no macOS, o sistema
// pergunta sozinho quando o núcleo abre o microfone (o NSMicrophoneUsageDescription);
// no Linux e no Windows, não há o que pedir.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('org.psito.chirp/background');

/// Diz se dá para gravar (pedindo ao sistema, se for o caso).
Future<bool> askMicrophone() async {
  if (kIsWeb || !Platform.isAndroid) return true;
  try {
    return await _channel.invokeMethod<bool>('askMicrophone') ?? false;
  } on PlatformException {
    return false;
  }
}

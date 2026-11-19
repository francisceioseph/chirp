// lib/src/platform/bluetooth.dart
//
// As licenças do Bluetooth (fase 8). No Android, pelo canal da MainActivity: o sistema
// pergunta ao ligar o Bluetooth do Chirp (no 12 ou mais novo, as do Bluetooth; no 10 e
// no 11, a localização, que ele exige para procurar). No Linux, não há o que pedir.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('org.psito.chirp/background');

/// Se o sistema tem o Bluetooth do Chirp.
bool get bluetoothSupported =>
    !kIsWeb && (Platform.isLinux || Platform.isAndroid);

/// Diz se dá para usar o Bluetooth (pedindo ao sistema, se for o caso).
Future<bool> askBluetooth() async {
  if (kIsWeb || !Platform.isAndroid) return true;
  try {
    return await _channel.invokeMethod<bool>('askBluetooth') ?? false;
  } on PlatformException {
    return false;
  }
}

// lib/src/platform/system_accent.dart
//
// A cor de destaque do sistema, para o tema "Cor do sistema": no Android 12+, a
// paleta do papel de parede; no Linux (o portal do XDG ou o tema GTK), no Windows e
// no macOS, a cor de destaque. Tudo local, pelo plugin dynamic_color. Onde não há
// (iOS, Android antigo), `null`, e a opção não aparece.
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// No Linux, o portal responde (-1, -1, -1) quando ninguém escolheu uma cor, e o
/// dynamic_color 2.1.0 converte isso nesta cor em vez de cair no tema GTK.
const _portalUnset = 0xFFFFFF01;

Future<Color?> readSystemAccent() async {
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final palette = await DynamicColorPlugin.getCorePalette();
      return palette == null ? null : Color(palette.primary.get(40));
    }
    final accent = await DynamicColorPlugin.getAccentColor();
    if (accent == null || accent.toARGB32() == _portalUnset) return null;
    return accent;
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

// lib/src/core/chirp_core.dart
//
// A porta para o núcleo em Rust. A UI só conhece o ChirpCore; o BridgeCore é a ponte
// gerada pelo flutter_rust_bridge (lib/src/bridge/), e os testes usam um falso.
import 'package:flutter/foundation.dart';

import '../bridge/api/info.dart' as bridge;
import '../bridge/frb_generated.dart';

/// A versão do núcleo e a do protocolo que ele fala no fio.
@immutable
class CoreInfo {
  const CoreInfo({required this.version, required this.protocol});

  final String version;
  final int protocol;
}

/// O que a UI pode pedir ao núcleo.
abstract interface class ChirpCore {
  /// Nulo quando a biblioteca nativa não abriu.
  CoreInfo? get info;
}

/// O núcleo de verdade, pela ponte.
class BridgeCore implements ChirpCore {
  BridgeCore._(this.info);

  @override
  final CoreInfo? info;

  /// Abre a biblioteca nativa. Se ela faltar ou não carregar, o app abre do mesmo
  /// jeito e diz que o núcleo não iniciou, em vez de fechar sem explicação.
  static Future<BridgeCore> open() async {
    try {
      await RustLib.init();
      final info = bridge.coreInfo();
      return BridgeCore._(
        CoreInfo(version: info.version, protocol: info.protocol),
      );
    } catch (error) {
      debugPrint('chirp: core failed to start: $error');
      return BridgeCore._(null);
    }
  }
}

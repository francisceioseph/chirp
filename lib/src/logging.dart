// lib/src/logging.dart
//
// O que o Chirp escreve na saída. Nomes, ids, endereços e conteúdo não ficam no log de
// quem usa, que pode ir parar no journal: instalado, ele só escreve com o ajuste ligado. Em
// desenvolvimento, escreve sempre.
import 'package:flutter/foundation.dart';

/// O ajuste de registrar logs.
bool logsEnabled = false;

bool _gated = false;

DebugPrintCallback gatedPrint(DebugPrintCallback write) =>
    (message, {wrapWidth}) {
      if (logsEnabled) write(message, wrapWidth: wrapWidth);
    };

/// Vale para o processo inteiro. Chamar de novo não muda nada.
void silenceLogsInRelease() {
  if (!kReleaseMode || _gated) return;
  _gated = true;
  debugPrint = gatedPrint(debugPrint);
}

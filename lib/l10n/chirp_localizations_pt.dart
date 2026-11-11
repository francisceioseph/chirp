// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class ChirpLocalizationsPt extends ChirpLocalizations {
  ChirpLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Conversas que ficam entre vocês';

  @override
  String get welcomeBody =>
      'Sem contas, sem servidores, sem registros. Suas mensagens vivem só nos seus aparelhos.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Núcleo $version · protocolo $protocol';
  }

  @override
  String get coreUnavailable => 'O núcleo seguro não conseguiu iniciar.';

  @override
  String get foundationNote =>
      'Esta é a fundação do novo Chirp. As conversas chegam nas próximas fases.';
}

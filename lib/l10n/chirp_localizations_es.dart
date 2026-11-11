// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ChirpLocalizationsEs extends ChirpLocalizations {
  ChirpLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Conversaciones que quedan entre ustedes';

  @override
  String get welcomeBody =>
      'Sin cuentas, sin servidores, sin registros. Tus mensajes viven solo en tus dispositivos.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Núcleo $version · protocolo $protocol';
  }

  @override
  String get coreUnavailable => 'El núcleo seguro no pudo iniciarse.';

  @override
  String get foundationNote =>
      'Esta es la base del nuevo Chirp. Las conversaciones llegan en las próximas fases.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class ChirpLocalizationsDe extends ChirpLocalizations {
  ChirpLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Gespräche, die unter euch bleiben';

  @override
  String get welcomeBody =>
      'Keine Konten, keine Server, keine Protokolle. Deine Nachrichten leben nur auf deinen Geräten.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Kern $version · Protokoll $protocol';
  }

  @override
  String get coreUnavailable => 'Der sichere Kern konnte nicht starten.';

  @override
  String get foundationNote =>
      'Das ist das Fundament des neuen Chirp. Unterhaltungen kommen in den nächsten Phasen.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ChirpLocalizationsFr extends ChirpLocalizations {
  ChirpLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Des conversations qui restent entre vous';

  @override
  String get welcomeBody =>
      'Pas de compte, pas de serveur, pas de journaux. Vos messages ne vivent que sur vos appareils.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Noyau $version · protocole $protocol';
  }

  @override
  String get coreUnavailable => 'Le noyau sécurisé n’a pas pu démarrer.';

  @override
  String get foundationNote =>
      'Voici la base du nouveau Chirp. Les conversations arrivent dans les prochaines phases.';
}

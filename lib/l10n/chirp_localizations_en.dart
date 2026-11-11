// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ChirpLocalizationsEn extends ChirpLocalizations {
  ChirpLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Conversations that stay between you';

  @override
  String get welcomeBody =>
      'No accounts, no servers, no logs. Your messages live only on your devices.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Core $version · protocol $protocol';
  }

  @override
  String get coreUnavailable => 'The secure core could not start.';

  @override
  String get foundationNote =>
      'This is the foundation of the new Chirp. Conversations arrive in the next phases.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class ChirpLocalizationsRu extends ChirpLocalizations {
  ChirpLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Разговоры, которые остаются между вами';

  @override
  String get welcomeBody =>
      'Без аккаунтов, без серверов, без журналов. Ваши сообщения хранятся только на ваших устройствах.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Ядро $version · протокол $protocol';
  }

  @override
  String get coreUnavailable => 'Не удалось запустить защищённое ядро.';

  @override
  String get foundationNote =>
      'Это основа нового Chirp. Переписка появится на следующих этапах.';
}

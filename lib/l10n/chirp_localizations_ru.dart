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
      'Без аккаунтов, без серверов, без журналов. Ваши сообщения живут только на ваших устройствах.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Ядро $version · протокол $protocol';
  }

  @override
  String get coreUnavailable => 'Защищённое ядро не запустилось.';

  @override
  String get loading => 'Открываем Chirp';

  @override
  String get nameLabel => 'Ваше имя';

  @override
  String get nameHelp =>
      'Его увидят только ваши контакты, и только в зашифрованном виде.';

  @override
  String get nameInvalid => 'Введите имя длиной до 64 символов в одну строку.';

  @override
  String get onboardingCreate => 'Создать профиль';

  @override
  String get passphraseCreateTitle => 'Защитите Chirp парольной фразой';

  @override
  String get passphraseCreateBody =>
      'В этой системе нет связки ключей, где Chirp мог бы хранить свой ключ, поэтому ваши данные будут заперты парольной фразой. Если вы её забудете, восстановить её нельзя.';

  @override
  String get passphraseUnlockTitle => 'Разблокировать Chirp';

  @override
  String get passphraseLabel => 'Парольная фраза';

  @override
  String get passphraseConfirmLabel => 'Повторите парольную фразу';

  @override
  String get passphraseShow => 'Показать парольную фразу';

  @override
  String get passphraseHide => 'Скрыть парольную фразу';

  @override
  String passphraseTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Используйте не меньше $count символа.',
      many: 'Используйте не меньше $count символов.',
      few: 'Используйте не меньше $count символов.',
      one: 'Используйте не меньше $count символа.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseMismatch => 'Парольные фразы не совпадают.';

  @override
  String get passphraseWrong => 'Эта парольная фраза не открывает Chirp.';

  @override
  String get passphraseCreate => 'Запереть этой фразой';

  @override
  String get passphraseUnlock => 'Разблокировать';

  @override
  String get passphraseForgot => 'Я забыл парольную фразу';

  @override
  String get problemCoreBody =>
      'Файлы приложения могут быть неполными. Установите Chirp заново.';

  @override
  String get problemVaultTitle => 'Связка ключей не ответила';

  @override
  String get problemVaultBody =>
      'Chirp хранит свой ключ в связке ключей системы, и она не ответила. Разблокируйте её и попробуйте снова.';

  @override
  String get problemKeyLostTitle => 'Ключ к вашим данным пропал';

  @override
  String get problemKeyLostBody =>
      'Ваши данные всё ещё на этом устройстве, но ключа, который их открывает, больше нет в связке ключей системы. Без него ничего нельзя прочитать. Можно всё стереть и начать заново.';

  @override
  String get problemNewerTitle => 'Эти данные от более новой версии Chirp';

  @override
  String get problemNewerBody => 'Обновите Chirp, чтобы открыть их.';

  @override
  String get problemStorageTitle => 'Chirp не смог открыть свои данные';

  @override
  String get problemStorageBody =>
      'При чтении диска что-то пошло не так. Попробуйте снова; если это повторяется, можно всё стереть и начать заново.';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get eraseEverything => 'Стереть всё и начать заново';

  @override
  String get eraseTitle => 'Стереть всё?';

  @override
  String get eraseBody =>
      'Ваш профиль, ваш ключ и всё, что Chirp хранит на этом устройстве, исчезнут навсегда.';

  @override
  String get eraseConfirm => 'Стереть';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get renameTooltip => 'Изменить имя';

  @override
  String get renameTitle => 'Измените имя';

  @override
  String get profileKeyLabel => 'Ваш ключ';

  @override
  String get profileKeyHelp =>
      'Ваши контакты сверяют это число, чтобы знать, что это действительно вы.';

  @override
  String get homeNextPhase =>
      'Ваш профиль и ключ готовы. Разговоры появятся на следующем этапе.';

  @override
  String get somethingWentWrong => 'Что-то пошло не так. Попробуйте снова.';
}

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
  String get somethingWentWrong => 'Что-то пошло не так. Попробуйте снова.';

  @override
  String get profileTitle => 'Ваш профиль';

  @override
  String get addContact => 'Добавить контакт';

  @override
  String get contactsEmptyTitle => 'Здесь пока никого';

  @override
  String get contactsEmptyBody =>
      'Чтобы общаться, обменяйтесь приглашениями. Сообщения идут напрямую с устройства на устройство, зашифрованные, без серверов.';

  @override
  String get contactPending => 'Ждём другое устройство';

  @override
  String get contactVerified => 'Проверен';

  @override
  String get contactUnverified => 'Не проверен';

  @override
  String get contactUnnamed => 'Пока без имени';

  @override
  String contactAdded(String name) {
    return '$name теперь в ваших контактах.';
  }

  @override
  String get inviteTabShow => 'Мой код';

  @override
  String get inviteTabPaste => 'Вставить приглашение';

  @override
  String get inviteQrLabel => 'Код приглашения в виде QR';

  @override
  String get inviteQrHelp =>
      'Дайте другому человеку отсканировать этот код или отправьте ссылку. Каждый код действует один раз, 24 часа.';

  @override
  String get inviteCopyLink => 'Скопировать ссылку-приглашение';

  @override
  String get inviteLinkCopied =>
      'Ссылка скопирована. Отправьте её по каналу, которому доверяете: она действует один раз, 24 часа.';

  @override
  String get inviteNewCode => 'Новый код';

  @override
  String get pasteLabel => 'Ссылка-приглашение';

  @override
  String get pasteHelp => 'Начинается с chirp://invite';

  @override
  String get pasteAdd => 'Добавить';

  @override
  String get pasteConnecting => 'Подключаемся';

  @override
  String get qrScanLater =>
      'Чтение кода камерой появится в следующей версии. Пока вставьте ссылку.';

  @override
  String get inviteInvalid =>
      'Это не приглашение Chirp, или в нём чего-то не хватает.';

  @override
  String get inviteRefused =>
      'Срок приглашения истёк, или оно уже использовано. Попросите новое.';

  @override
  String get inviteOwn => 'Это ваше собственное приглашение.';

  @override
  String get inviteUnreachable =>
      'Не удалось связаться с другим устройством. Вы в одной сети, и Chirp открыт?';

  @override
  String get inviteAlreadyContact => 'Этот человек уже в ваших контактах.';

  @override
  String get inviteProtocol =>
      'Другое устройство ответило что-то неожиданное. Попробуйте новое приглашение.';

  @override
  String get safetyNumberTitle => 'Код безопасности';

  @override
  String safetyNumberHelp(String name) {
    return 'Сравните эти числа с собеседником ($name) лично или по телефону. Если они совпадают, никто не вклинился в ваш разговор.';
  }

  @override
  String get markVerified => 'Отметить как проверенный';

  @override
  String get networkUnavailable => 'Локальная сеть не запустилась.';

  @override
  String get messageHint => 'Сообщение';

  @override
  String get send => 'Отправить';

  @override
  String get nudge => 'Привлечь внимание';

  @override
  String nudgeSent(String name) {
    return 'Вы привлекли внимание: $name';
  }

  @override
  String nudgeReceived(String name) {
    return '$name привлекает ваше внимание';
  }

  @override
  String get nudgePreview => 'Привлекает внимание';

  @override
  String get typing => 'печатает…';

  @override
  String get messageDeleted => 'Сообщение удалено';

  @override
  String get messageEdited => 'изменено';

  @override
  String get statusPending => 'Ожидает доставки';

  @override
  String get statusDelivered => 'Доставлено';

  @override
  String get statusRead => 'Прочитано';

  @override
  String get you => 'Вы';

  @override
  String get reply => 'Ответить';

  @override
  String replyingTo(String name) {
    return 'Ответ: $name';
  }

  @override
  String get quotedMissing => 'Сообщения нет на этом устройстве';

  @override
  String get editMessage => 'Изменить';

  @override
  String get editingMessage => 'Редактирование сообщения';

  @override
  String get copyText => 'Копировать текст';

  @override
  String get textCopied => 'Скопировано';

  @override
  String get deleteForMe => 'Удалить у меня';

  @override
  String get deleteForEveryone => 'Удалить у всех';

  @override
  String get reaction1 => 'Нравится';

  @override
  String get reaction2 => 'Обожаю';

  @override
  String get reaction3 => 'Смешно';

  @override
  String get reaction4 => 'Грустно';

  @override
  String get reaction5 => 'Спасибо';

  @override
  String get reaction6 => 'Ура';

  @override
  String get react => 'Реакция';

  @override
  String get contactDetails => 'Сведения о контакте';

  @override
  String get searchMessages => 'Поиск сообщений';

  @override
  String get searchNothing => 'Ничего не найдено';

  @override
  String get searchHelp =>
      'Слова из любой переписки, без учёта ударений и регистра.';

  @override
  String get messageTooSoon =>
      'Подождите несколько секунд, прежде чем повторить.';

  @override
  String get messageTooLate => 'Время на изменение этого сообщения истекло.';

  @override
  String get messageInvalid => 'Сообщение пустое или слишком длинное.';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count непрочитанного сообщения',
      many: '$count непрочитанных сообщений',
      few: '$count непрочитанных сообщения',
      one: '$count непрочитанное сообщение',
    );
    return '$_temp0';
  }

  @override
  String get chatSettingsTitle => 'Переписка';

  @override
  String get readReceipts => 'Отчёты о прочтении';

  @override
  String get readReceiptsHelp =>
      'Если выключить, вы тоже не увидите, когда прочитают ваши.';

  @override
  String get typingIndicator => 'Индикатор набора';

  @override
  String get typingIndicatorHelp =>
      'Если выключить, вы тоже не увидите, когда печатают другие.';

  @override
  String get messageOptions => 'Действия с сообщением';

  @override
  String get appearanceTitle => 'Оформление';

  @override
  String get appearanceMode => 'Светлая или тёмная';

  @override
  String get modeSystem => 'Как в системе';

  @override
  String get modeLight => 'Светлая';

  @override
  String get modeDark => 'Тёмная';

  @override
  String get themeLabel => 'Тема';

  @override
  String get appearanceNotSaved => 'Не удалось сохранить оформление.';

  @override
  String get themeLutino => 'Sunny Lutino';

  @override
  String get themeWildGrey => 'Wild Grey';

  @override
  String get themeSkylight => 'Skylight';

  @override
  String get themeOldDays => 'Old Days';

  @override
  String get themeHuman => 'Human';

  @override
  String get themeSymbian => 'Symbian';

  @override
  String get themeFoundation => 'Foundation';

  @override
  String get themeMightyCats => 'Mighty Cats';

  @override
  String get conversationPick => 'Выберите переписку';

  @override
  String get close => 'Закрыть';

  @override
  String get glassEffect => 'Эффект стекла';

  @override
  String get glassEffectHelp =>
      'Панели становятся полупрозрачными над тем, что прокручивается под ними. Выключен, если система просит меньше анимации или больше контраста.';

  @override
  String get themeSystem => 'Цвет системы';

  @override
  String get networkTitle => 'Сеть';

  @override
  String get networkLocalAlways =>
      'Локальная сеть всегда включена: кто в одной сети Wi-Fi, переписывается, и ничего не выходит наружу.';

  @override
  String get internetToggle => 'Интернет';

  @override
  String get internetHelp =>
      'Чтобы переписываться с теми, кто в другой сети. Ваши контакты получают ваш публичный адрес (IP), по которому видно провайдера и примерно город.';

  @override
  String get relaysTitle => 'Серверы-ретрансляторы';

  @override
  String get relaysHelp =>
      'Без него работают только прямые соединения, а многие сети (мобильные почти всегда) их не пропускают. Ретранслятор видит ваш IP, IP контактов и когда вы общаетесь, и пересылает уже зашифрованные сообщения, не читая и не храня их. Используйте свой или того, кому доверяете.';

  @override
  String get relayAddress => 'Адрес ретранслятора';

  @override
  String get relayAddressHelp => 'Начинается с https://';

  @override
  String get relayAdd => 'Добавить';

  @override
  String get relayRemove => 'Удалить';

  @override
  String get relayInvalid =>
      'Этот адрес не подходит. Используйте адрес, начинающийся с https://, без имени и пароля, не больше трёх.';

  @override
  String get relayStatusNone => 'Без ретранслятора: только прямые соединения.';

  @override
  String get relayStatusConnected => 'Подключено к ретранслятору.';

  @override
  String get relayStatusWaiting => 'Ретранслятор пока не ответил.';

  @override
  String get reachTitle => 'Соединение';

  @override
  String get reachLan => 'В локальной сети';

  @override
  String get reachDirect => 'Через интернет, напрямую';

  @override
  String get reachRelay => 'Через ретранслятор';

  @override
  String get reachUnreachable => 'Сейчас недоступен';

  @override
  String get reachUnknown => 'Ещё не пробовали';

  @override
  String get unreachableLocalOnly =>
      'Недоступен в локальной сети. Если он в другой сети, включите интернет в разделе Ваш профиль, Сеть. Сообщения ждут здесь.';

  @override
  String get unreachableNoRelay =>
      'Не удалось подключиться напрямую. Без ретранслятора это работает, только если один из вас принимает входящие соединения, а многие сети (например, мобильные) этого не позволяют. Сообщения ждут здесь.';

  @override
  String get unreachableOffline =>
      'Похоже, контакт не в сети. Сообщения ждут здесь и уйдут, когда он появится.';

  @override
  String get attachFile => 'Прикрепить файл';

  @override
  String get fileDownload => 'Скачать';

  @override
  String get fileSave => 'Сохранить';

  @override
  String get fileRetry => 'Попробовать снова';

  @override
  String get fileSaved => 'Сохранено.';

  @override
  String get fileWaiting => 'Ожидание контакта';

  @override
  String get fileFailed =>
      'Файл пришёл не таким, каким был отправлен, и удалён.';

  @override
  String get fileInvalid =>
      'Этот файл нельзя отправить: он больше 1 ГБ, не читается или это фото, из которого не удалось убрать метаданные.';

  @override
  String fileView(String name) {
    return 'Открыть фото $name';
  }

  @override
  String filePreview(String name) {
    return 'Файл: $name';
  }

  @override
  String fileProgress(int percent) {
    return '$percent %';
  }

  @override
  String sizeBytes(String size) {
    return '$size Б';
  }

  @override
  String sizeKb(String size) {
    return '$size КБ';
  }

  @override
  String sizeMb(String size) {
    return '$size МБ';
  }

  @override
  String sizeGb(String size) {
    return '$size ГБ';
  }

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsHelp =>
      'Что система показывает, когда приходит сообщение, а беседа не на экране.';

  @override
  String get notifyOff => 'Выключены';

  @override
  String get notifyHidden => 'Без содержания';

  @override
  String get notifyHiddenHelp =>
      'Только «Новое сообщение», без имени и текста.';

  @override
  String get notifySender => 'Только имя';

  @override
  String get notifySenderHelp => 'Кто написал, без текста.';

  @override
  String get notifyFull => 'Имя и сообщение';

  @override
  String get notifyFullHelp =>
      'Текст может появиться и на экране блокировки, если система это позволяет.';

  @override
  String get notificationNewMessage => 'Новое сообщение';

  @override
  String get notificationOpen => 'Открыть';

  @override
  String get notificationChannel => 'Сообщения';

  @override
  String get backgroundTitle => 'В фоне';

  @override
  String get keepRunning => 'Получать сообщения при закрытом окне';

  @override
  String get keepRunningHelp =>
      'Psito Chirp остаётся в системном трее. Чтобы выйти совсем, выберите «Выйти» в его меню.';

  @override
  String get startAtLogin => 'Открывать при входе в систему';

  @override
  String get startAtLoginHelp => 'Запускается скрытым, в трее.';

  @override
  String trayOpen(String name) {
    return 'Открыть $name';
  }

  @override
  String get trayQuit => 'Выйти';

  @override
  String get keepRunningHelpMobile =>
      'Пока Psito Chirp получает сообщения, остаётся неброское уведомление.';

  @override
  String get receivingNow => 'Получение сообщений';

  @override
  String get batteryTitle => 'Экономия заряда';

  @override
  String get batteryHelp =>
      'Когда телефон не используется, Android может задерживать сообщения. Если исключить Psito Chirp из экономии, этого не будет, но расход заряда немного вырастет.';

  @override
  String get batteryAllow => 'Исключить';

  @override
  String get downloadsTitle => 'Загрузки';

  @override
  String get downloadsHelp =>
      'Файлы до этого размера загружаются сразу, как приходят. Более крупные ждут, пока вы нажмёте «Скачать».';

  @override
  String get autoDownloadNever => 'Никогда сами';

  @override
  String get autoDownloadSmall => 'До 4 МБ';

  @override
  String get autoDownloadMedium => 'До 32 МБ';

  @override
  String get autoDownloadLarge => 'До 256 МБ';

  @override
  String get onlyVerified => 'Только от проверенных контактов';

  @override
  String get onlyVerifiedHelp =>
      'От контактов, чей код безопасности вы не сверили, все файлы ждут.';

  @override
  String get voiceRecord => 'Записать голосовое сообщение';

  @override
  String get voiceRecording => 'Идёт запись';

  @override
  String get voiceDiscard => 'Отменить';

  @override
  String get voiceSend => 'Отправить голосовое сообщение';

  @override
  String get voiceNote => 'Голосовое сообщение';

  @override
  String get voicePlay => 'Прослушать голосовое сообщение';

  @override
  String get voiceStop => 'Остановить';

  @override
  String get voicePreview => 'Голосовое сообщение';

  @override
  String get voiceTooShort => 'Слишком коротко: запишите чуть дольше.';

  @override
  String get audioUnavailable =>
      'Нет микрофона или динамика, или система не разрешила их использовать.';

  @override
  String get microphoneDenied =>
      'Psito Chirp нужен микрофон для записи. Разрешить можно в настройках системы.';

  @override
  String get emptyShowCode => 'Показать мой код';

  @override
  String get emptyShowCodeBody =>
      'Вы рядом? Другой человек сканирует QR. Так надёжнее всего: вы сразу проверены.';

  @override
  String get emptyUseLink => 'Использовать ссылку-приглашение';

  @override
  String get emptyUseLinkBody =>
      'Далеко? Отправьте ссылку как угодно или вставьте полученную. Она действует один раз, 24 часа.';

  @override
  String get emptyPromise => 'Без аккаунта, без номера телефона, без журналов.';

  @override
  String get contactsWillAppear => 'Здесь появятся ваши контакты';

  @override
  String get filterAll => 'Все';

  @override
  String get filterUnread => 'Непрочитанные';

  @override
  String get filterVerified => 'Проверенные';

  @override
  String get filterEmpty => 'С этим фильтром ничего нет.';

  @override
  String groupReachable(int count) {
    return 'В СЕТИ · $count';
  }

  @override
  String groupUnreachable(int count) {
    return 'НЕДОСТУПНЫ · $count';
  }

  @override
  String sayHi(String name) {
    return 'Поздоровайтесь с $name';
  }

  @override
  String get sayHiUnverified =>
      'Вы ещё не сверили код безопасности. Общаться можно, но сверьте его при встрече.';

  @override
  String get e2eVerified =>
      'Сквозное шифрование. Вы сверили код безопасности лично.';

  @override
  String get e2eUnverified =>
      'Сквозное шифрование. Сверьте код безопасности при встрече.';

  @override
  String get checkCode => 'Сверить код';

  @override
  String get inviteValidity => 'Действует один раз, 24 часа';

  @override
  String get pasteStep1 =>
      'Попросите ссылку у другого человека там, где вы уже общаетесь.';

  @override
  String get pasteStep2 =>
      'Вставьте её сюда. Chirp найдёт человека в локальной сети или в интернете, если он включён.';

  @override
  String get pasteStep3 =>
      'Контакт будет непроверенным: сверьте код безопасности при встрече.';

  @override
  String get pasteTip =>
      'Ссылка действует один раз и истекает через 24 часа. Не публикуйте её.';
}

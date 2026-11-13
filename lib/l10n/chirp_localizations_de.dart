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
  String get loading => 'Chirp wird geöffnet';

  @override
  String get nameLabel => 'Dein Name';

  @override
  String get nameHelp => 'Nur deine Kontakte sehen ihn, und nur verschlüsselt.';

  @override
  String get nameInvalid =>
      'Gib einen Namen mit höchstens 64 Zeichen in einer Zeile ein.';

  @override
  String get onboardingCreate => 'Mein Profil erstellen';

  @override
  String get passphraseCreateTitle => 'Schütze Chirp mit einer Passphrase';

  @override
  String get passphraseCreateBody =>
      'Dieses System hat keinen Schlüsselbund, in dem Chirp seinen Schlüssel ablegen kann. Deine Daten werden daher mit einer Passphrase gesperrt. Wenn du sie vergisst, lässt sie sich nicht wiederherstellen.';

  @override
  String get passphraseUnlockTitle => 'Chirp entsperren';

  @override
  String get passphraseLabel => 'Passphrase';

  @override
  String get passphraseConfirmLabel => 'Passphrase wiederholen';

  @override
  String get passphraseShow => 'Passphrase anzeigen';

  @override
  String get passphraseHide => 'Passphrase verbergen';

  @override
  String passphraseTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verwende mindestens $count Zeichen.',
      one: 'Verwende mindestens $count Zeichen.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseMismatch => 'Die Passphrasen stimmen nicht überein.';

  @override
  String get passphraseWrong => 'Diese Passphrase öffnet Chirp nicht.';

  @override
  String get passphraseCreate => 'Mit dieser Passphrase sperren';

  @override
  String get passphraseUnlock => 'Entsperren';

  @override
  String get passphraseForgot => 'Ich habe die Passphrase vergessen';

  @override
  String get problemCoreBody =>
      'Die Dateien der App sind vielleicht unvollständig. Installiere Chirp neu.';

  @override
  String get problemVaultTitle => 'Der Schlüsselbund hat nicht geantwortet';

  @override
  String get problemVaultBody =>
      'Chirp bewahrt seinen Schlüssel im Schlüsselbund des Systems auf, und der hat nicht geantwortet. Entsperre ihn und versuche es noch einmal.';

  @override
  String get problemKeyLostTitle => 'Der Schlüssel zu deinen Daten ist weg';

  @override
  String get problemKeyLostBody =>
      'Deine Daten sind noch auf diesem Gerät, aber der Schlüssel, der sie öffnet, ist nicht mehr im Schlüsselbund des Systems. Ohne ihn lässt sich nichts lesen. Du kannst alles löschen und neu anfangen.';

  @override
  String get problemNewerTitle => 'Diese Daten stammen von einem neueren Chirp';

  @override
  String get problemNewerBody => 'Aktualisiere Chirp, um sie zu öffnen.';

  @override
  String get problemStorageTitle => 'Chirp konnte seine Daten nicht öffnen';

  @override
  String get problemStorageBody =>
      'Beim Lesen des Datenträgers ist etwas schiefgegangen. Versuche es noch einmal; wenn es wieder passiert, kannst du alles löschen und neu anfangen.';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get eraseEverything => 'Alles löschen und neu anfangen';

  @override
  String get eraseTitle => 'Alles löschen?';

  @override
  String get eraseBody =>
      'Dein Profil, dein Schlüssel und alles, was Chirp auf diesem Gerät aufbewahrt, sind dann für immer weg.';

  @override
  String get eraseConfirm => 'Löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get renameTooltip => 'Namen ändern';

  @override
  String get renameTitle => 'Ändere deinen Namen';

  @override
  String get profileKeyLabel => 'Dein Schlüssel';

  @override
  String get profileKeyHelp =>
      'Deine Kontakte vergleichen diese Nummer, um zu wissen, dass du es wirklich bist.';

  @override
  String get somethingWentWrong =>
      'Etwas ist schiefgegangen. Versuche es noch einmal.';

  @override
  String get profileTitle => 'Dein Profil';

  @override
  String get addContact => 'Kontakt hinzufügen';

  @override
  String get contactsEmptyTitle => 'Noch niemand hier';

  @override
  String get contactsEmptyBody =>
      'Zum Schreiben tauscht ihr Einladungen. Nachrichten gehen direkt von Gerät zu Gerät, verschlüsselt, ohne Server dazwischen.';

  @override
  String get contactPending => 'Warte auf das andere Gerät';

  @override
  String get contactVerified => 'Verifiziert';

  @override
  String get contactUnverified => 'Nicht verifiziert';

  @override
  String get contactUnnamed => 'Noch ohne Namen';

  @override
  String contactAdded(String name) {
    return '$name ist jetzt ein Kontakt.';
  }

  @override
  String get inviteTabShow => 'Mein Code';

  @override
  String get inviteTabPaste => 'Einladung einfügen';

  @override
  String get inviteQrLabel => 'Einladungscode als QR';

  @override
  String get inviteQrHelp =>
      'Lass die andere Person diesen Code scannen oder schick ihr den Link. Jeder Code gilt einmal, 24 Stunden lang.';

  @override
  String get inviteCopyLink => 'Einladungslink kopieren';

  @override
  String get inviteLinkCopied =>
      'Link kopiert. Schick ihn über einen Weg, dem du vertraust: Er gilt einmal, 24 Stunden lang.';

  @override
  String get inviteNewCode => 'Neuer Code';

  @override
  String get pasteLabel => 'Einladungslink';

  @override
  String get pasteHelp => 'Beginnt mit chirp://invite';

  @override
  String get pasteAdd => 'Hinzufügen';

  @override
  String get pasteConnecting => 'Verbinde';

  @override
  String get qrScanLater =>
      'Das Lesen des Codes mit der Kamera kommt in einer späteren Version. Füge vorerst den Link ein.';

  @override
  String get inviteInvalid =>
      'Das ist keine Chirp-Einladung, oder ein Teil fehlt.';

  @override
  String get inviteRefused =>
      'Diese Einladung ist abgelaufen oder wurde schon benutzt. Bitte um eine neue.';

  @override
  String get inviteOwn => 'Das ist deine eigene Einladung.';

  @override
  String get inviteUnreachable =>
      'Das andere Gerät war nicht erreichbar. Seid ihr im selben Netz, mit geöffnetem Chirp?';

  @override
  String get inviteAlreadyContact => 'Diese Person ist schon ein Kontakt.';

  @override
  String get inviteProtocol =>
      'Das andere Gerät hat etwas Unerwartetes geantwortet. Versuch eine neue Einladung.';

  @override
  String get safetyNumberTitle => 'Sicherheitsnummer';

  @override
  String safetyNumberHelp(String name) {
    return 'Vergleiche diese Zahlen mit $name, persönlich oder bei einem Anruf. Stimmen sie überein, sitzt niemand in der Mitte eures Gesprächs.';
  }

  @override
  String get markVerified => 'Als verifiziert markieren';

  @override
  String get networkUnavailable => 'Das lokale Netz ist nicht gestartet.';

  @override
  String get messageHint => 'Nachricht';

  @override
  String get send => 'Senden';

  @override
  String get nudge => 'Anstupsen';

  @override
  String nudgeSent(String name) {
    return 'Du hast $name angestupst';
  }

  @override
  String nudgeReceived(String name) {
    return '$name hat dich angestupst';
  }

  @override
  String get nudgePreview => 'Hat angestupst';

  @override
  String get typing => 'schreibt…';

  @override
  String get messageDeleted => 'Diese Nachricht wurde gelöscht';

  @override
  String get messageEdited => 'bearbeitet';

  @override
  String get statusPending => 'Wartet auf Zustellung';

  @override
  String get statusDelivered => 'Zugestellt';

  @override
  String get statusRead => 'Gelesen';

  @override
  String get you => 'Du';

  @override
  String get reply => 'Antworten';

  @override
  String replyingTo(String name) {
    return 'Antwort an $name';
  }

  @override
  String get quotedMissing => 'Nachricht nicht auf diesem Gerät';

  @override
  String get editMessage => 'Bearbeiten';

  @override
  String get editingMessage => 'Nachricht bearbeiten';

  @override
  String get copyText => 'Text kopieren';

  @override
  String get textCopied => 'Kopiert';

  @override
  String get deleteForMe => 'Für mich löschen';

  @override
  String get deleteForEveryone => 'Für alle löschen';

  @override
  String get reaction1 => 'Gefällt mir';

  @override
  String get reaction2 => 'Liebe ich';

  @override
  String get reaction3 => 'Lustig';

  @override
  String get reaction4 => 'Traurig';

  @override
  String get reaction5 => 'Danke';

  @override
  String get reaction6 => 'Feiern';

  @override
  String get react => 'Reagieren';

  @override
  String get contactDetails => 'Kontaktdetails';

  @override
  String get searchMessages => 'Nachrichten suchen';

  @override
  String get searchNothing => 'Nichts gefunden';

  @override
  String get searchHelp =>
      'Wörter aus jeder Unterhaltung, ohne Rücksicht auf Akzente und Großschreibung.';

  @override
  String get messageTooSoon =>
      'Warte ein paar Sekunden, bevor du das wieder tust.';

  @override
  String get messageTooLate =>
      'Die Frist zum Ändern dieser Nachricht ist abgelaufen.';

  @override
  String get messageInvalid => 'Die Nachricht ist leer oder zu lang.';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ungelesene Nachrichten',
      one: '$count ungelesene Nachricht',
    );
    return '$_temp0';
  }

  @override
  String get chatSettingsTitle => 'Unterhaltungen';

  @override
  String get readReceipts => 'Lesebestätigungen';

  @override
  String get readReceiptsHelp =>
      'Wenn aus, siehst du auch nicht, wann deine gelesen werden.';

  @override
  String get typingIndicator => 'Tippanzeige';

  @override
  String get typingIndicatorHelp =>
      'Wenn aus, siehst du auch nicht, wann andere tippen.';

  @override
  String get messageOptions => 'Nachrichtenoptionen';

  @override
  String get appearanceTitle => 'Darstellung';

  @override
  String get appearanceMode => 'Hell oder dunkel';

  @override
  String get modeSystem => 'System';

  @override
  String get modeLight => 'Hell';

  @override
  String get modeDark => 'Dunkel';

  @override
  String get themeLabel => 'Design';

  @override
  String get appearanceNotSaved =>
      'Die Darstellung konnte nicht gespeichert werden.';

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
  String get conversationPick => 'Wähle eine Unterhaltung';

  @override
  String get close => 'Schließen';

  @override
  String get glassEffect => 'Glaseffekt';

  @override
  String get glassEffectHelp =>
      'Die Leisten werden über dem, was darunter scrollt, durchscheinend. Aus, wenn das System weniger Bewegung oder mehr Kontrast verlangt.';

  @override
  String get themeSystem => 'Systemfarbe';

  @override
  String get networkTitle => 'Netzwerk';

  @override
  String get networkLocalAlways =>
      'Das lokale Netzwerk ist immer an: Wer im selben WLAN ist, schreibt, ohne dass etwas hinausgeht.';

  @override
  String get internetToggle => 'Internet';

  @override
  String get internetHelp =>
      'Um mit Leuten in anderen Netzen zu schreiben. Deine Kontakte erhalten deine öffentliche Adresse (die IP), die deinen Anbieter und ungefähr deine Stadt zeigt.';

  @override
  String get relaysTitle => 'Relay-Server';

  @override
  String get relaysHelp =>
      'Ohne einen gehen nur direkte Verbindungen, und viele Netze (Mobilfunk fast immer) lassen sie nicht zu. Der Relay sieht deine IP, die deiner Kontakte und wann ihr schreibt, und leitet die schon verschlüsselten Nachrichten weiter, ohne sie zu lesen oder zu speichern. Nimm deinen eigenen oder einen von jemandem, dem du vertraust.';

  @override
  String get relayAddress => 'Relay-Adresse';

  @override
  String get relayAddressHelp => 'Beginnt mit https://';

  @override
  String get relayAdd => 'Hinzufügen';

  @override
  String get relayRemove => 'Entfernen';

  @override
  String get relayInvalid =>
      'Diese Adresse geht nicht. Nimm eine, die mit https:// beginnt, ohne Benutzer oder Passwort, höchstens drei.';

  @override
  String get relayStatusNone => 'Kein Relay: nur direkte Verbindungen.';

  @override
  String get relayStatusConnected => 'Mit dem Relay verbunden.';

  @override
  String get relayStatusWaiting => 'Der Relay hat noch nicht geantwortet.';

  @override
  String get bluetoothToggle => 'Bluetooth';

  @override
  String get bluetoothHelp =>
      'Um mit Kontakten in der Nähe zu sprechen, bis zu einigen zehn Metern, ganz ohne Netz. Solange es an ist, kann jeder, der in der Nähe sucht, erkennen, dass jemand mit Chirp da ist, aber nicht wer: Nur deine Kontakte erkennen dich. Verbraucht mehr Akku.';

  @override
  String get bluetoothUnavailable =>
      'Bluetooth wurde nicht gestartet. Prüfe, ob es im System eingeschaltet ist.';

  @override
  String get reachTitle => 'Verbindung';

  @override
  String get reachLan => 'Im lokalen Netzwerk';

  @override
  String get reachDirect => 'Über das Internet, direkt';

  @override
  String get reachRelay => 'Über den Relay';

  @override
  String get reachUnreachable => 'Gerade nicht erreichbar';

  @override
  String get reachUnknown => 'Noch nicht versucht';

  @override
  String get reachBluetooth => 'In der Nähe, über Bluetooth';

  @override
  String get unreachableLocalOnly =>
      'Im lokalen Netzwerk nicht erreichbar. Ist die Person in einem anderen Netz, schalte das Internet unter Dein Profil, Netzwerk ein. Die Nachrichten warten hier.';

  @override
  String get unreachableNoRelay =>
      'Keine direkte Verbindung möglich. Ohne Relay-Server geht das nur, wenn einer von euch Verbindungen von außen annimmt, und viele Netze (etwa Mobilfunk) lassen das nicht zu. Die Nachrichten warten hier.';

  @override
  String get unreachableOffline =>
      'Der Kontakt scheint offline zu sein. Die Nachrichten warten hier und gehen raus, sobald er auftaucht.';

  @override
  String get attachFile => 'Datei anhängen';

  @override
  String get fileDownload => 'Herunterladen';

  @override
  String get fileSave => 'Speichern';

  @override
  String get fileRetry => 'Erneut versuchen';

  @override
  String get fileSaved => 'Gespeichert.';

  @override
  String get fileWaiting => 'Wartet auf den Kontakt';

  @override
  String get fileFailed =>
      'Sie kam anders an als gesendet und wurde verworfen.';

  @override
  String get fileInvalid =>
      'Diese Datei kann nicht gesendet werden: Sie ist größer als 1 GB, nicht lesbar oder ein Foto, dessen Metadaten nicht entfernt werden konnten.';

  @override
  String fileView(String name) {
    return 'Foto $name öffnen';
  }

  @override
  String filePreview(String name) {
    return 'Datei: $name';
  }

  @override
  String fileProgress(int percent) {
    return '$percent %';
  }

  @override
  String sizeBytes(String size) {
    return '$size B';
  }

  @override
  String sizeKb(String size) {
    return '$size KB';
  }

  @override
  String sizeMb(String size) {
    return '$size MB';
  }

  @override
  String sizeGb(String size) {
    return '$size GB';
  }

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsHelp =>
      'Was das System zeigt, wenn eine Nachricht eintrifft und die Unterhaltung nicht auf dem Bildschirm ist.';

  @override
  String get notifyOff => 'Aus';

  @override
  String get notifyHidden => 'Ohne Inhalt';

  @override
  String get notifyHiddenHelp => 'Nur „Neue Nachricht“, ohne Namen und Text.';

  @override
  String get notifySender => 'Nur der Name';

  @override
  String get notifySenderHelp => 'Wer geschrieben hat, ohne den Text.';

  @override
  String get notifyFull => 'Name und Nachricht';

  @override
  String get notifyFullHelp =>
      'Der Text kann auch auf dem Sperrbildschirm erscheinen, wenn das System es erlaubt.';

  @override
  String get notificationNewMessage => 'Neue Nachricht';

  @override
  String get notificationOpen => 'Öffnen';

  @override
  String get notificationChannel => 'Nachrichten';

  @override
  String get backgroundTitle => 'Im Hintergrund';

  @override
  String get keepRunning => 'Bei geschlossenem Fenster weiter empfangen';

  @override
  String get keepRunningHelp =>
      'Psito Chirp bleibt im Infobereich. Zum endgültigen Beenden nutze Beenden in seinem Menü.';

  @override
  String get startAtLogin => 'Beim Anmelden öffnen';

  @override
  String get startAtLoginHelp => 'Es startet versteckt im Infobereich.';

  @override
  String trayOpen(String name) {
    return '$name öffnen';
  }

  @override
  String get trayQuit => 'Beenden';

  @override
  String get keepRunningHelpMobile =>
      'Eine unauffällige Benachrichtigung bleibt, solange Psito Chirp empfängt.';

  @override
  String get receivingNow => 'Nachrichten werden empfangen';

  @override
  String get batteryTitle => 'Energiesparen';

  @override
  String get batteryHelp =>
      'Wenn das Telefon ruht, kann Android Nachrichten verzögern. Psito Chirp vom Energiesparen auszunehmen verhindert das und braucht etwas mehr Akku.';

  @override
  String get batteryAllow => 'Ausnehmen';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsHelp =>
      'Dateien bis zu dieser Größe werden sofort beim Eintreffen geladen. Größere warten, bis du auf Herunterladen tippst.';

  @override
  String get autoDownloadNever => 'Nie automatisch';

  @override
  String get autoDownloadSmall => 'Bis 4 MB';

  @override
  String get autoDownloadMedium => 'Bis 32 MB';

  @override
  String get autoDownloadLarge => 'Bis 256 MB';

  @override
  String get onlyVerified => 'Nur von verifizierten Kontakten';

  @override
  String get onlyVerifiedHelp =>
      'Von Kontakten, deren Sicherheitscode du nicht geprüft hast, wartet jede Datei.';

  @override
  String get voiceRecord => 'Sprachnachricht aufnehmen';

  @override
  String get voiceRecording => 'Aufnahme läuft';

  @override
  String get voiceDiscard => 'Verwerfen';

  @override
  String get voiceSend => 'Sprachnachricht senden';

  @override
  String get voiceNote => 'Sprachnachricht';

  @override
  String get voicePlay => 'Sprachnachricht abspielen';

  @override
  String get voiceStop => 'Stoppen';

  @override
  String get voicePreview => 'Sprachnachricht';

  @override
  String get voiceTooShort => 'Zu kurz: nimm etwas länger auf.';

  @override
  String get audioUnavailable =>
      'Kein Mikrofon oder Lautsprecher, oder das System hat die Nutzung nicht erlaubt.';

  @override
  String get microphoneDenied =>
      'Psito Chirp braucht das Mikrofon zum Aufnehmen. Du kannst es in den Systemeinstellungen erlauben.';

  @override
  String get emptyShowCode => 'Meinen Code zeigen';

  @override
  String get emptyShowCodeBody =>
      'Zusammen? Die andere Person scannt den QR-Code. Am sichersten: Ihr seid gleich verifiziert.';

  @override
  String get emptyUseLink => 'Einladungslink nutzen';

  @override
  String get emptyUseLinkBody =>
      'Weit weg? Schick deinen Link, wie du willst, oder füge den erhaltenen ein. Er gilt einmal, 24 Stunden lang.';

  @override
  String get emptyPromise =>
      'Kein Konto, keine Telefonnummer, keine Protokolle.';

  @override
  String get contactsWillAppear => 'Deine Kontakte erscheinen hier';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterUnread => 'Ungelesen';

  @override
  String get filterVerified => 'Verifiziert';

  @override
  String get filterEmpty => 'Nichts mit diesem Filter.';

  @override
  String groupReachable(int count) {
    return 'ERREICHBAR · $count';
  }

  @override
  String groupUnreachable(int count) {
    return 'NICHT ERREICHBAR · $count';
  }

  @override
  String sayHi(String name) {
    return 'Sag $name Hallo';
  }

  @override
  String get sayHiUnverified =>
      'Ihr habt den Sicherheitscode noch nicht geprüft. Ihr könnt schreiben, aber prüft ihn, wenn ihr euch seht.';

  @override
  String get e2eVerified =>
      'Ende-zu-Ende-verschlüsselt. Ihr habt den Sicherheitscode persönlich geprüft.';

  @override
  String get e2eUnverified =>
      'Ende-zu-Ende-verschlüsselt. Prüft den Sicherheitscode, wenn ihr euch seht.';

  @override
  String get checkCode => 'Code prüfen';

  @override
  String get inviteValidity => 'Gilt einmal, 24 Stunden lang';

  @override
  String get pasteStep1 =>
      'Bitte die andere Person um den Link, dort, wo ihr schon schreibt.';

  @override
  String get pasteStep2 =>
      'Füge ihn hier ein. Chirp sucht im lokalen Netz, oder im Internet, wenn es an ist.';

  @override
  String get pasteStep3 =>
      'Der Kontakt kommt unverifiziert: Prüft den Sicherheitscode, wenn ihr euch seht.';

  @override
  String get pasteTip =>
      'Der Link gilt nur einmal und läuft nach 24 Stunden ab. Stell ihn nicht öffentlich.';

  @override
  String get statusInMailbox => 'Wartet in ihrem Postfach';

  @override
  String get mailboxTitle => 'Postfach';

  @override
  String get mailboxHelp =>
      'Ein Postfach ist ein kleiner Server von dir oder von jemandem, dem du vertraust. Es bewahrt auf, was deine Kontakte schicken, während dieses Gerät aus ist, bis du Chirp öffnest. Nachrichten kommen dort bereits verschlüsselt an: Es sieht, wer etwas hinterlegt und wann, nie was. Dateien brauchen weiterhin euch beide online.';

  @override
  String get mailboxCode => 'Postfach-Code';

  @override
  String get mailboxCodeHelp =>
      'Führe chirp-mailbox pair auf dem Server aus und füge den angezeigten Code ein. Er gilt einmal, 24 Stunden lang.';

  @override
  String get mailboxPair => 'Verbinden';

  @override
  String get mailboxPaired => 'Postfach verbunden';

  @override
  String get mailboxStatusWaiting => 'Noch nicht abgerufen.';

  @override
  String mailboxStatusChecked(String time) {
    return 'Zuletzt abgerufen $time.';
  }

  @override
  String get mailboxStatusUnreachable =>
      'Das Postfach hat nicht geantwortet. Nachrichten an dich warten eventuell bei deinen Kontakten.';

  @override
  String get mailboxUnpair => 'Trennen';

  @override
  String get mailboxUnpairTitle => 'Postfach trennen?';

  @override
  String get mailboxUnpairBody =>
      'Was darin wartet, geht verloren, und deine Kontakte hinterlegen dort nichts mehr. Mit einem neuen Code kannst du es wieder verbinden.';

  @override
  String get mailboxInvalid =>
      'Dieser Code funktioniert nicht. Füge den ganzen chirp://mailbox#-Link ein.';

  @override
  String get mailboxRefused =>
      'Das Postfach hat den Code abgelehnt. Er gilt nur einmal und läuft nach 24 Stunden ab: Erzeuge einen neuen.';

  @override
  String get mailboxUnreachable =>
      'Das Postfach war nicht erreichbar. Ohne Internet funktioniert nur ein Postfach im lokalen Netz.';

  @override
  String get contactRequestLeft =>
      'Die Person war offline, deshalb wartet deine Anfrage in ihrem Postfach. Sie wird zum Kontakt, sobald sie Chirp öffnet.';

  @override
  String get photoTitle => 'Profilfoto';

  @override
  String get photoHelp =>
      'Nur Kontakte, denen du es erlaubst, sehen es, sonst niemand. Es wird quadratisch zugeschnitten und verlässt dieses Gerät ohne Standort oder andere Daten der Originaldatei.';

  @override
  String get photoChoose => 'Foto auswählen';

  @override
  String get photoChange => 'Foto ändern';

  @override
  String get photoRemove => 'Foto entfernen';

  @override
  String get photoWhoSees => 'Wer es sieht';

  @override
  String get photoEveryone => 'Alle meine Kontakte';

  @override
  String get photoChosen => 'Nur ausgewählte Kontakte';

  @override
  String get photoChosenHelp =>
      'Wähle sie auf der Seite des jeweiligen Kontakts aus.';

  @override
  String get photoNobody => 'Niemand';

  @override
  String get photoRevokeNote =>
      'Wenn du jemanden entfernst, verschwindet dein Foto aus seinem Chirp, aber er hat vielleicht schon eine Kopie gespeichert.';

  @override
  String get photoAllowed => 'Darf mein Foto sehen';

  @override
  String get photoAllowedHelp =>
      'Ausschalten entfernt dein Foto aus seinem Chirp.';

  @override
  String get groupNew => 'Neue Gruppe';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get groupPickMembers => 'Wer dabei ist';

  @override
  String get groupCreate => 'Erstellen';

  @override
  String get groupAdd => 'Hinzufügen';

  @override
  String get groupNoOneToAdd =>
      'Noch keine Kontakte zum Hinzufügen. Füge zuerst jemanden hinzu und hol ihn dann in die Gruppe.';

  @override
  String get groupHelp =>
      'Jedes Mitglied bekommt deine Nachrichten verschlüsselt, direkt von deinem Gerät, ohne Server. Mitglieder, die sich nicht kennen, werden über den Admin vorgestellt und sprechen dann direkt.';

  @override
  String get groupLabel => 'Gruppe';

  @override
  String get groupClosed => 'Du bist nicht mehr in dieser Gruppe.';

  @override
  String groupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Du und $count weitere',
      one: 'Du und $count weitere Person',
      zero: 'Nur du',
    );
    return '$_temp0';
  }

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupNotConnected =>
      'Wird über den Admin vorgestellt: deine Nachrichten erreichen diese Person, sobald das fertig ist';

  @override
  String get groupAddMembers => 'Mitglieder hinzufügen';

  @override
  String get groupRemove => 'Aus der Gruppe entfernen';

  @override
  String get groupRename => 'Gruppe umbenennen';

  @override
  String get groupLeave => 'Gruppe verlassen';

  @override
  String groupLeaveTitle(String name) {
    return '$name verlassen?';
  }

  @override
  String get groupLeaveBody =>
      'Die Mitglieder erfahren, dass du gegangen bist. Die Nachrichten bleiben hier, aber du kannst in dieser Gruppe nicht mehr schreiben oder empfangen.';

  @override
  String get groupNotAdmin => 'Nur der Gruppen-Admin kann das.';

  @override
  String get groupTooMany => 'Eine Gruppe hat höchstens 64 Mitglieder.';
}

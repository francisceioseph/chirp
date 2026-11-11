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
  String get contactsEmptyTitle => 'Noch keine Kontakte';

  @override
  String get contactsEmptyBody =>
      'Zeig deinen Code jemandem in der Nähe oder füge die Einladung ein, die man dir geschickt hat. Im selben Netz, ganz ohne Internet.';

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
  String get conversationEmpty => 'Noch keine Nachrichten. Sag hallo!';

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
}

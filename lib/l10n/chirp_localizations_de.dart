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
  String get homeNextPhase =>
      'Dein Profil und dein Schlüssel sind bereit. Gespräche kommen in der nächsten Phase.';

  @override
  String get somethingWentWrong =>
      'Etwas ist schiefgegangen. Versuche es noch einmal.';
}

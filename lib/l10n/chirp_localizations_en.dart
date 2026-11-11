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
  String get loading => 'Opening Chirp';

  @override
  String get nameLabel => 'Your name';

  @override
  String get nameHelp => 'Only your contacts will see it, and only encrypted.';

  @override
  String get nameInvalid => 'Enter a name of up to 64 characters, on one line.';

  @override
  String get onboardingCreate => 'Create my profile';

  @override
  String get passphraseCreateTitle => 'Protect Chirp with a passphrase';

  @override
  String get passphraseCreateBody =>
      'This system has no keychain where Chirp can keep its key, so your data will be locked with a passphrase. If you forget it, there is no way to recover it.';

  @override
  String get passphraseUnlockTitle => 'Unlock Chirp';

  @override
  String get passphraseLabel => 'Passphrase';

  @override
  String get passphraseConfirmLabel => 'Repeat the passphrase';

  @override
  String get passphraseShow => 'Show passphrase';

  @override
  String get passphraseHide => 'Hide passphrase';

  @override
  String passphraseTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use at least $count characters.',
      one: 'Use at least $count character.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseMismatch => 'The passphrases do not match.';

  @override
  String get passphraseWrong => 'That passphrase does not open Chirp.';

  @override
  String get passphraseCreate => 'Lock with this passphrase';

  @override
  String get passphraseUnlock => 'Unlock';

  @override
  String get passphraseForgot => 'I forgot the passphrase';

  @override
  String get problemCoreBody =>
      'The app\'s files may be incomplete. Install Chirp again.';

  @override
  String get problemVaultTitle => 'The keychain did not answer';

  @override
  String get problemVaultBody =>
      'Chirp keeps its key in the system keychain, and it did not answer. Unlock it and try again.';

  @override
  String get problemKeyLostTitle => 'The key to your data is gone';

  @override
  String get problemKeyLostBody =>
      'Your data is still on this device, but the key that opens it is no longer in the system keychain. Without it, nothing can be read. You can erase it and start over.';

  @override
  String get problemNewerTitle => 'This data is from a newer Chirp';

  @override
  String get problemNewerBody => 'Update Chirp to open it.';

  @override
  String get problemStorageTitle => 'Chirp could not open its data';

  @override
  String get problemStorageBody =>
      'Something went wrong while reading the disk. Try again; if it keeps happening, you can erase everything and start over.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get eraseEverything => 'Erase everything and start over';

  @override
  String get eraseTitle => 'Erase everything?';

  @override
  String get eraseBody =>
      'Your profile, your key and everything Chirp keeps on this device will be gone for good.';

  @override
  String get eraseConfirm => 'Erase';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get renameTooltip => 'Change name';

  @override
  String get renameTitle => 'Change your name';

  @override
  String get profileKeyLabel => 'Your key';

  @override
  String get profileKeyHelp =>
      'Your contacts compare this number to know it is really you.';

  @override
  String get homeNextPhase =>
      'Your profile and your key are ready. Conversations arrive in the next phase.';

  @override
  String get somethingWentWrong => 'Something went wrong. Try again.';
}

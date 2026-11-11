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
  String get somethingWentWrong => 'Something went wrong. Try again.';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get addContact => 'Add contact';

  @override
  String get contactsEmptyTitle => 'No contacts yet';

  @override
  String get contactsEmptyBody =>
      'Show your code to someone nearby, or paste the invite they sent you. On the same network, no internet needed.';

  @override
  String get contactPending => 'Waiting for the other device';

  @override
  String get contactVerified => 'Verified';

  @override
  String get contactUnverified => 'Not verified';

  @override
  String get contactUnnamed => 'No name yet';

  @override
  String contactAdded(String name) {
    return '$name is now a contact.';
  }

  @override
  String get inviteTabShow => 'My code';

  @override
  String get inviteTabPaste => 'Paste invite';

  @override
  String get inviteQrLabel => 'Invite code, as a QR';

  @override
  String get inviteQrHelp =>
      'Let the other person scan this code, or send them the link. Each code works once, for 24 hours.';

  @override
  String get inviteCopyLink => 'Copy invite link';

  @override
  String get inviteLinkCopied =>
      'Link copied. Send it over a channel you trust: it works once, for 24 hours.';

  @override
  String get inviteNewCode => 'New code';

  @override
  String get pasteLabel => 'Invite link';

  @override
  String get pasteHelp => 'Starts with chirp://invite';

  @override
  String get pasteAdd => 'Add';

  @override
  String get pasteConnecting => 'Connecting';

  @override
  String get qrScanLater =>
      'Reading the code with the camera comes in a later version. For now, paste the link.';

  @override
  String get inviteInvalid =>
      'This is not a Chirp invite, or part of it is missing.';

  @override
  String get inviteRefused =>
      'This invite has expired or was already used. Ask for a new one.';

  @override
  String get inviteOwn => 'This is your own invite.';

  @override
  String get inviteUnreachable =>
      'Could not reach the other device. Are you both on the same network, with Chirp open?';

  @override
  String get inviteAlreadyContact => 'This person is already a contact.';

  @override
  String get inviteProtocol =>
      'The other device answered something unexpected. Try a new invite.';

  @override
  String get safetyNumberTitle => 'Safety number';

  @override
  String safetyNumberHelp(String name) {
    return 'Compare these numbers with $name, in person or on a call. If they match, nobody is in the middle of your conversation.';
  }

  @override
  String get markVerified => 'Mark as verified';

  @override
  String get networkUnavailable => 'The local network did not start.';
}

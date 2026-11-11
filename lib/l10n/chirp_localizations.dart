import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations_de.dart';
import 'chirp_localizations_en.dart';
import 'chirp_localizations_es.dart';
import 'chirp_localizations_fr.dart';
import 'chirp_localizations_pt.dart';
import 'chirp_localizations_ru.dart';
import 'chirp_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ChirpLocalizations
/// returned by `ChirpLocalizations.of(context)`.
///
/// Applications need to include `ChirpLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/chirp_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ChirpLocalizations.localizationsDelegates,
///   supportedLocales: ChirpLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ChirpLocalizations.supportedLocales
/// property.
abstract class ChirpLocalizations {
  ChirpLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ChirpLocalizations of(BuildContext context) {
    return Localizations.of<ChirpLocalizations>(context, ChirpLocalizations)!;
  }

  static const LocalizationsDelegate<ChirpLocalizations> delegate =
      _ChirpLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The app name, in the window title and the about box.
  ///
  /// In en, this message translates to:
  /// **'Psito Chirp'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations that stay between you'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'No accounts, no servers, no logs. Your messages live only on your devices.'**
  String get welcomeBody;

  /// No description provided for @coreVersion.
  ///
  /// In en, this message translates to:
  /// **'Core {version} · protocol {protocol}'**
  String coreVersion(String version, int protocol);

  /// No description provided for @coreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The secure core could not start.'**
  String get coreUnavailable;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Opening Chirp'**
  String get loading;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameLabel;

  /// No description provided for @nameHelp.
  ///
  /// In en, this message translates to:
  /// **'Only your contacts will see it, and only encrypted.'**
  String get nameHelp;

  /// No description provided for @nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name of up to 64 characters, on one line.'**
  String get nameInvalid;

  /// No description provided for @onboardingCreate.
  ///
  /// In en, this message translates to:
  /// **'Create my profile'**
  String get onboardingCreate;

  /// No description provided for @passphraseCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect Chirp with a passphrase'**
  String get passphraseCreateTitle;

  /// No description provided for @passphraseCreateBody.
  ///
  /// In en, this message translates to:
  /// **'This system has no keychain where Chirp can keep its key, so your data will be locked with a passphrase. If you forget it, there is no way to recover it.'**
  String get passphraseCreateBody;

  /// No description provided for @passphraseUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Chirp'**
  String get passphraseUnlockTitle;

  /// A long password that locks the local data when the system has no keychain.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphraseLabel;

  /// No description provided for @passphraseConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat the passphrase'**
  String get passphraseConfirmLabel;

  /// No description provided for @passphraseShow.
  ///
  /// In en, this message translates to:
  /// **'Show passphrase'**
  String get passphraseShow;

  /// No description provided for @passphraseHide.
  ///
  /// In en, this message translates to:
  /// **'Hide passphrase'**
  String get passphraseHide;

  /// No description provided for @passphraseTooShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Use at least {count} character.} other{Use at least {count} characters.}}'**
  String passphraseTooShort(int count);

  /// No description provided for @passphraseMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passphrases do not match.'**
  String get passphraseMismatch;

  /// No description provided for @passphraseWrong.
  ///
  /// In en, this message translates to:
  /// **'That passphrase does not open Chirp.'**
  String get passphraseWrong;

  /// No description provided for @passphraseCreate.
  ///
  /// In en, this message translates to:
  /// **'Lock with this passphrase'**
  String get passphraseCreate;

  /// No description provided for @passphraseUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get passphraseUnlock;

  /// No description provided for @passphraseForgot.
  ///
  /// In en, this message translates to:
  /// **'I forgot the passphrase'**
  String get passphraseForgot;

  /// No description provided for @problemCoreBody.
  ///
  /// In en, this message translates to:
  /// **'The app\'s files may be incomplete. Install Chirp again.'**
  String get problemCoreBody;

  /// No description provided for @problemVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'The keychain did not answer'**
  String get problemVaultTitle;

  /// No description provided for @problemVaultBody.
  ///
  /// In en, this message translates to:
  /// **'Chirp keeps its key in the system keychain, and it did not answer. Unlock it and try again.'**
  String get problemVaultBody;

  /// No description provided for @problemKeyLostTitle.
  ///
  /// In en, this message translates to:
  /// **'The key to your data is gone'**
  String get problemKeyLostTitle;

  /// No description provided for @problemKeyLostBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is still on this device, but the key that opens it is no longer in the system keychain. Without it, nothing can be read. You can erase it and start over.'**
  String get problemKeyLostBody;

  /// No description provided for @problemNewerTitle.
  ///
  /// In en, this message translates to:
  /// **'This data is from a newer Chirp'**
  String get problemNewerTitle;

  /// No description provided for @problemNewerBody.
  ///
  /// In en, this message translates to:
  /// **'Update Chirp to open it.'**
  String get problemNewerBody;

  /// No description provided for @problemStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Chirp could not open its data'**
  String get problemStorageTitle;

  /// No description provided for @problemStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading the disk. Try again; if it keeps happening, you can erase everything and start over.'**
  String get problemStorageBody;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @eraseEverything.
  ///
  /// In en, this message translates to:
  /// **'Erase everything and start over'**
  String get eraseEverything;

  /// No description provided for @eraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase everything?'**
  String get eraseTitle;

  /// No description provided for @eraseBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile, your key and everything Chirp keeps on this device will be gone for good.'**
  String get eraseBody;

  /// No description provided for @eraseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get eraseConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @renameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get renameTooltip;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Change your name'**
  String get renameTitle;

  /// Heading above the 30-digit fingerprint of the user's identity key.
  ///
  /// In en, this message translates to:
  /// **'Your key'**
  String get profileKeyLabel;

  /// No description provided for @profileKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Your contacts compare this number to know it is really you.'**
  String get profileKeyHelp;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get somethingWentWrong;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContact;

  /// No description provided for @contactsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactsEmptyTitle;

  /// No description provided for @contactsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Show your code to someone nearby, or paste the invite they sent you. On the same network, no internet needed.'**
  String get contactsEmptyBody;

  /// No description provided for @contactPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other device'**
  String get contactPending;

  /// No description provided for @contactVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get contactVerified;

  /// No description provided for @contactUnverified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get contactUnverified;

  /// No description provided for @contactUnnamed.
  ///
  /// In en, this message translates to:
  /// **'No name yet'**
  String get contactUnnamed;

  /// No description provided for @contactAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} is now a contact.'**
  String contactAdded(String name);

  /// No description provided for @inviteTabShow.
  ///
  /// In en, this message translates to:
  /// **'My code'**
  String get inviteTabShow;

  /// No description provided for @inviteTabPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste invite'**
  String get inviteTabPaste;

  /// No description provided for @inviteQrLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code, as a QR'**
  String get inviteQrLabel;

  /// No description provided for @inviteQrHelp.
  ///
  /// In en, this message translates to:
  /// **'Let the other person scan this code, or send them the link. Each code works once, for 24 hours.'**
  String get inviteQrHelp;

  /// No description provided for @inviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy invite link'**
  String get inviteCopyLink;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied. Send it over a channel you trust: it works once, for 24 hours.'**
  String get inviteLinkCopied;

  /// No description provided for @inviteNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get inviteNewCode;

  /// No description provided for @pasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite link'**
  String get pasteLabel;

  /// No description provided for @pasteHelp.
  ///
  /// In en, this message translates to:
  /// **'Starts with chirp://invite'**
  String get pasteHelp;

  /// No description provided for @pasteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get pasteAdd;

  /// No description provided for @pasteConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get pasteConnecting;

  /// No description provided for @qrScanLater.
  ///
  /// In en, this message translates to:
  /// **'Reading the code with the camera comes in a later version. For now, paste the link.'**
  String get qrScanLater;

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This is not a Chirp invite, or part of it is missing.'**
  String get inviteInvalid;

  /// No description provided for @inviteRefused.
  ///
  /// In en, this message translates to:
  /// **'This invite has expired or was already used. Ask for a new one.'**
  String get inviteRefused;

  /// No description provided for @inviteOwn.
  ///
  /// In en, this message translates to:
  /// **'This is your own invite.'**
  String get inviteOwn;

  /// No description provided for @inviteUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the other device. Are you both on the same network, with Chirp open?'**
  String get inviteUnreachable;

  /// No description provided for @inviteAlreadyContact.
  ///
  /// In en, this message translates to:
  /// **'This person is already a contact.'**
  String get inviteAlreadyContact;

  /// No description provided for @inviteProtocol.
  ///
  /// In en, this message translates to:
  /// **'The other device answered something unexpected. Try a new invite.'**
  String get inviteProtocol;

  /// No description provided for @safetyNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety number'**
  String get safetyNumberTitle;

  /// No description provided for @safetyNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'Compare these numbers with {name}, in person or on a call. If they match, nobody is in the middle of your conversation.'**
  String safetyNumberHelp(String name);

  /// No description provided for @markVerified.
  ///
  /// In en, this message translates to:
  /// **'Mark as verified'**
  String get markVerified;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The local network did not start.'**
  String get networkUnavailable;
}

class _ChirpLocalizationsDelegate
    extends LocalizationsDelegate<ChirpLocalizations> {
  const _ChirpLocalizationsDelegate();

  @override
  Future<ChirpLocalizations> load(Locale locale) {
    return SynchronousFuture<ChirpLocalizations>(
      lookupChirpLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_ChirpLocalizationsDelegate old) => false;
}

ChirpLocalizations lookupChirpLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return ChirpLocalizationsDe();
    case 'en':
      return ChirpLocalizationsEn();
    case 'es':
      return ChirpLocalizationsEs();
    case 'fr':
      return ChirpLocalizationsFr();
    case 'pt':
      return ChirpLocalizationsPt();
    case 'ru':
      return ChirpLocalizationsRu();
    case 'zh':
      return ChirpLocalizationsZh();
  }

  throw FlutterError(
    'ChirpLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

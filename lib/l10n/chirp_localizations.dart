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
  /// **'Nobody here yet'**
  String get contactsEmptyTitle;

  /// No description provided for @contactsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'To talk, swap invites. Messages go straight from one device to the other, encrypted, and never pass through a server.'**
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

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @nudge.
  ///
  /// In en, this message translates to:
  /// **'Get their attention'**
  String get nudge;

  /// No description provided for @nudgeSent.
  ///
  /// In en, this message translates to:
  /// **'You asked for {name}\'s attention'**
  String nudgeSent(String name);

  /// No description provided for @nudgeReceived.
  ///
  /// In en, this message translates to:
  /// **'{name} wants your attention'**
  String nudgeReceived(String name);

  /// No description provided for @nudgePreview.
  ///
  /// In en, this message translates to:
  /// **'Asked for attention'**
  String get nudgePreview;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get typing;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get messageDeleted;

  /// No description provided for @messageEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get messageEdited;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be delivered'**
  String get statusPending;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get statusRead;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @quotedMissing.
  ///
  /// In en, this message translates to:
  /// **'Message not on this device'**
  String get quotedMissing;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editMessage;

  /// No description provided for @editingMessage.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get editingMessage;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get textCopied;

  /// No description provided for @deleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get deleteForMe;

  /// No description provided for @deleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get deleteForEveryone;

  /// No description provided for @reaction1.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get reaction1;

  /// No description provided for @reaction2.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get reaction2;

  /// No description provided for @reaction3.
  ///
  /// In en, this message translates to:
  /// **'Funny'**
  String get reaction3;

  /// No description provided for @reaction4.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get reaction4;

  /// No description provided for @reaction5.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get reaction5;

  /// No description provided for @reaction6.
  ///
  /// In en, this message translates to:
  /// **'Celebrate'**
  String get reaction6;

  /// No description provided for @react.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get react;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get contactDetails;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessages;

  /// No description provided for @searchNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get searchNothing;

  /// No description provided for @searchHelp.
  ///
  /// In en, this message translates to:
  /// **'Words from any conversation, ignoring accents and case.'**
  String get searchHelp;

  /// No description provided for @messageTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Wait a few seconds before doing that again.'**
  String get messageTooSoon;

  /// No description provided for @messageTooLate.
  ///
  /// In en, this message translates to:
  /// **'The time to change this message is over.'**
  String get messageTooLate;

  /// No description provided for @messageInvalid.
  ///
  /// In en, this message translates to:
  /// **'The message is empty or too long.'**
  String get messageInvalid;

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} unread message} other{{count} unread messages}}'**
  String unreadCount(int count);

  /// No description provided for @chatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get chatSettingsTitle;

  /// No description provided for @readReceipts.
  ///
  /// In en, this message translates to:
  /// **'Read receipts'**
  String get readReceipts;

  /// No description provided for @readReceiptsHelp.
  ///
  /// In en, this message translates to:
  /// **'When off, you don\'t see when others read yours either.'**
  String get readReceiptsHelp;

  /// No description provided for @typingIndicator.
  ///
  /// In en, this message translates to:
  /// **'Typing indicator'**
  String get typingIndicator;

  /// No description provided for @typingIndicatorHelp.
  ///
  /// In en, this message translates to:
  /// **'When off, you don\'t see when others are typing either.'**
  String get typingIndicatorHelp;

  /// No description provided for @messageOptions.
  ///
  /// In en, this message translates to:
  /// **'Message options'**
  String get messageOptions;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// The group of light, dark and system buttons, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Light or dark'**
  String get appearanceMode;

  /// No description provided for @modeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get modeSystem;

  /// No description provided for @modeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get modeLight;

  /// No description provided for @modeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get modeDark;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @appearanceNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The appearance could not be saved.'**
  String get appearanceNotSaved;

  /// Theme names are proper names; keep them in every language.
  ///
  /// In en, this message translates to:
  /// **'Sunny Lutino'**
  String get themeLutino;

  /// No description provided for @themeWildGrey.
  ///
  /// In en, this message translates to:
  /// **'Wild Grey'**
  String get themeWildGrey;

  /// No description provided for @themeSkylight.
  ///
  /// In en, this message translates to:
  /// **'Skylight'**
  String get themeSkylight;

  /// No description provided for @themeOldDays.
  ///
  /// In en, this message translates to:
  /// **'Old Days'**
  String get themeOldDays;

  /// No description provided for @themeHuman.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get themeHuman;

  /// No description provided for @themeSymbian.
  ///
  /// In en, this message translates to:
  /// **'Symbian'**
  String get themeSymbian;

  /// No description provided for @themeFoundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get themeFoundation;

  /// No description provided for @themeMightyCats.
  ///
  /// In en, this message translates to:
  /// **'Mighty Cats'**
  String get themeMightyCats;

  /// No description provided for @conversationPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a conversation'**
  String get conversationPick;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @glassEffect.
  ///
  /// In en, this message translates to:
  /// **'Glass effect'**
  String get glassEffect;

  /// No description provided for @glassEffectHelp.
  ///
  /// In en, this message translates to:
  /// **'Bars become translucent over what scrolls beneath. Off when the system asks for less motion or more contrast.'**
  String get glassEffectHelp;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System color'**
  String get themeSystem;

  /// No description provided for @networkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkTitle;

  /// No description provided for @networkLocalAlways.
  ///
  /// In en, this message translates to:
  /// **'The local network is always on: people on the same Wi-Fi talk without anything leaving it.'**
  String get networkLocalAlways;

  /// No description provided for @internetToggle.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get internetToggle;

  /// No description provided for @internetHelp.
  ///
  /// In en, this message translates to:
  /// **'To talk with people on other networks. Your contacts get your public address (the IP), which shows your provider and roughly your city.'**
  String get internetHelp;

  /// No description provided for @relaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Relay servers'**
  String get relaysTitle;

  /// No description provided for @relaysHelp.
  ///
  /// In en, this message translates to:
  /// **'Without one, only direct connections work, and many networks (mobile ones, almost always) block them. A relay sees your IP, your contacts’ IPs and when you talk, and passes on messages already encrypted, without reading or keeping them. Use your own or one run by someone you trust.'**
  String get relaysHelp;

  /// No description provided for @relayAddress.
  ///
  /// In en, this message translates to:
  /// **'Relay address'**
  String get relayAddress;

  /// No description provided for @relayAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Starts with https://'**
  String get relayAddressHelp;

  /// No description provided for @relayAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get relayAdd;

  /// No description provided for @relayRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get relayRemove;

  /// No description provided for @relayInvalid.
  ///
  /// In en, this message translates to:
  /// **'That address does not work. Use one starting with https://, without user or password, up to three.'**
  String get relayInvalid;

  /// No description provided for @relayStatusNone.
  ///
  /// In en, this message translates to:
  /// **'No relay: direct connections only.'**
  String get relayStatusNone;

  /// No description provided for @relayStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to the relay.'**
  String get relayStatusConnected;

  /// No description provided for @relayStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'The relay has not answered yet.'**
  String get relayStatusWaiting;

  /// No description provided for @bluetoothToggle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get bluetoothToggle;

  /// No description provided for @bluetoothHelp.
  ///
  /// In en, this message translates to:
  /// **'To talk with contacts nearby, up to a few tens of meters, with no network at all. While it is on, anyone scanning nearby can tell that someone with Chirp is around, but not who: only your contacts recognize you. Uses more battery.'**
  String get bluetoothHelp;

  /// No description provided for @bluetoothUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth did not start. Check that it is on in the system.'**
  String get bluetoothUnavailable;

  /// No description provided for @reachTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get reachTitle;

  /// No description provided for @reachLan.
  ///
  /// In en, this message translates to:
  /// **'On the local network'**
  String get reachLan;

  /// No description provided for @reachDirect.
  ///
  /// In en, this message translates to:
  /// **'Over the internet, direct'**
  String get reachDirect;

  /// No description provided for @reachRelay.
  ///
  /// In en, this message translates to:
  /// **'Through the relay'**
  String get reachRelay;

  /// No description provided for @reachUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Out of reach right now'**
  String get reachUnreachable;

  /// No description provided for @reachUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not tried yet'**
  String get reachUnknown;

  /// No description provided for @reachBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Nearby, by Bluetooth'**
  String get reachBluetooth;

  /// No description provided for @unreachableLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Out of reach on the local network. If they are on another network, turn on the internet in Your profile, Network. Messages wait here.'**
  String get unreachableLocalOnly;

  /// No description provided for @unreachableNoRelay.
  ///
  /// In en, this message translates to:
  /// **'Could not connect directly. Without a relay server this only works if one of you accepts outside connections, and many networks (like mobile ones) do not. Messages wait here.'**
  String get unreachableNoRelay;

  /// No description provided for @unreachableOffline.
  ///
  /// In en, this message translates to:
  /// **'The contact seems to be offline. Messages wait here and go out when they show up.'**
  String get unreachableOffline;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get attachFile;

  /// No description provided for @fileDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get fileDownload;

  /// No description provided for @fileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get fileSave;

  /// No description provided for @fileRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get fileRetry;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get fileSaved;

  /// No description provided for @fileWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the contact'**
  String get fileWaiting;

  /// No description provided for @fileFailed.
  ///
  /// In en, this message translates to:
  /// **'It arrived different from what was sent, and was discarded.'**
  String get fileFailed;

  /// No description provided for @fileInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be sent: it is over 1 GB, cannot be read, or is a photo whose metadata could not be removed.'**
  String get fileInvalid;

  /// No description provided for @fileView.
  ///
  /// In en, this message translates to:
  /// **'Open the photo {name}'**
  String fileView(String name);

  /// No description provided for @filePreview.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String filePreview(String name);

  /// No description provided for @fileProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String fileProgress(int percent);

  /// No description provided for @sizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{size} B'**
  String sizeBytes(String size);

  /// No description provided for @sizeKb.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String sizeKb(String size);

  /// No description provided for @sizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMb(String size);

  /// No description provided for @sizeGb.
  ///
  /// In en, this message translates to:
  /// **'{size} GB'**
  String sizeGb(String size);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsHelp.
  ///
  /// In en, this message translates to:
  /// **'What the system shows when a message arrives and the conversation isn\'t on screen.'**
  String get notificationsHelp;

  /// No description provided for @notifyOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifyOff;

  /// No description provided for @notifyHidden.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get notifyHidden;

  /// No description provided for @notifyHiddenHelp.
  ///
  /// In en, this message translates to:
  /// **'Only \"New message\", without name or text.'**
  String get notifyHiddenHelp;

  /// No description provided for @notifySender.
  ///
  /// In en, this message translates to:
  /// **'Name only'**
  String get notifySender;

  /// No description provided for @notifySenderHelp.
  ///
  /// In en, this message translates to:
  /// **'Who wrote, without the text.'**
  String get notifySenderHelp;

  /// No description provided for @notifyFull.
  ///
  /// In en, this message translates to:
  /// **'Name and message'**
  String get notifyFull;

  /// No description provided for @notifyFullHelp.
  ///
  /// In en, this message translates to:
  /// **'The text can also show on the lock screen, if the system allows.'**
  String get notifyFullHelp;

  /// No description provided for @notificationNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notificationNewMessage;

  /// No description provided for @notificationOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationOpen;

  /// No description provided for @notificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationChannel;

  /// No description provided for @backgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'In the background'**
  String get backgroundTitle;

  /// No description provided for @keepRunning.
  ///
  /// In en, this message translates to:
  /// **'Keep receiving with the window closed'**
  String get keepRunning;

  /// No description provided for @keepRunningHelp.
  ///
  /// In en, this message translates to:
  /// **'Psito Chirp stays in the system tray. To quit for good, use Quit in its menu.'**
  String get keepRunningHelp;

  /// No description provided for @startAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Open when you sign in'**
  String get startAtLogin;

  /// No description provided for @startAtLoginHelp.
  ///
  /// In en, this message translates to:
  /// **'It starts hidden, in the tray.'**
  String get startAtLoginHelp;

  /// No description provided for @trayOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String trayOpen(String name);

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @keepRunningHelpMobile.
  ///
  /// In en, this message translates to:
  /// **'A quiet notification stays while Psito Chirp is receiving.'**
  String get keepRunningHelpMobile;

  /// No description provided for @receivingNow.
  ///
  /// In en, this message translates to:
  /// **'Receiving messages'**
  String get receivingNow;

  /// No description provided for @batteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery saving'**
  String get batteryTitle;

  /// No description provided for @batteryHelp.
  ///
  /// In en, this message translates to:
  /// **'With the phone idle, Android may delay messages. Keeping Psito Chirp out of battery saving avoids that, and uses a little more battery.'**
  String get batteryHelp;

  /// No description provided for @batteryAllow.
  ///
  /// In en, this message translates to:
  /// **'Keep it out'**
  String get batteryAllow;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsHelp.
  ///
  /// In en, this message translates to:
  /// **'Files up to this size download as soon as they arrive. Bigger ones wait for you to tap Download.'**
  String get downloadsHelp;

  /// No description provided for @autoDownloadNever.
  ///
  /// In en, this message translates to:
  /// **'Never on their own'**
  String get autoDownloadNever;

  /// No description provided for @autoDownloadSmall.
  ///
  /// In en, this message translates to:
  /// **'Up to 4 MB'**
  String get autoDownloadSmall;

  /// No description provided for @autoDownloadMedium.
  ///
  /// In en, this message translates to:
  /// **'Up to 32 MB'**
  String get autoDownloadMedium;

  /// No description provided for @autoDownloadLarge.
  ///
  /// In en, this message translates to:
  /// **'Up to 256 MB'**
  String get autoDownloadLarge;

  /// No description provided for @onlyVerified.
  ///
  /// In en, this message translates to:
  /// **'Only from verified contacts'**
  String get onlyVerified;

  /// No description provided for @onlyVerifiedHelp.
  ///
  /// In en, this message translates to:
  /// **'From contacts whose safety code you haven\'t checked, every file waits.'**
  String get onlyVerifiedHelp;

  /// No description provided for @voiceRecord.
  ///
  /// In en, this message translates to:
  /// **'Record a voice note'**
  String get voiceRecord;

  /// No description provided for @voiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get voiceRecording;

  /// No description provided for @voiceDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get voiceDiscard;

  /// No description provided for @voiceSend.
  ///
  /// In en, this message translates to:
  /// **'Send the voice note'**
  String get voiceSend;

  /// No description provided for @voiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get voiceNote;

  /// No description provided for @voicePlay.
  ///
  /// In en, this message translates to:
  /// **'Play the voice note'**
  String get voicePlay;

  /// No description provided for @voiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get voiceStop;

  /// No description provided for @voicePreview.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get voicePreview;

  /// No description provided for @voiceTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short: hold on a little longer.'**
  String get voiceTooShort;

  /// No description provided for @audioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No microphone or speaker, or the system didn\'t allow using it.'**
  String get audioUnavailable;

  /// No description provided for @microphoneDenied.
  ///
  /// In en, this message translates to:
  /// **'Psito Chirp needs the microphone to record. You can allow it in the system settings.'**
  String get microphoneDenied;

  /// No description provided for @emptyShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show my code'**
  String get emptyShowCode;

  /// No description provided for @emptyShowCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Together? The other person scans the QR. It\'s the safest way: you\'re verified from the start.'**
  String get emptyShowCodeBody;

  /// No description provided for @emptyUseLink.
  ///
  /// In en, this message translates to:
  /// **'Use an invite link'**
  String get emptyUseLink;

  /// No description provided for @emptyUseLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Far apart? Send your link however you like, or paste the one you got. It works once, for 24 hours.'**
  String get emptyUseLinkBody;

  /// No description provided for @emptyPromise.
  ///
  /// In en, this message translates to:
  /// **'No account, no phone number, no logs.'**
  String get emptyPromise;

  /// No description provided for @contactsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your contacts show up here'**
  String get contactsWillAppear;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// No description provided for @filterVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get filterVerified;

  /// No description provided for @filterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here with this filter.'**
  String get filterEmpty;

  /// No description provided for @groupReachable.
  ///
  /// In en, this message translates to:
  /// **'IN REACH · {count}'**
  String groupReachable(int count);

  /// No description provided for @groupUnreachable.
  ///
  /// In en, this message translates to:
  /// **'OUT OF REACH · {count}'**
  String groupUnreachable(int count);

  /// No description provided for @sayHi.
  ///
  /// In en, this message translates to:
  /// **'Say hi to {name}'**
  String sayHi(String name);

  /// No description provided for @sayHiUnverified.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t checked the safety code yet. You can talk, but check it when you meet.'**
  String get sayHiUnverified;

  /// No description provided for @e2eVerified.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted. You checked the safety code in person.'**
  String get e2eVerified;

  /// No description provided for @e2eUnverified.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted. Check the safety code when you meet.'**
  String get e2eUnverified;

  /// No description provided for @checkCode.
  ///
  /// In en, this message translates to:
  /// **'Check code'**
  String get checkCode;

  /// No description provided for @inviteValidity.
  ///
  /// In en, this message translates to:
  /// **'Works once, for 24 hours'**
  String get inviteValidity;

  /// No description provided for @pasteStep1.
  ///
  /// In en, this message translates to:
  /// **'Ask the other person for the link, wherever you already talk.'**
  String get pasteStep1;

  /// No description provided for @pasteStep2.
  ///
  /// In en, this message translates to:
  /// **'Paste it here. Chirp looks for them on the local network, or the internet if it\'s on.'**
  String get pasteStep2;

  /// No description provided for @pasteStep3.
  ///
  /// In en, this message translates to:
  /// **'They come in as unverified: check the safety code when you meet.'**
  String get pasteStep3;

  /// No description provided for @pasteTip.
  ///
  /// In en, this message translates to:
  /// **'The link works only once and expires in 24 hours. Don\'t leave it anywhere public.'**
  String get pasteTip;

  /// No description provided for @statusInMailbox.
  ///
  /// In en, this message translates to:
  /// **'Waiting in their mailbox'**
  String get statusInMailbox;

  /// No description provided for @mailboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get mailboxTitle;

  /// No description provided for @mailboxHelp.
  ///
  /// In en, this message translates to:
  /// **'A mailbox is a small server of your own, or of someone you trust, that keeps what your contacts send while this device is off, until you open Chirp. Messages arrive there already encrypted: it sees who leaves something and when, never what. Files still need you both online.'**
  String get mailboxHelp;

  /// No description provided for @mailboxCode.
  ///
  /// In en, this message translates to:
  /// **'Mailbox code'**
  String get mailboxCode;

  /// No description provided for @mailboxCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Run chirp-mailbox pair on the server and paste the code it shows. It works once, for 24 hours.'**
  String get mailboxCodeHelp;

  /// No description provided for @mailboxPair.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get mailboxPair;

  /// No description provided for @mailboxPaired.
  ///
  /// In en, this message translates to:
  /// **'Mailbox linked'**
  String get mailboxPaired;

  /// No description provided for @mailboxStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet.'**
  String get mailboxStatusWaiting;

  /// No description provided for @mailboxStatusChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked {time}.'**
  String mailboxStatusChecked(String time);

  /// No description provided for @mailboxStatusUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The mailbox did not answer. Messages for you may wait with your contacts.'**
  String get mailboxStatusUnreachable;

  /// No description provided for @mailboxUnpair.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get mailboxUnpair;

  /// No description provided for @mailboxUnpairTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink the mailbox?'**
  String get mailboxUnpairTitle;

  /// No description provided for @mailboxUnpairBody.
  ///
  /// In en, this message translates to:
  /// **'Whatever is waiting in it is lost, and your contacts stop leaving messages there. You can link it again with a new code.'**
  String get mailboxUnpairBody;

  /// No description provided for @mailboxInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code does not work. Paste the whole chirp://mailbox# link.'**
  String get mailboxInvalid;

  /// No description provided for @mailboxRefused.
  ///
  /// In en, this message translates to:
  /// **'The mailbox refused the code. It works only once and expires in 24 hours: make a new one.'**
  String get mailboxRefused;

  /// No description provided for @mailboxUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the mailbox. With the internet off, only a mailbox on the local network works.'**
  String get mailboxUnreachable;

  /// No description provided for @contactRequestLeft.
  ///
  /// In en, this message translates to:
  /// **'They were offline, so your request is waiting in their mailbox. They\'ll appear as a contact once they open Chirp.'**
  String get contactRequestLeft;

  /// No description provided for @photoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get photoTitle;

  /// No description provided for @photoHelp.
  ///
  /// In en, this message translates to:
  /// **'Only contacts you allow see it, never anyone else. It is made square and leaves this device without location or any other data from the original file.'**
  String get photoHelp;

  /// No description provided for @photoChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get photoChoose;

  /// No description provided for @photoChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get photoChange;

  /// No description provided for @photoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// No description provided for @photoWhoSees.
  ///
  /// In en, this message translates to:
  /// **'Who sees it'**
  String get photoWhoSees;

  /// No description provided for @photoEveryone.
  ///
  /// In en, this message translates to:
  /// **'All my contacts'**
  String get photoEveryone;

  /// No description provided for @photoChosen.
  ///
  /// In en, this message translates to:
  /// **'Only contacts I choose'**
  String get photoChosen;

  /// No description provided for @photoChosenHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose them on each contact\'s page.'**
  String get photoChosenHelp;

  /// No description provided for @photoNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get photoNobody;

  /// No description provided for @photoRevokeNote.
  ///
  /// In en, this message translates to:
  /// **'Taking someone off removes your photo from their Chirp, but they may already have saved a copy.'**
  String get photoRevokeNote;

  /// No description provided for @photoAllowed.
  ///
  /// In en, this message translates to:
  /// **'Can see my photo'**
  String get photoAllowed;

  /// No description provided for @photoAllowedHelp.
  ///
  /// In en, this message translates to:
  /// **'Turning this off removes your photo from their Chirp.'**
  String get photoAllowedHelp;

  /// No description provided for @groupNew.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get groupNew;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groupPickMembers.
  ///
  /// In en, this message translates to:
  /// **'Who is in it'**
  String get groupPickMembers;

  /// No description provided for @groupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get groupCreate;

  /// No description provided for @groupAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get groupAdd;

  /// No description provided for @groupNoOneToAdd.
  ///
  /// In en, this message translates to:
  /// **'No contacts to add yet. Add someone first, then bring them into the group.'**
  String get groupNoOneToAdd;

  /// No description provided for @groupHelp.
  ///
  /// In en, this message translates to:
  /// **'Each member gets your messages encrypted, straight from your device, with no server. Members who do not know each other are introduced through the admin, and then talk directly.'**
  String get groupHelp;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// No description provided for @groupClosed.
  ///
  /// In en, this message translates to:
  /// **'You are no longer in this group.'**
  String get groupClosed;

  /// No description provided for @groupMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Only you} one{You and {count} other} other{You and {count} others}}'**
  String groupMemberCount(int count);

  /// No description provided for @groupAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get groupAdmin;

  /// No description provided for @groupNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Being introduced through the admin: your messages reach them once that is done'**
  String get groupNotConnected;

  /// No description provided for @groupAddMembers.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get groupAddMembers;

  /// No description provided for @groupRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from the group'**
  String get groupRemove;

  /// No description provided for @groupRename.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get groupRename;

  /// No description provided for @groupLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get groupLeave;

  /// No description provided for @groupLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String groupLeaveTitle(String name);

  /// No description provided for @groupLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'The members are told you left. The messages stay here, but you can no longer write or receive in this group.'**
  String get groupLeaveBody;

  /// No description provided for @groupNotAdmin.
  ///
  /// In en, this message translates to:
  /// **'Only the group admin can do that.'**
  String get groupNotAdmin;

  /// No description provided for @groupTooMany.
  ///
  /// In en, this message translates to:
  /// **'A group has at most 64 members.'**
  String get groupTooMany;
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

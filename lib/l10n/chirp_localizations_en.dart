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
  String get contactsEmptyTitle => 'Nobody here yet';

  @override
  String get contactsEmptyBody =>
      'To talk, swap invites. Messages go straight from one device to the other, encrypted, and never pass through a server.';

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

  @override
  String get messageHint => 'Message';

  @override
  String get send => 'Send';

  @override
  String get nudge => 'Get their attention';

  @override
  String nudgeSent(String name) {
    return 'You asked for $name\'s attention';
  }

  @override
  String nudgeReceived(String name) {
    return '$name wants your attention';
  }

  @override
  String get nudgePreview => 'Asked for attention';

  @override
  String get typing => 'typing…';

  @override
  String get messageDeleted => 'This message was deleted';

  @override
  String get messageEdited => 'edited';

  @override
  String get statusPending => 'Waiting to be delivered';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusRead => 'Read';

  @override
  String get you => 'You';

  @override
  String get reply => 'Reply';

  @override
  String replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get quotedMissing => 'Message not on this device';

  @override
  String get editMessage => 'Edit';

  @override
  String get editingMessage => 'Editing message';

  @override
  String get copyText => 'Copy text';

  @override
  String get textCopied => 'Copied';

  @override
  String get deleteForMe => 'Delete for me';

  @override
  String get deleteForEveryone => 'Delete for everyone';

  @override
  String get reaction1 => 'Like';

  @override
  String get reaction2 => 'Love';

  @override
  String get reaction3 => 'Funny';

  @override
  String get reaction4 => 'Sad';

  @override
  String get reaction5 => 'Thanks';

  @override
  String get reaction6 => 'Celebrate';

  @override
  String get react => 'React';

  @override
  String get contactDetails => 'Contact details';

  @override
  String get searchMessages => 'Search messages';

  @override
  String get searchNothing => 'Nothing found';

  @override
  String get searchHelp =>
      'Words from any conversation, ignoring accents and case.';

  @override
  String get messageTooSoon => 'Wait a few seconds before doing that again.';

  @override
  String get messageTooLate => 'The time to change this message is over.';

  @override
  String get messageInvalid => 'The message is empty or too long.';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '$count unread message',
    );
    return '$_temp0';
  }

  @override
  String get chatSettingsTitle => 'Conversations';

  @override
  String get readReceipts => 'Read receipts';

  @override
  String get readReceiptsHelp =>
      'When off, you don\'t see when others read yours either.';

  @override
  String get typingIndicator => 'Typing indicator';

  @override
  String get typingIndicatorHelp =>
      'When off, you don\'t see when others are typing either.';

  @override
  String get messageOptions => 'Message options';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceMode => 'Light or dark';

  @override
  String get modeSystem => 'System';

  @override
  String get modeLight => 'Light';

  @override
  String get modeDark => 'Dark';

  @override
  String get themeLabel => 'Theme';

  @override
  String get appearanceNotSaved => 'The appearance could not be saved.';

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
  String get conversationPick => 'Pick a conversation';

  @override
  String get close => 'Close';

  @override
  String get glassEffect => 'Glass effect';

  @override
  String get glassEffectHelp =>
      'Bars become translucent over what scrolls beneath. Off when the system asks for less motion or more contrast.';

  @override
  String get themeSystem => 'System color';

  @override
  String get networkTitle => 'Network';

  @override
  String get networkLocalAlways =>
      'The local network is always on: people on the same Wi-Fi talk without anything leaving it.';

  @override
  String get internetToggle => 'Internet';

  @override
  String get internetHelp =>
      'To talk with people on other networks. Your contacts get your public address (the IP), which shows your provider and roughly your city.';

  @override
  String get relaysTitle => 'Relay servers';

  @override
  String get relaysHelp =>
      'Without one, only direct connections work, and many networks (mobile ones, almost always) block them. A relay sees your IP, your contacts’ IPs and when you talk, and passes on messages already encrypted, without reading or keeping them. Use your own or one run by someone you trust.';

  @override
  String get relayAddress => 'Relay address';

  @override
  String get relayAddressHelp => 'Starts with https://';

  @override
  String get relayAdd => 'Add';

  @override
  String get relayRemove => 'Remove';

  @override
  String get relayInvalid =>
      'That address does not work. Use one starting with https://, without user or password, up to three.';

  @override
  String get relayStatusNone => 'No relay: direct connections only.';

  @override
  String get relayStatusConnected => 'Connected to the relay.';

  @override
  String get relayStatusWaiting => 'The relay has not answered yet.';

  @override
  String get bluetoothToggle => 'Bluetooth';

  @override
  String get bluetoothHelp =>
      'To talk with contacts nearby, up to a few tens of meters, with no network at all. While it is on, anyone scanning nearby can tell that someone with Chirp is around, but not who: only your contacts recognize you. Uses more battery.';

  @override
  String get bluetoothUnavailable =>
      'Bluetooth did not start. Check that it is on in the system.';

  @override
  String get reachTitle => 'Connection';

  @override
  String get reachLan => 'On the local network';

  @override
  String get reachDirect => 'Over the internet, direct';

  @override
  String get reachRelay => 'Through the relay';

  @override
  String get reachUnreachable => 'Out of reach right now';

  @override
  String get reachUnknown => 'Not tried yet';

  @override
  String get reachBluetooth => 'Nearby, by Bluetooth';

  @override
  String get unreachableLocalOnly =>
      'Out of reach on the local network. If they are on another network, turn on the internet in Your profile, Network. Messages wait here.';

  @override
  String get unreachableNoRelay =>
      'Could not connect directly. Without a relay server this only works if one of you accepts outside connections, and many networks (like mobile ones) do not. Messages wait here.';

  @override
  String get unreachableOffline =>
      'The contact seems to be offline. Messages wait here and go out when they show up.';

  @override
  String get attachFile => 'Attach a file';

  @override
  String get fileDownload => 'Download';

  @override
  String get fileSave => 'Save';

  @override
  String get fileRetry => 'Try again';

  @override
  String get fileSaved => 'Saved.';

  @override
  String get fileWaiting => 'Waiting for the contact';

  @override
  String get fileFailed =>
      'It arrived different from what was sent, and was discarded.';

  @override
  String get fileInvalid =>
      'This file cannot be sent: it is over 1 GB, cannot be read, or is a photo whose metadata could not be removed.';

  @override
  String fileView(String name) {
    return 'Open the photo $name';
  }

  @override
  String filePreview(String name) {
    return 'File: $name';
  }

  @override
  String fileProgress(int percent) {
    return '$percent%';
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
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsHelp =>
      'What the system shows when a message arrives and the conversation isn\'t on screen.';

  @override
  String get notifyOff => 'Off';

  @override
  String get notifyHidden => 'No content';

  @override
  String get notifyHiddenHelp => 'Only \"New message\", without name or text.';

  @override
  String get notifySender => 'Name only';

  @override
  String get notifySenderHelp => 'Who wrote, without the text.';

  @override
  String get notifyFull => 'Name and message';

  @override
  String get notifyFullHelp =>
      'The text can also show on the lock screen, if the system allows.';

  @override
  String get notificationNewMessage => 'New message';

  @override
  String get notificationOpen => 'Open';

  @override
  String get notificationChannel => 'Messages';

  @override
  String get backgroundTitle => 'In the background';

  @override
  String get keepRunning => 'Keep receiving with the window closed';

  @override
  String get keepRunningHelp =>
      'Psito Chirp stays in the system tray. To quit for good, use Quit in its menu.';

  @override
  String get startAtLogin => 'Open when you sign in';

  @override
  String get startAtLoginHelp => 'It starts hidden, in the tray.';

  @override
  String trayOpen(String name) {
    return 'Open $name';
  }

  @override
  String get trayQuit => 'Quit';

  @override
  String get keepRunningHelpMobile =>
      'A quiet notification stays while Psito Chirp is receiving.';

  @override
  String get receivingNow => 'Receiving messages';

  @override
  String get batteryTitle => 'Battery saving';

  @override
  String get batteryHelp =>
      'With the phone idle, Android may delay messages. Keeping Psito Chirp out of battery saving avoids that, and uses a little more battery.';

  @override
  String get batteryAllow => 'Keep it out';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsHelp =>
      'Files up to this size download as soon as they arrive. Bigger ones wait for you to tap Download.';

  @override
  String get autoDownloadNever => 'Never on their own';

  @override
  String get autoDownloadSmall => 'Up to 4 MB';

  @override
  String get autoDownloadMedium => 'Up to 32 MB';

  @override
  String get autoDownloadLarge => 'Up to 256 MB';

  @override
  String get onlyVerified => 'Only from verified contacts';

  @override
  String get onlyVerifiedHelp =>
      'From contacts whose safety code you haven\'t checked, every file waits.';

  @override
  String get voiceRecord => 'Record a voice note';

  @override
  String get voiceRecording => 'Recording';

  @override
  String get voiceDiscard => 'Discard';

  @override
  String get voiceSend => 'Send the voice note';

  @override
  String get voiceNote => 'Voice note';

  @override
  String get voicePlay => 'Play the voice note';

  @override
  String get voiceStop => 'Stop';

  @override
  String get voicePreview => 'Voice note';

  @override
  String get voiceTooShort => 'Too short: hold on a little longer.';

  @override
  String get audioUnavailable =>
      'No microphone or speaker, or the system didn\'t allow using it.';

  @override
  String get microphoneDenied =>
      'Psito Chirp needs the microphone to record. You can allow it in the system settings.';

  @override
  String get emptyShowCode => 'Show my code';

  @override
  String get emptyShowCodeBody =>
      'Together? The other person scans the QR. It\'s the safest way: you\'re verified from the start.';

  @override
  String get emptyUseLink => 'Use an invite link';

  @override
  String get emptyUseLinkBody =>
      'Far apart? Send your link however you like, or paste the one you got. It works once, for 24 hours.';

  @override
  String get emptyPromise => 'No account, no phone number, no logs.';

  @override
  String get contactsWillAppear => 'Your contacts show up here';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterVerified => 'Verified';

  @override
  String get filterEmpty => 'Nothing here with this filter.';

  @override
  String groupReachable(int count) {
    return 'IN REACH · $count';
  }

  @override
  String groupUnreachable(int count) {
    return 'OUT OF REACH · $count';
  }

  @override
  String sayHi(String name) {
    return 'Say hi to $name';
  }

  @override
  String get sayHiUnverified =>
      'You haven\'t checked the safety code yet. You can talk, but check it when you meet.';

  @override
  String get e2eVerified =>
      'End-to-end encrypted. You checked the safety code in person.';

  @override
  String get e2eUnverified =>
      'End-to-end encrypted. Check the safety code when you meet.';

  @override
  String get checkCode => 'Check code';

  @override
  String get inviteValidity => 'Works once, for 24 hours';

  @override
  String get pasteStep1 =>
      'Ask the other person for the link, wherever you already talk.';

  @override
  String get pasteStep2 =>
      'Paste it here. Chirp looks for them on the local network, or the internet if it\'s on.';

  @override
  String get pasteStep3 =>
      'They come in as unverified: check the safety code when you meet.';

  @override
  String get pasteTip =>
      'The link works only once and expires in 24 hours. Don\'t leave it anywhere public.';

  @override
  String get statusInMailbox => 'Waiting in their mailbox';

  @override
  String get mailboxTitle => 'Mailbox';

  @override
  String get mailboxHelp =>
      'A mailbox is a small server of your own, or of someone you trust, that keeps what your contacts send while this device is off, until you open Chirp. Messages arrive there already encrypted: it sees who leaves something and when, never what. Files still need you both online.';

  @override
  String get mailboxCode => 'Mailbox code';

  @override
  String get mailboxCodeHelp =>
      'Run chirp-mailbox pair on the server and paste the code it shows. It works once, for 24 hours.';

  @override
  String get mailboxPair => 'Link';

  @override
  String get mailboxPaired => 'Mailbox linked';

  @override
  String get mailboxStatusWaiting => 'Not checked yet.';

  @override
  String mailboxStatusChecked(String time) {
    return 'Last checked $time.';
  }

  @override
  String get mailboxStatusUnreachable =>
      'The mailbox did not answer. Messages for you may wait with your contacts.';

  @override
  String get mailboxUnpair => 'Unlink';

  @override
  String get mailboxUnpairTitle => 'Unlink the mailbox?';

  @override
  String get mailboxUnpairBody =>
      'Whatever is waiting in it is lost, and your contacts stop leaving messages there. You can link it again with a new code.';

  @override
  String get mailboxInvalid =>
      'That code does not work. Paste the whole chirp://mailbox# link.';

  @override
  String get mailboxRefused =>
      'The mailbox refused the code. It works only once and expires in 24 hours: make a new one.';

  @override
  String get mailboxUnreachable =>
      'Could not reach the mailbox. With the internet off, only a mailbox on the local network works.';

  @override
  String get contactRequestLeft =>
      'They were offline, so your request is waiting in their mailbox. They\'ll appear as a contact once they open Chirp.';

  @override
  String get photoTitle => 'Profile photo';

  @override
  String get photoHelp =>
      'Only contacts you allow see it, never anyone else. It is made square and leaves this device without location or any other data from the original file.';

  @override
  String get photoChoose => 'Choose a photo';

  @override
  String get photoChange => 'Change photo';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get photoWhoSees => 'Who sees it';

  @override
  String get photoEveryone => 'All my contacts';

  @override
  String get photoChosen => 'Only contacts I choose';

  @override
  String get photoChosenHelp => 'Choose them on each contact\'s page.';

  @override
  String get photoNobody => 'Nobody';

  @override
  String get photoRevokeNote =>
      'Taking someone off removes your photo from their Chirp, but they may already have saved a copy.';

  @override
  String get photoAllowed => 'Can see my photo';

  @override
  String get photoAllowedHelp =>
      'Turning this off removes your photo from their Chirp.';

  @override
  String get groupNew => 'New group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupPickMembers => 'Who is in it';

  @override
  String get groupCreate => 'Create';

  @override
  String get groupAdd => 'Add';

  @override
  String get groupNoOneToAdd =>
      'No contacts to add yet. Add someone first, then bring them into the group.';

  @override
  String get groupHelp =>
      'Each member gets your messages encrypted, straight from your device, with no server. For now they reach only members who are also your contacts.';

  @override
  String get groupLabel => 'Group';

  @override
  String get groupClosed => 'You are no longer in this group.';

  @override
  String groupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You and $count others',
      one: 'You and $count other',
      zero: 'Only you',
    );
    return '$_temp0';
  }

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupNotConnected =>
      'Not your contact: your messages do not reach them yet';

  @override
  String get groupAddMembers => 'Add members';

  @override
  String get groupRemove => 'Remove from the group';

  @override
  String get groupRename => 'Rename group';

  @override
  String get groupLeave => 'Leave group';

  @override
  String groupLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get groupLeaveBody =>
      'The members are told you left. The messages stay here, but you can no longer write or receive in this group.';

  @override
  String get groupNotAdmin => 'Only the group admin can do that.';

  @override
  String get groupTooMany => 'A group has at most 64 members.';
}

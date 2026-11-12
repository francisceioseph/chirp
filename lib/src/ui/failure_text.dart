// lib/src/ui/failure_text.dart
//
// O texto de cada falha do núcleo que aparece num formulário.
import '../../l10n/l10n.dart';
import '../core/chirp_core.dart';

String failureText(
  ChirpLocalizations l10n,
  CoreFailure failure, {
  int minPassphraseChars = 8,
}) => switch (failure) {
  CoreFailure.wrongKey => l10n.passphraseWrong,
  CoreFailure.weakPassphrase => l10n.passphraseTooShort(minPassphraseChars),
  CoreFailure.invalidName => l10n.nameInvalid,
  CoreFailure.invalidInvite => l10n.inviteInvalid,
  CoreFailure.inviteRefused => l10n.inviteRefused,
  CoreFailure.ownInvite => l10n.inviteOwn,
  CoreFailure.unreachable => l10n.inviteUnreachable,
  CoreFailure.alreadyExists => l10n.inviteAlreadyContact,
  CoreFailure.protocol => l10n.inviteProtocol,
  CoreFailure.tooSoon => l10n.messageTooSoon,
  CoreFailure.tooLate => l10n.messageTooLate,
  CoreFailure.invalidMessage => l10n.messageInvalid,
  CoreFailure.invalidRelay => l10n.relayInvalid,
  CoreFailure.invalidFile => l10n.fileInvalid,
  CoreFailure.noAudio => l10n.audioUnavailable,
  CoreFailure.invalidMailbox => l10n.mailboxInvalid,
  CoreFailure.mailboxRefused => l10n.mailboxRefused,
  _ => l10n.somethingWentWrong,
};

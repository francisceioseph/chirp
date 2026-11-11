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
  _ => l10n.somethingWentWrong,
};

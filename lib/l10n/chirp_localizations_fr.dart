// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ChirpLocalizationsFr extends ChirpLocalizations {
  ChirpLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Des conversations qui restent entre vous';

  @override
  String get welcomeBody =>
      'Ni compte, ni serveur, ni journal. Vos messages ne vivent que sur vos appareils.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Noyau $version · protocole $protocol';
  }

  @override
  String get coreUnavailable => 'Le noyau sécurisé n\'a pas pu démarrer.';

  @override
  String get loading => 'Ouverture de Chirp';

  @override
  String get nameLabel => 'Votre nom';

  @override
  String get nameHelp => 'Seuls vos contacts le verront, et toujours chiffré.';

  @override
  String get nameInvalid =>
      'Saisissez un nom de 64 caractères au plus, sur une seule ligne.';

  @override
  String get onboardingCreate => 'Créer mon profil';

  @override
  String get passphraseCreateTitle => 'Protégez Chirp par une phrase secrète';

  @override
  String get passphraseCreateBody =>
      'Ce système n\'a pas de trousseau où Chirp peut garder sa clé : vos données seront donc verrouillées par une phrase secrète. Si vous l\'oubliez, impossible de la récupérer.';

  @override
  String get passphraseUnlockTitle => 'Déverrouiller Chirp';

  @override
  String get passphraseLabel => 'Phrase secrète';

  @override
  String get passphraseConfirmLabel => 'Répétez la phrase secrète';

  @override
  String get passphraseShow => 'Afficher la phrase secrète';

  @override
  String get passphraseHide => 'Masquer la phrase secrète';

  @override
  String passphraseTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Utilisez au moins $count caractères.',
      one: 'Utilisez au moins $count caractère.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseMismatch => 'Les phrases secrètes ne correspondent pas.';

  @override
  String get passphraseWrong => 'Cette phrase secrète n\'ouvre pas Chirp.';

  @override
  String get passphraseCreate => 'Verrouiller avec cette phrase';

  @override
  String get passphraseUnlock => 'Déverrouiller';

  @override
  String get passphraseForgot => 'J\'ai oublié la phrase secrète';

  @override
  String get problemCoreBody =>
      'Les fichiers de l\'app sont peut-être incomplets. Réinstallez Chirp.';

  @override
  String get problemVaultTitle => 'Le trousseau n\'a pas répondu';

  @override
  String get problemVaultBody =>
      'Chirp garde sa clé dans le trousseau du système, qui n\'a pas répondu. Déverrouillez-le et réessayez.';

  @override
  String get problemKeyLostTitle => 'La clé de vos données a disparu';

  @override
  String get problemKeyLostBody =>
      'Vos données sont toujours sur cet appareil, mais la clé qui les ouvre n\'est plus dans le trousseau du système. Sans elle, rien ne peut être lu. Vous pouvez tout effacer et recommencer.';

  @override
  String get problemNewerTitle =>
      'Ces données viennent d\'un Chirp plus récent';

  @override
  String get problemNewerBody => 'Mettez Chirp à jour pour les ouvrir.';

  @override
  String get problemStorageTitle => 'Chirp n\'a pas pu ouvrir ses données';

  @override
  String get problemStorageBody =>
      'Un problème est survenu en lisant le disque. Réessayez ; si cela continue, vous pouvez tout effacer et recommencer.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get eraseEverything => 'Tout effacer et recommencer';

  @override
  String get eraseTitle => 'Tout effacer ?';

  @override
  String get eraseBody =>
      'Votre profil, votre clé et tout ce que Chirp garde sur cet appareil disparaîtront pour de bon.';

  @override
  String get eraseConfirm => 'Effacer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get renameTooltip => 'Changer de nom';

  @override
  String get renameTitle => 'Changez votre nom';

  @override
  String get profileKeyLabel => 'Votre clé';

  @override
  String get profileKeyHelp =>
      'Vos contacts comparent ce numéro pour savoir que c\'est bien vous.';

  @override
  String get homeNextPhase =>
      'Votre profil et votre clé sont prêts. Les conversations arrivent à la prochaine étape.';

  @override
  String get somethingWentWrong => 'Un problème est survenu. Réessayez.';
}

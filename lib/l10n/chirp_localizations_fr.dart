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
  String get somethingWentWrong => 'Un problème est survenu. Réessayez.';

  @override
  String get profileTitle => 'Votre profil';

  @override
  String get addContact => 'Ajouter un contact';

  @override
  String get contactsEmptyTitle => 'Aucun contact pour l\'instant';

  @override
  String get contactsEmptyBody =>
      'Montrez votre code à quelqu\'un à côté de vous, ou collez l\'invitation qu\'on vous a envoyée. Sur le même réseau, sans internet.';

  @override
  String get contactPending => 'En attente de l\'autre appareil';

  @override
  String get contactVerified => 'Vérifié';

  @override
  String get contactUnverified => 'Non vérifié';

  @override
  String get contactUnnamed => 'Pas encore de nom';

  @override
  String contactAdded(String name) {
    return '$name est maintenant un contact.';
  }

  @override
  String get inviteTabShow => 'Mon code';

  @override
  String get inviteTabPaste => 'Coller une invitation';

  @override
  String get inviteQrLabel => 'Code d\'invitation, en QR';

  @override
  String get inviteQrHelp =>
      'Laissez l\'autre personne scanner ce code, ou envoyez-lui le lien. Chaque code sert une fois, pendant 24 heures.';

  @override
  String get inviteCopyLink => 'Copier le lien d\'invitation';

  @override
  String get inviteLinkCopied =>
      'Lien copié. Envoyez-le par un canal de confiance : il sert une fois, pendant 24 heures.';

  @override
  String get inviteNewCode => 'Nouveau code';

  @override
  String get pasteLabel => 'Lien d\'invitation';

  @override
  String get pasteHelp => 'Commence par chirp://invite';

  @override
  String get pasteAdd => 'Ajouter';

  @override
  String get pasteConnecting => 'Connexion';

  @override
  String get qrScanLater =>
      'La lecture du code par la caméra arrive dans une prochaine version. Pour l\'instant, collez le lien.';

  @override
  String get inviteInvalid =>
      'Ce n\'est pas une invitation Chirp, ou il en manque une partie.';

  @override
  String get inviteRefused =>
      'Cette invitation a expiré ou a déjà servi. Demandez-en une nouvelle.';

  @override
  String get inviteOwn => 'C\'est votre propre invitation.';

  @override
  String get inviteUnreachable =>
      'Impossible de joindre l\'autre appareil. Êtes-vous sur le même réseau, avec Chirp ouvert ?';

  @override
  String get inviteAlreadyContact => 'Cette personne est déjà un contact.';

  @override
  String get inviteProtocol =>
      'L\'autre appareil a répondu quelque chose d\'inattendu. Essayez une nouvelle invitation.';

  @override
  String get safetyNumberTitle => 'Numéro de sécurité';

  @override
  String safetyNumberHelp(String name) {
    return 'Comparez ces numéros avec $name, en personne ou au téléphone. S\'ils sont identiques, personne ne s\'est glissé dans la conversation.';
  }

  @override
  String get markVerified => 'Marquer comme vérifié';

  @override
  String get networkUnavailable => 'Le réseau local n\'a pas démarré.';

  @override
  String get messageHint => 'Message';

  @override
  String get send => 'Envoyer';

  @override
  String get nudge => 'Attirer l\'attention';

  @override
  String nudgeSent(String name) {
    return 'Vous avez attiré l\'attention de $name';
  }

  @override
  String nudgeReceived(String name) {
    return '$name veut attirer votre attention';
  }

  @override
  String get nudgePreview => 'A attiré l\'attention';

  @override
  String get typing => 'écrit…';

  @override
  String get messageDeleted => 'Ce message a été supprimé';

  @override
  String get messageEdited => 'modifié';

  @override
  String get statusPending => 'En attente d\'envoi';

  @override
  String get statusDelivered => 'Distribué';

  @override
  String get statusRead => 'Lu';

  @override
  String get you => 'Vous';

  @override
  String get reply => 'Répondre';

  @override
  String replyingTo(String name) {
    return 'Réponse à $name';
  }

  @override
  String get quotedMissing => 'Message absent de cet appareil';

  @override
  String get editMessage => 'Modifier';

  @override
  String get editingMessage => 'Modification du message';

  @override
  String get copyText => 'Copier le texte';

  @override
  String get textCopied => 'Copié';

  @override
  String get deleteForMe => 'Supprimer pour moi';

  @override
  String get deleteForEveryone => 'Supprimer pour tous';

  @override
  String get reaction1 => 'J\'aime';

  @override
  String get reaction2 => 'J\'adore';

  @override
  String get reaction3 => 'Drôle';

  @override
  String get reaction4 => 'Triste';

  @override
  String get reaction5 => 'Merci';

  @override
  String get reaction6 => 'Bravo';

  @override
  String get react => 'Réagir';

  @override
  String get conversationEmpty => 'Pas encore de messages. Dites bonjour !';

  @override
  String get contactDetails => 'Détails du contact';

  @override
  String get searchMessages => 'Rechercher des messages';

  @override
  String get searchNothing => 'Aucun résultat';

  @override
  String get searchHelp =>
      'Des mots de n\'importe quelle conversation, sans tenir compte des accents ni des majuscules.';

  @override
  String get messageTooSoon =>
      'Attendez quelques secondes avant de recommencer.';

  @override
  String get messageTooLate => 'Le délai pour modifier ce message est passé.';

  @override
  String get messageInvalid => 'Le message est vide ou trop long.';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non lus',
      one: '$count message non lu',
    );
    return '$_temp0';
  }

  @override
  String get chatSettingsTitle => 'Conversations';

  @override
  String get readReceipts => 'Accusés de lecture';

  @override
  String get readReceiptsHelp =>
      'Désactivés, vous ne voyez pas non plus quand on lit les vôtres.';

  @override
  String get typingIndicator => 'Indicateur de saisie';

  @override
  String get typingIndicatorHelp =>
      'Désactivé, vous ne voyez pas non plus quand les autres écrivent.';

  @override
  String get messageOptions => 'Options du message';
}

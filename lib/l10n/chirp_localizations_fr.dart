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

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get appearanceMode => 'Clair ou sombre';

  @override
  String get modeSystem => 'Système';

  @override
  String get modeLight => 'Clair';

  @override
  String get modeDark => 'Sombre';

  @override
  String get themeLabel => 'Thème';

  @override
  String get appearanceNotSaved => 'Impossible d’enregistrer l’apparence.';

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
  String get conversationPick => 'Choisissez une conversation';

  @override
  String get close => 'Fermer';

  @override
  String get glassEffect => 'Effet verre';

  @override
  String get glassEffectHelp =>
      'Les barres deviennent translucides au-dessus de ce qui défile. Désactivé quand le système demande moins d’animations ou plus de contraste.';

  @override
  String get themeSystem => 'Couleur du système';

  @override
  String get networkTitle => 'Réseau';

  @override
  String get networkLocalAlways =>
      'Le réseau local reste toujours actif : les personnes sur le même Wi-Fi discutent sans que rien n’en sorte.';

  @override
  String get internetToggle => 'Internet';

  @override
  String get internetHelp =>
      'Pour discuter avec des personnes sur d’autres réseaux. Vos contacts reçoivent votre adresse publique (l’IP), qui révèle votre opérateur et à peu près votre ville.';

  @override
  String get relaysTitle => 'Serveurs relais';

  @override
  String get relaysHelp =>
      'Sans relais, seules les connexions directes marchent, et beaucoup de réseaux (les réseaux mobiles, presque toujours) les bloquent. Le relais voit votre IP, celle de vos contacts et quand vous discutez, et transmet les messages déjà chiffrés, sans les lire ni les garder. Utilisez le vôtre ou celui d’une personne de confiance.';

  @override
  String get relayAddress => 'Adresse du relais';

  @override
  String get relayAddressHelp => 'Commence par https://';

  @override
  String get relayAdd => 'Ajouter';

  @override
  String get relayRemove => 'Retirer';

  @override
  String get relayInvalid =>
      'Cette adresse ne convient pas. Utilisez-en une qui commence par https://, sans utilisateur ni mot de passe, trois au plus.';

  @override
  String get relayStatusNone =>
      'Pas de relais : connexions directes uniquement.';

  @override
  String get relayStatusConnected => 'Connecté au relais.';

  @override
  String get relayStatusWaiting => 'Le relais n’a pas encore répondu.';

  @override
  String get reachTitle => 'Connexion';

  @override
  String get reachLan => 'Sur le réseau local';

  @override
  String get reachDirect => 'Par internet, en direct';

  @override
  String get reachRelay => 'Par le relais';

  @override
  String get reachUnreachable => 'Hors de portée pour l’instant';

  @override
  String get reachUnknown => 'Pas encore essayé';

  @override
  String get unreachableLocalOnly =>
      'Hors de portée sur le réseau local. S’il est sur un autre réseau, activez internet dans Votre profil, Réseau. Les messages attendent ici.';

  @override
  String get unreachableNoRelay =>
      'Connexion directe impossible. Sans serveur relais, cela ne marche que si l’un de vous accepte les connexions de l’extérieur, et beaucoup de réseaux (comme les réseaux mobiles) ne le permettent pas. Les messages attendent ici.';

  @override
  String get unreachableOffline =>
      'Le contact semble hors ligne. Les messages attendent ici et partiront quand il reviendra.';

  @override
  String get attachFile => 'Joindre un fichier';

  @override
  String get fileDownload => 'Télécharger';

  @override
  String get fileSave => 'Enregistrer';

  @override
  String get fileRetry => 'Réessayer';

  @override
  String get fileSaved => 'Enregistré.';

  @override
  String get fileWaiting => 'En attente du contact';

  @override
  String get fileFailed =>
      'Il est arrivé différent de ce qui a été envoyé et a été supprimé.';

  @override
  String get fileInvalid =>
      'Ce fichier ne peut pas être envoyé : il dépasse 1 Go, il est illisible, ou c’est une photo dont les métadonnées n’ont pas pu être retirées.';

  @override
  String fileView(String name) {
    return 'Ouvrir la photo $name';
  }

  @override
  String filePreview(String name) {
    return 'Fichier : $name';
  }

  @override
  String fileProgress(int percent) {
    return '$percent %';
  }

  @override
  String sizeBytes(String size) {
    return '$size o';
  }

  @override
  String sizeKb(String size) {
    return '$size Ko';
  }

  @override
  String sizeMb(String size) {
    return '$size Mo';
  }

  @override
  String sizeGb(String size) {
    return '$size Go';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsHelp =>
      'Ce que le système affiche quand un message arrive et que la conversation n\'est pas à l\'écran.';

  @override
  String get notifyOff => 'Désactivées';

  @override
  String get notifyHidden => 'Sans contenu';

  @override
  String get notifyHiddenHelp =>
      'Seulement « Nouveau message », sans nom ni texte.';

  @override
  String get notifySender => 'Nom seulement';

  @override
  String get notifySenderHelp => 'Qui a écrit, sans le texte.';

  @override
  String get notifyFull => 'Nom et message';

  @override
  String get notifyFullHelp =>
      'Le texte peut aussi apparaître sur l\'écran verrouillé, si le système le permet.';

  @override
  String get notificationNewMessage => 'Nouveau message';

  @override
  String get notificationOpen => 'Ouvrir';

  @override
  String get notificationChannel => 'Messages';

  @override
  String get backgroundTitle => 'En arrière-plan';

  @override
  String get keepRunning => 'Continuer à recevoir avec la fenêtre fermée';

  @override
  String get keepRunningHelp =>
      'Psito Chirp reste dans la zone de notification. Pour quitter vraiment, utilisez Quitter dans son menu.';

  @override
  String get startAtLogin => 'Ouvrir à la connexion';

  @override
  String get startAtLoginHelp =>
      'Il démarre caché, dans la zone de notification.';

  @override
  String trayOpen(String name) {
    return 'Ouvrir $name';
  }

  @override
  String get trayQuit => 'Quitter';

  @override
  String get keepRunningHelpMobile =>
      'Une notification discrète reste affichée pendant que Psito Chirp reçoit.';

  @override
  String get receivingNow => 'Réception des messages';

  @override
  String get batteryTitle => 'Économie de batterie';

  @override
  String get batteryHelp =>
      'Téléphone au repos, Android peut retarder les messages. Laisser Psito Chirp hors de l\'économie l\'évite, et consomme un peu plus de batterie.';

  @override
  String get batteryAllow => 'L\'exclure';
}

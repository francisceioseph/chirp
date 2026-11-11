// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ChirpLocalizationsEs extends ChirpLocalizations {
  ChirpLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Conversaciones que quedan entre ustedes';

  @override
  String get welcomeBody =>
      'Sin cuentas, sin servidores, sin registros. Tus mensajes viven solo en tus dispositivos.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Núcleo $version · protocolo $protocol';
  }

  @override
  String get coreUnavailable => 'El núcleo seguro no pudo iniciar.';

  @override
  String get loading => 'Abriendo Chirp';

  @override
  String get nameLabel => 'Tu nombre';

  @override
  String get nameHelp => 'Solo lo verán tus contactos, y siempre cifrado.';

  @override
  String get nameInvalid =>
      'Escribe un nombre de hasta 64 caracteres, en una sola línea.';

  @override
  String get onboardingCreate => 'Crear mi perfil';

  @override
  String get passphraseCreateTitle => 'Protege Chirp con una contraseña';

  @override
  String get passphraseCreateBody =>
      'Este sistema no tiene un llavero donde Chirp pueda guardar su clave, así que tus datos quedarán bloqueados con una contraseña. Si la olvidas, no hay forma de recuperarla.';

  @override
  String get passphraseUnlockTitle => 'Desbloquear Chirp';

  @override
  String get passphraseLabel => 'Contraseña';

  @override
  String get passphraseConfirmLabel => 'Repite la contraseña';

  @override
  String get passphraseShow => 'Mostrar la contraseña';

  @override
  String get passphraseHide => 'Ocultar la contraseña';

  @override
  String passphraseTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usa al menos $count caracteres.',
      one: 'Usa al menos $count carácter.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseMismatch => 'Las contraseñas no coinciden.';

  @override
  String get passphraseWrong => 'Esa contraseña no abre Chirp.';

  @override
  String get passphraseCreate => 'Bloquear con esta contraseña';

  @override
  String get passphraseUnlock => 'Desbloquear';

  @override
  String get passphraseForgot => 'Olvidé la contraseña';

  @override
  String get problemCoreBody =>
      'Los archivos de la app pueden estar incompletos. Instala Chirp de nuevo.';

  @override
  String get problemVaultTitle => 'El llavero no respondió';

  @override
  String get problemVaultBody =>
      'Chirp guarda su clave en el llavero del sistema, y no respondió. Desbloquéalo e inténtalo de nuevo.';

  @override
  String get problemKeyLostTitle => 'La clave de tus datos ya no está';

  @override
  String get problemKeyLostBody =>
      'Tus datos siguen en este dispositivo, pero la clave que los abre ya no está en el llavero del sistema. Sin ella, no se puede leer nada. Puedes borrarlos y empezar de nuevo.';

  @override
  String get problemNewerTitle => 'Estos datos son de un Chirp más nuevo';

  @override
  String get problemNewerBody => 'Actualiza Chirp para abrirlos.';

  @override
  String get problemStorageTitle => 'Chirp no pudo abrir sus datos';

  @override
  String get problemStorageBody =>
      'Algo salió mal al leer el disco. Inténtalo de nuevo; si sigue pasando, puedes borrar todo y empezar de nuevo.';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get eraseEverything => 'Borrar todo y empezar de nuevo';

  @override
  String get eraseTitle => '¿Borrar todo?';

  @override
  String get eraseBody =>
      'Tu perfil, tu clave y todo lo que Chirp guarda en este dispositivo desaparecerán para siempre.';

  @override
  String get eraseConfirm => 'Borrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get renameTooltip => 'Cambiar el nombre';

  @override
  String get renameTitle => 'Cambia tu nombre';

  @override
  String get profileKeyLabel => 'Tu clave';

  @override
  String get profileKeyHelp =>
      'Tus contactos comparan este número para saber que de verdad eres tú.';

  @override
  String get somethingWentWrong => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get profileTitle => 'Tu perfil';

  @override
  String get addContact => 'Añadir contacto';

  @override
  String get contactsEmptyTitle => 'Todavía no hay contactos';

  @override
  String get contactsEmptyBody =>
      'Muestra tu código a alguien cercano o pega la invitación que te enviaron. En la misma red, sin necesidad de internet.';

  @override
  String get contactPending => 'Esperando al otro dispositivo';

  @override
  String get contactVerified => 'Verificado';

  @override
  String get contactUnverified => 'No verificado';

  @override
  String get contactUnnamed => 'Todavía sin nombre';

  @override
  String contactAdded(String name) {
    return '$name ahora es un contacto.';
  }

  @override
  String get inviteTabShow => 'Mi código';

  @override
  String get inviteTabPaste => 'Pegar invitación';

  @override
  String get inviteQrLabel => 'Código de invitación, en QR';

  @override
  String get inviteQrHelp =>
      'Deja que la otra persona escanee este código o envíale el enlace. Cada código vale una vez, durante 24 horas.';

  @override
  String get inviteCopyLink => 'Copiar el enlace de invitación';

  @override
  String get inviteLinkCopied =>
      'Enlace copiado. Envíalo por un canal de confianza: vale una vez, durante 24 horas.';

  @override
  String get inviteNewCode => 'Código nuevo';

  @override
  String get pasteLabel => 'Enlace de invitación';

  @override
  String get pasteHelp => 'Empieza con chirp://invite';

  @override
  String get pasteAdd => 'Añadir';

  @override
  String get pasteConnecting => 'Conectando';

  @override
  String get qrScanLater =>
      'Leer el código con la cámara llega en una versión posterior. Por ahora, pega el enlace.';

  @override
  String get inviteInvalid =>
      'Esto no es una invitación de Chirp, o le falta una parte.';

  @override
  String get inviteRefused =>
      'Esta invitación caducó o ya se usó. Pide una nueva.';

  @override
  String get inviteOwn => 'Esta es tu propia invitación.';

  @override
  String get inviteUnreachable =>
      'No se pudo contactar con el otro dispositivo. ¿Están en la misma red, con Chirp abierto?';

  @override
  String get inviteAlreadyContact => 'Esta persona ya es un contacto.';

  @override
  String get inviteProtocol =>
      'El otro dispositivo respondió algo inesperado. Prueba una invitación nueva.';

  @override
  String get safetyNumberTitle => 'Número de seguridad';

  @override
  String safetyNumberHelp(String name) {
    return 'Compara estos números con $name, en persona o en una llamada. Si coinciden, nadie está en medio de la conversación.';
  }

  @override
  String get markVerified => 'Marcar como verificado';

  @override
  String get networkUnavailable => 'La red local no se inició.';

  @override
  String get messageHint => 'Mensaje';

  @override
  String get send => 'Enviar';

  @override
  String get nudge => 'Llamar la atención';

  @override
  String nudgeSent(String name) {
    return 'Llamaste la atención de $name';
  }

  @override
  String nudgeReceived(String name) {
    return '$name te llamó la atención';
  }

  @override
  String get nudgePreview => 'Llamó la atención';

  @override
  String get typing => 'escribiendo…';

  @override
  String get messageDeleted => 'Mensaje eliminado';

  @override
  String get messageEdited => 'editado';

  @override
  String get statusPending => 'Esperando la entrega';

  @override
  String get statusDelivered => 'Entregado';

  @override
  String get statusRead => 'Leído';

  @override
  String get you => 'Tú';

  @override
  String get reply => 'Responder';

  @override
  String replyingTo(String name) {
    return 'Respondiendo a $name';
  }

  @override
  String get quotedMissing => 'Mensaje que no está en este dispositivo';

  @override
  String get editMessage => 'Editar';

  @override
  String get editingMessage => 'Editando el mensaje';

  @override
  String get copyText => 'Copiar el texto';

  @override
  String get textCopied => 'Copiado';

  @override
  String get deleteForMe => 'Eliminar para mí';

  @override
  String get deleteForEveryone => 'Eliminar para todos';

  @override
  String get reaction1 => 'Me gusta';

  @override
  String get reaction2 => 'Me encanta';

  @override
  String get reaction3 => 'Divertido';

  @override
  String get reaction4 => 'Triste';

  @override
  String get reaction5 => 'Gracias';

  @override
  String get reaction6 => 'Celebrar';

  @override
  String get react => 'Reaccionar';

  @override
  String get conversationEmpty => 'Aún no hay mensajes. ¡Saluda!';

  @override
  String get contactDetails => 'Detalles del contacto';

  @override
  String get searchMessages => 'Buscar mensajes';

  @override
  String get searchNothing => 'No se encontró nada';

  @override
  String get searchHelp =>
      'Palabras de cualquier conversación, sin importar tildes ni mayúsculas.';

  @override
  String get messageTooSoon =>
      'Espera unos segundos antes de hacerlo otra vez.';

  @override
  String get messageTooLate => 'Ya pasó el plazo para cambiar este mensaje.';

  @override
  String get messageInvalid => 'El mensaje está vacío o es demasiado largo.';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes sin leer',
      one: '$count mensaje sin leer',
    );
    return '$_temp0';
  }

  @override
  String get chatSettingsTitle => 'Conversaciones';

  @override
  String get readReceipts => 'Confirmaciones de lectura';

  @override
  String get readReceiptsHelp =>
      'Si las desactivas, tampoco verás cuándo leen las tuyas.';

  @override
  String get typingIndicator => 'Aviso de escribiendo';

  @override
  String get typingIndicatorHelp =>
      'Si lo desactivas, tampoco verás cuándo escriben los demás.';

  @override
  String get messageOptions => 'Opciones del mensaje';
}

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
  String get contactsEmptyTitle => 'Todavía no hay nadie';

  @override
  String get contactsEmptyBody =>
      'Para hablar, intercambien invitaciones. Los mensajes van directo de un dispositivo al otro, cifrados, sin pasar por ningún servidor.';

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

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearanceMode => 'Claro u oscuro';

  @override
  String get modeSystem => 'Sistema';

  @override
  String get modeLight => 'Claro';

  @override
  String get modeDark => 'Oscuro';

  @override
  String get themeLabel => 'Tema';

  @override
  String get appearanceNotSaved => 'No se pudo guardar la apariencia.';

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
  String get conversationPick => 'Elige una conversación';

  @override
  String get close => 'Cerrar';

  @override
  String get glassEffect => 'Efecto vidrio';

  @override
  String get glassEffectHelp =>
      'Las barras se vuelven translúcidas sobre lo que pasa por debajo. Se apaga cuando el sistema pide menos animación o más contraste.';

  @override
  String get themeSystem => 'Color del sistema';

  @override
  String get networkTitle => 'Red';

  @override
  String get networkLocalAlways =>
      'La red local está siempre activa: quienes están en el mismo Wi-Fi hablan sin que nada salga de ella.';

  @override
  String get internetToggle => 'Internet';

  @override
  String get internetHelp =>
      'Para hablar con quienes están en otra red. Tus contactos reciben tu dirección pública (la IP), que muestra tu proveedor y más o menos tu ciudad.';

  @override
  String get relaysTitle => 'Servidores de retransmisión';

  @override
  String get relaysHelp =>
      'Sin uno, solo funcionan las conexiones directas, y muchas redes (las móviles, casi siempre) no las permiten. El servidor ve tu IP, la de tus contactos y cuándo hablan, y reenvía los mensajes ya cifrados, sin leerlos ni guardarlos. Usa el tuyo o el de alguien de confianza.';

  @override
  String get relayAddress => 'Dirección del servidor';

  @override
  String get relayAddressHelp => 'Empieza con https://';

  @override
  String get relayAdd => 'Añadir';

  @override
  String get relayRemove => 'Quitar';

  @override
  String get relayInvalid =>
      'Esa dirección no sirve. Usa una que empiece con https://, sin usuario ni contraseña, hasta tres.';

  @override
  String get relayStatusNone => 'Sin servidor: solo conexiones directas.';

  @override
  String get relayStatusConnected => 'Conectado al servidor.';

  @override
  String get relayStatusWaiting => 'El servidor aún no ha respondido.';

  @override
  String get reachTitle => 'Conexión';

  @override
  String get reachLan => 'En la red local';

  @override
  String get reachDirect => 'Por internet, directo';

  @override
  String get reachRelay => 'Por el servidor de retransmisión';

  @override
  String get reachUnreachable => 'Fuera de alcance ahora';

  @override
  String get reachUnknown => 'Aún no se intentó';

  @override
  String get unreachableLocalOnly =>
      'Fuera de alcance en la red local. Si está en otra red, activa internet en Tu perfil, Red. Los mensajes esperan aquí.';

  @override
  String get unreachableNoRelay =>
      'No se pudo conectar directamente. Sin un servidor de retransmisión, solo funciona si uno de los dos acepta conexiones de fuera, y muchas redes (como las móviles) no lo permiten. Los mensajes esperan aquí.';

  @override
  String get unreachableOffline =>
      'El contacto parece desconectado. Los mensajes esperan aquí y salen cuando aparezca.';

  @override
  String get attachFile => 'Adjuntar archivo';

  @override
  String get fileDownload => 'Descargar';

  @override
  String get fileSave => 'Guardar';

  @override
  String get fileRetry => 'Intentar de nuevo';

  @override
  String get fileSaved => 'Guardado.';

  @override
  String get fileWaiting => 'Esperando al contacto';

  @override
  String get fileFailed => 'Llegó distinto de lo que se envió y se descartó.';

  @override
  String get fileInvalid =>
      'Este archivo no se puede enviar: supera 1 GB, no se puede leer o es una foto de la que no se pudieron quitar los metadatos.';

  @override
  String fileView(String name) {
    return 'Abrir la foto $name';
  }

  @override
  String filePreview(String name) {
    return 'Archivo: $name';
  }

  @override
  String fileProgress(int percent) {
    return '$percent %';
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
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsHelp =>
      'Lo que muestra el sistema cuando llega un mensaje y la conversación no está en pantalla.';

  @override
  String get notifyOff => 'Desactivadas';

  @override
  String get notifyHidden => 'Sin contenido';

  @override
  String get notifyHiddenHelp => 'Solo \"Nuevo mensaje\", sin nombre ni texto.';

  @override
  String get notifySender => 'Solo el nombre';

  @override
  String get notifySenderHelp => 'Quién escribió, sin el texto.';

  @override
  String get notifyFull => 'Nombre y mensaje';

  @override
  String get notifyFullHelp =>
      'El texto también puede aparecer en la pantalla de bloqueo, si el sistema lo permite.';

  @override
  String get notificationNewMessage => 'Nuevo mensaje';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationChannel => 'Mensajes';

  @override
  String get backgroundTitle => 'En segundo plano';

  @override
  String get keepRunning => 'Seguir recibiendo con la ventana cerrada';

  @override
  String get keepRunningHelp =>
      'Psito Chirp se queda en la bandeja del sistema. Para salir del todo, usa Salir en su menú.';

  @override
  String get startAtLogin => 'Abrir al iniciar sesión';

  @override
  String get startAtLoginHelp => 'Empieza oculto, en la bandeja.';

  @override
  String trayOpen(String name) {
    return 'Abrir $name';
  }

  @override
  String get trayQuit => 'Salir';

  @override
  String get keepRunningHelpMobile =>
      'Queda una notificación discreta mientras Psito Chirp recibe.';

  @override
  String get receivingNow => 'Recibiendo mensajes';

  @override
  String get batteryTitle => 'Ahorro de batería';

  @override
  String get batteryHelp =>
      'Con el teléfono en reposo, Android puede retrasar los mensajes. Dejar Psito Chirp fuera del ahorro lo evita, y gasta un poco más de batería.';

  @override
  String get batteryAllow => 'Dejar fuera';

  @override
  String get downloadsTitle => 'Descargas';

  @override
  String get downloadsHelp =>
      'Los archivos hasta este tamaño se descargan en cuanto llegan. Los más grandes esperan a que toques Descargar.';

  @override
  String get autoDownloadNever => 'Nunca solos';

  @override
  String get autoDownloadSmall => 'Hasta 4 MB';

  @override
  String get autoDownloadMedium => 'Hasta 32 MB';

  @override
  String get autoDownloadLarge => 'Hasta 256 MB';

  @override
  String get onlyVerified => 'Solo de contactos verificados';

  @override
  String get onlyVerifiedHelp =>
      'De los contactos cuyo código de seguridad no has comprobado, todos los archivos esperan.';

  @override
  String get voiceRecord => 'Grabar nota de voz';

  @override
  String get voiceRecording => 'Grabando';

  @override
  String get voiceDiscard => 'Descartar';

  @override
  String get voiceSend => 'Enviar la nota de voz';

  @override
  String get voiceNote => 'Nota de voz';

  @override
  String get voicePlay => 'Reproducir la nota de voz';

  @override
  String get voiceStop => 'Detener';

  @override
  String get voicePreview => 'Nota de voz';

  @override
  String get voiceTooShort => 'Demasiado corta: graba un poco más.';

  @override
  String get audioUnavailable =>
      'No hay micrófono ni altavoz, o el sistema no permitió usarlos.';

  @override
  String get microphoneDenied =>
      'Psito Chirp necesita el micrófono para grabar. Puedes permitirlo en los ajustes del sistema.';

  @override
  String get emptyShowCode => 'Mostrar mi código';

  @override
  String get emptyShowCodeBody =>
      '¿Están juntos? La otra persona lee el QR. Es lo más seguro: quedan verificados desde el principio.';

  @override
  String get emptyUseLink => 'Usar un enlace de invitación';

  @override
  String get emptyUseLinkBody =>
      '¿Lejos? Envía tu enlace como quieras, o pega el que recibiste. Vale una vez, durante 24 horas.';

  @override
  String get emptyPromise =>
      'Sin cuenta, sin número de teléfono, sin registros.';

  @override
  String get contactsWillAppear => 'Tus contactos aparecen aquí';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterUnread => 'No leídas';

  @override
  String get filterVerified => 'Verificados';

  @override
  String get filterEmpty => 'No hay nada con este filtro.';

  @override
  String groupReachable(int count) {
    return 'AL ALCANCE · $count';
  }

  @override
  String groupUnreachable(int count) {
    return 'FUERA DE ALCANCE · $count';
  }

  @override
  String sayHi(String name) {
    return 'Saluda a $name';
  }

  @override
  String get sayHiUnverified =>
      'Todavía no comprobaron el código de seguridad. Pueden hablar, pero compruébenlo cuando estén juntos.';

  @override
  String get e2eVerified =>
      'Cifrada de extremo a extremo. Comprobaron el código de seguridad en persona.';

  @override
  String get e2eUnverified =>
      'Cifrada de extremo a extremo. Comprueben el código de seguridad cuando se vean.';

  @override
  String get checkCode => 'Comprobar código';

  @override
  String get inviteValidity => 'Vale una vez, durante 24 horas';

  @override
  String get pasteStep1 =>
      'Pide el enlace a la otra persona, por donde ya hablan.';

  @override
  String get pasteStep2 =>
      'Pégalo aquí. Chirp la busca en la red local, o en internet si está activado.';

  @override
  String get pasteStep3 =>
      'Entra como no verificado: comprueben el código de seguridad cuando se vean.';

  @override
  String get pasteTip =>
      'El enlace solo sirve una vez y caduca en 24 horas. No lo dejes en un lugar público.';

  @override
  String get statusInMailbox => 'Esperando en su buzón';

  @override
  String get mailboxTitle => 'Buzón';

  @override
  String get mailboxHelp =>
      'El buzón es un pequeño servidor tuyo, o de alguien de confianza, que guarda lo que tus contactos envían mientras este dispositivo está apagado, hasta que abras Chirp. Los mensajes llegan ya cifrados: ve quién deja algo y cuándo, nunca qué. Los archivos aún necesitan a los dos en línea.';

  @override
  String get mailboxCode => 'Código del buzón';

  @override
  String get mailboxCodeHelp =>
      'Ejecuta chirp-mailbox pair en el servidor y pega el código que muestra. Sirve una vez, durante 24 horas.';

  @override
  String get mailboxPair => 'Vincular';

  @override
  String get mailboxPaired => 'Buzón vinculado';

  @override
  String get mailboxStatusWaiting => 'Aún no se ha revisado.';

  @override
  String mailboxStatusChecked(String time) {
    return 'Revisado por última vez $time.';
  }

  @override
  String get mailboxStatusUnreachable =>
      'El buzón no respondió. Los mensajes para ti pueden esperar con tus contactos.';

  @override
  String get mailboxUnpair => 'Desvincular';

  @override
  String get mailboxUnpairTitle => '¿Desvincular el buzón?';

  @override
  String get mailboxUnpairBody =>
      'Lo que esté esperando en él se pierde, y tus contactos dejan de enviar allí. Puedes vincularlo de nuevo con otro código.';

  @override
  String get mailboxInvalid =>
      'Ese código no sirve. Pega el enlace chirp://mailbox# completo.';

  @override
  String get mailboxRefused =>
      'El buzón rechazó el código. Sirve una sola vez y caduca en 24 horas: genera otro.';

  @override
  String get mailboxUnreachable =>
      'No se pudo contactar con el buzón. Con internet apagado, solo funciona un buzón en la red local.';

  @override
  String get contactRequestLeft =>
      'La otra persona estaba desconectada, así que tu solicitud quedó en su buzón. Será tu contacto cuando abra Chirp.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class ChirpLocalizationsPt extends ChirpLocalizations {
  ChirpLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => 'Conversas que ficam entre vocês';

  @override
  String get welcomeBody =>
      'Sem contas, sem servidores, sem registros. Suas mensagens vivem só nos seus aparelhos.';

  @override
  String coreVersion(String version, int protocol) {
    return 'Núcleo $version · protocolo $protocol';
  }

  @override
  String get coreUnavailable => 'O núcleo seguro não conseguiu iniciar.';

  @override
  String get loading => 'Abrindo o Chirp';

  @override
  String get nameLabel => 'Seu nome';

  @override
  String get nameHelp => 'Só seus contatos vão ver, e sempre cifrado.';

  @override
  String get nameInvalid =>
      'Digite um nome de até 64 caracteres, numa linha só.';

  @override
  String get onboardingCreate => 'Criar meu perfil';

  @override
  String get passphraseCreateTitle => 'Proteja o Chirp com uma senha';

  @override
  String get passphraseCreateBody =>
      'Este sistema não tem um cofre onde o Chirp possa guardar a chave, então seus dados vão ficar trancados com uma senha. Se você esquecer, não há como recuperar.';

  @override
  String get passphraseUnlockTitle => 'Destrancar o Chirp';

  @override
  String get passphraseLabel => 'Senha';

  @override
  String get passphraseConfirmLabel => 'Repita a senha';

  @override
  String get passphraseShow => 'Mostrar a senha';

  @override
  String get passphraseHide => 'Esconder a senha';

  @override
  String passphraseTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Use pelo menos $count caracteres.',
      one: 'Use pelo menos $count caractere.',
    );
    return '$_temp0';
  }

  @override
  String get passphraseMismatch => 'As senhas não são iguais.';

  @override
  String get passphraseWrong => 'Essa senha não abre o Chirp.';

  @override
  String get passphraseCreate => 'Trancar com esta senha';

  @override
  String get passphraseUnlock => 'Destrancar';

  @override
  String get passphraseForgot => 'Esqueci a senha';

  @override
  String get problemCoreBody =>
      'Os arquivos do app podem estar incompletos. Instale o Chirp de novo.';

  @override
  String get problemVaultTitle => 'O cofre não respondeu';

  @override
  String get problemVaultBody =>
      'O Chirp guarda a chave no cofre do sistema, e ele não respondeu. Destranque o cofre e tente de novo.';

  @override
  String get problemKeyLostTitle => 'A chave dos seus dados sumiu';

  @override
  String get problemKeyLostBody =>
      'Seus dados continuam neste aparelho, mas a chave que os abre não está mais no cofre do sistema. Sem ela, nada pode ser lido. Você pode apagar e começar de novo.';

  @override
  String get problemNewerTitle => 'Estes dados são de um Chirp mais novo';

  @override
  String get problemNewerBody => 'Atualize o Chirp para abrir.';

  @override
  String get problemStorageTitle => 'O Chirp não conseguiu abrir os dados';

  @override
  String get problemStorageBody =>
      'Algo deu errado ao ler o disco. Tente de novo; se continuar, você pode apagar tudo e começar de novo.';

  @override
  String get tryAgain => 'Tentar de novo';

  @override
  String get eraseEverything => 'Apagar tudo e começar de novo';

  @override
  String get eraseTitle => 'Apagar tudo?';

  @override
  String get eraseBody =>
      'Seu perfil, sua chave e tudo o que o Chirp guarda neste aparelho vão sumir para sempre.';

  @override
  String get eraseConfirm => 'Apagar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get renameTooltip => 'Trocar o nome';

  @override
  String get renameTitle => 'Troque seu nome';

  @override
  String get profileKeyLabel => 'Sua chave';

  @override
  String get profileKeyHelp =>
      'Seus contatos comparam este número para saber que é você mesmo.';

  @override
  String get somethingWentWrong => 'Algo deu errado. Tente de novo.';

  @override
  String get profileTitle => 'Seu perfil';

  @override
  String get addContact => 'Adicionar contato';

  @override
  String get contactsEmptyTitle => 'Nenhum contato ainda';

  @override
  String get contactsEmptyBody =>
      'Mostre seu código para alguém por perto, ou cole o convite que mandaram para você. Na mesma rede, sem precisar de internet.';

  @override
  String get contactPending => 'Esperando o outro aparelho';

  @override
  String get contactVerified => 'Verificado';

  @override
  String get contactUnverified => 'Não verificado';

  @override
  String get contactUnnamed => 'Ainda sem nome';

  @override
  String contactAdded(String name) {
    return '$name agora é um contato.';
  }

  @override
  String get inviteTabShow => 'Meu código';

  @override
  String get inviteTabPaste => 'Colar convite';

  @override
  String get inviteQrLabel => 'Código do convite, em QR';

  @override
  String get inviteQrHelp =>
      'Deixe a outra pessoa ler este código, ou mande o link. Cada código vale uma vez, por 24 horas.';

  @override
  String get inviteCopyLink => 'Copiar o link do convite';

  @override
  String get inviteLinkCopied =>
      'Link copiado. Mande por um canal em que você confia: ele vale uma vez, por 24 horas.';

  @override
  String get inviteNewCode => 'Código novo';

  @override
  String get pasteLabel => 'Link do convite';

  @override
  String get pasteHelp => 'Começa com chirp://invite';

  @override
  String get pasteAdd => 'Adicionar';

  @override
  String get pasteConnecting => 'Conectando';

  @override
  String get qrScanLater =>
      'Ler o código pela câmera chega numa versão seguinte. Por enquanto, cole o link.';

  @override
  String get inviteInvalid =>
      'Isto não é um convite do Chirp, ou falta um pedaço.';

  @override
  String get inviteRefused =>
      'Este convite venceu ou já foi usado. Peça um novo.';

  @override
  String get inviteOwn => 'Este é o seu próprio convite.';

  @override
  String get inviteUnreachable =>
      'Não deu para falar com o outro aparelho. Vocês estão na mesma rede, com o Chirp aberto?';

  @override
  String get inviteAlreadyContact => 'Esta pessoa já é um contato.';

  @override
  String get inviteProtocol =>
      'O outro aparelho respondeu algo inesperado. Tente um convite novo.';

  @override
  String get safetyNumberTitle => 'Número de segurança';

  @override
  String safetyNumberHelp(String name) {
    return 'Compare estes números com $name, pessoalmente ou numa ligação. Se forem iguais, ninguém está no meio da conversa.';
  }

  @override
  String get markVerified => 'Marcar como verificado';

  @override
  String get networkUnavailable => 'A rede local não ligou.';

  @override
  String get messageHint => 'Mensagem';

  @override
  String get send => 'Enviar';

  @override
  String get nudge => 'Chamar atenção';

  @override
  String nudgeSent(String name) {
    return 'Você chamou a atenção de $name';
  }

  @override
  String nudgeReceived(String name) {
    return '$name chamou sua atenção';
  }

  @override
  String get nudgePreview => 'Chamou atenção';

  @override
  String get typing => 'digitando…';

  @override
  String get messageDeleted => 'Mensagem apagada';

  @override
  String get messageEdited => 'editada';

  @override
  String get statusPending => 'Esperando a entrega';

  @override
  String get statusDelivered => 'Entregue';

  @override
  String get statusRead => 'Lida';

  @override
  String get you => 'Você';

  @override
  String get reply => 'Responder';

  @override
  String replyingTo(String name) {
    return 'Respondendo a $name';
  }

  @override
  String get quotedMissing => 'Mensagem que não está neste aparelho';

  @override
  String get editMessage => 'Editar';

  @override
  String get editingMessage => 'Editando a mensagem';

  @override
  String get copyText => 'Copiar o texto';

  @override
  String get textCopied => 'Copiado';

  @override
  String get deleteForMe => 'Apagar para mim';

  @override
  String get deleteForEveryone => 'Apagar para todos';

  @override
  String get reaction1 => 'Curti';

  @override
  String get reaction2 => 'Amei';

  @override
  String get reaction3 => 'Engraçado';

  @override
  String get reaction4 => 'Triste';

  @override
  String get reaction5 => 'Obrigado';

  @override
  String get reaction6 => 'Parabéns';

  @override
  String get react => 'Reagir';

  @override
  String get conversationEmpty => 'Nenhuma mensagem ainda. Diga oi!';

  @override
  String get contactDetails => 'Detalhes do contato';

  @override
  String get searchMessages => 'Buscar mensagens';

  @override
  String get searchNothing => 'Nada encontrado';

  @override
  String get searchHelp =>
      'Palavras de qualquer conversa, sem ligar para acentos ou maiúsculas.';

  @override
  String get messageTooSoon =>
      'Espere alguns segundos antes de fazer isso de novo.';

  @override
  String get messageTooLate => 'O prazo para mudar esta mensagem acabou.';

  @override
  String get messageInvalid => 'A mensagem está vazia ou comprida demais.';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens não lidas',
      one: '$count mensagem não lida',
    );
    return '$_temp0';
  }

  @override
  String get chatSettingsTitle => 'Conversas';

  @override
  String get readReceipts => 'Confirmação de leitura';

  @override
  String get readReceiptsHelp =>
      'Desligada, você também não vê quando leem as suas.';

  @override
  String get typingIndicator => 'Aviso de digitando';

  @override
  String get typingIndicatorHelp =>
      'Desligado, você também não vê quando os outros digitam.';

  @override
  String get messageOptions => 'Opções da mensagem';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceMode => 'Claro ou escuro';

  @override
  String get modeSystem => 'Sistema';

  @override
  String get modeLight => 'Claro';

  @override
  String get modeDark => 'Escuro';

  @override
  String get themeLabel => 'Tema';

  @override
  String get appearanceNotSaved => 'Não deu para gravar a aparência.';

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
  String get conversationPick => 'Escolha uma conversa';

  @override
  String get close => 'Fechar';

  @override
  String get glassEffect => 'Efeito vidro';

  @override
  String get glassEffectHelp =>
      'As barras ficam translúcidas sobre o que passa por baixo. Fica desligado quando o sistema pede menos animação ou mais contraste.';

  @override
  String get themeSystem => 'Cor do sistema';

  @override
  String get networkTitle => 'Rede';

  @override
  String get networkLocalAlways =>
      'A rede local fica sempre ligada: quem está no mesmo Wi-Fi conversa sem nada sair dela.';

  @override
  String get internetToggle => 'Internet';

  @override
  String get internetHelp =>
      'Para conversar com quem está em outra rede. Seus contatos recebem o seu endereço público (o IP), que mostra a sua operadora e mais ou menos a sua cidade.';

  @override
  String get relaysTitle => 'Servidores de retransmissão';

  @override
  String get relaysHelp =>
      'Sem um, só conecta direto, e muitas redes (a do celular, quase sempre) não deixam. O retransmissor vê o seu IP, o dos contatos e quando vocês conversam, e repassa as mensagens já cifradas, sem ler nem guardar. Use o seu ou o de alguém em quem você confia.';

  @override
  String get relayAddress => 'Endereço do retransmissor';

  @override
  String get relayAddressHelp => 'Começa com https://';

  @override
  String get relayAdd => 'Adicionar';

  @override
  String get relayRemove => 'Remover';

  @override
  String get relayInvalid =>
      'Esse endereço não serve. Use um que comece com https://, sem usuário nem senha, até três.';

  @override
  String get relayStatusNone => 'Sem retransmissor: só conexões diretas.';

  @override
  String get relayStatusConnected => 'Conectado ao retransmissor.';

  @override
  String get relayStatusWaiting => 'O retransmissor ainda não respondeu.';

  @override
  String get reachTitle => 'Conexão';

  @override
  String get reachLan => 'Na rede local';

  @override
  String get reachDirect => 'Pela internet, direto';

  @override
  String get reachRelay => 'Pelo retransmissor';

  @override
  String get reachUnreachable => 'Fora de alcance agora';

  @override
  String get reachUnknown => 'Ainda não tentou';

  @override
  String get unreachableLocalOnly =>
      'Fora de alcance na rede local. Se estiver em outra rede, ligue a internet em Seu perfil, Rede. As mensagens esperam aqui.';

  @override
  String get unreachableNoRelay =>
      'Não deu para conectar direto. Sem um servidor de retransmissão, isso só funciona se um dos dois aceitar conexões de fora, e muitas redes (como a do celular) não deixam. As mensagens esperam aqui.';

  @override
  String get unreachableOffline =>
      'O contato parece desligado. As mensagens esperam aqui e saem quando ele aparecer.';

  @override
  String get attachFile => 'Anexar arquivo';

  @override
  String get fileDownload => 'Baixar';

  @override
  String get fileSave => 'Salvar';

  @override
  String get fileRetry => 'Tentar de novo';

  @override
  String get fileSaved => 'Salvo.';

  @override
  String get fileWaiting => 'Esperando o contato';

  @override
  String get fileFailed =>
      'Chegou diferente do que foi mandado e foi descartado.';

  @override
  String get fileInvalid =>
      'Esse arquivo não pode ser mandado: passa de 1 GB, não dá para ler, ou é uma foto da qual não deu para tirar os metadados.';

  @override
  String fileView(String name) {
    return 'Abrir a foto $name';
  }

  @override
  String filePreview(String name) {
    return 'Arquivo: $name';
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
  String get notificationsTitle => 'Notificações';

  @override
  String get notificationsHelp =>
      'O que o sistema mostra quando chega uma mensagem e a conversa não está na tela.';

  @override
  String get notifyOff => 'Desligadas';

  @override
  String get notifyHidden => 'Sem conteúdo';

  @override
  String get notifyHiddenHelp => 'Só \"Nova mensagem\", sem nome nem texto.';

  @override
  String get notifySender => 'Só o nome';

  @override
  String get notifySenderHelp => 'Quem escreveu, sem o texto.';

  @override
  String get notifyFull => 'Nome e mensagem';

  @override
  String get notifyFullHelp =>
      'O texto pode aparecer também na tela bloqueada, se o sistema deixar.';

  @override
  String get notificationNewMessage => 'Nova mensagem';

  @override
  String get notificationOpen => 'Abrir';

  @override
  String get notificationChannel => 'Mensagens';

  @override
  String get backgroundTitle => 'Segundo plano';

  @override
  String get keepRunning => 'Continuar recebendo com a janela fechada';

  @override
  String get keepRunningHelp =>
      'O Psito Chirp fica na bandeja do sistema. Para sair de vez, use Sair no menu dele.';

  @override
  String get startAtLogin => 'Abrir ao entrar no computador';

  @override
  String get startAtLoginHelp => 'Ele começa escondido, na bandeja.';

  @override
  String trayOpen(String name) {
    return 'Abrir o $name';
  }

  @override
  String get trayQuit => 'Sair';

  @override
  String get keepRunningHelpMobile =>
      'Fica uma notificação discreta enquanto o Psito Chirp recebe.';

  @override
  String get receivingNow => 'Recebendo mensagens';

  @override
  String get batteryTitle => 'Economia de bateria';

  @override
  String get batteryHelp =>
      'Com o celular parado, o Android pode atrasar as mensagens. Deixar o Psito Chirp fora da economia evita isso, e gasta um pouco mais de bateria.';

  @override
  String get batteryAllow => 'Deixar fora';
}

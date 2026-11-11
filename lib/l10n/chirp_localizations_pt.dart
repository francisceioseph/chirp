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
}

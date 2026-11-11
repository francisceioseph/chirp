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
  String get homeNextPhase =>
      'Seu perfil e sua chave estão prontos. As conversas chegam na próxima fase.';

  @override
  String get somethingWentWrong => 'Algo deu errado. Tente de novo.';
}

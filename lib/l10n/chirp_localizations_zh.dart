// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ChirpLocalizationsZh extends ChirpLocalizations {
  ChirpLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Psito Chirp';

  @override
  String get welcomeTitle => '只属于你们之间的对话';

  @override
  String get welcomeBody => '没有账号，没有服务器，没有日志。你的消息只存在于你的设备上。';

  @override
  String coreVersion(String version, int protocol) {
    return '核心 $version · 协议 $protocol';
  }

  @override
  String get coreUnavailable => '安全核心无法启动。';

  @override
  String get loading => '正在打开 Chirp';

  @override
  String get nameLabel => '你的名字';

  @override
  String get nameHelp => '只有你的联系人能看到，而且始终加密。';

  @override
  String get nameInvalid => '请输入不超过 64 个字符的名字，只占一行。';

  @override
  String get onboardingCreate => '创建我的资料';

  @override
  String get passphraseCreateTitle => '用密码短语保护 Chirp';

  @override
  String get passphraseCreateBody =>
      '这个系统没有可供 Chirp 保存密钥的钥匙串，所以你的数据将用密码短语锁住。如果忘记了，就无法找回。';

  @override
  String get passphraseUnlockTitle => '解锁 Chirp';

  @override
  String get passphraseLabel => '密码短语';

  @override
  String get passphraseConfirmLabel => '再输入一次密码短语';

  @override
  String get passphraseShow => '显示密码短语';

  @override
  String get passphraseHide => '隐藏密码短语';

  @override
  String passphraseTooShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '请至少使用 $count 个字符。',
    );
    return '$_temp0';
  }

  @override
  String get passphraseMismatch => '两次输入的密码短语不一致。';

  @override
  String get passphraseWrong => '这个密码短语打不开 Chirp。';

  @override
  String get passphraseCreate => '用这个密码短语锁住';

  @override
  String get passphraseUnlock => '解锁';

  @override
  String get passphraseForgot => '我忘记了密码短语';

  @override
  String get problemCoreBody => '应用的文件可能不完整。请重新安装 Chirp。';

  @override
  String get problemVaultTitle => '钥匙串没有响应';

  @override
  String get problemVaultBody => 'Chirp 把密钥保存在系统钥匙串里，但它没有响应。请解锁后再试一次。';

  @override
  String get problemKeyLostTitle => '你的数据的密钥不见了';

  @override
  String get problemKeyLostBody =>
      '你的数据还在这台设备上，但打开它的密钥已经不在系统钥匙串里了。没有它，什么都读不出来。你可以全部抹掉，重新开始。';

  @override
  String get problemNewerTitle => '这些数据来自更新版本的 Chirp';

  @override
  String get problemNewerBody => '请更新 Chirp 后再打开。';

  @override
  String get problemStorageTitle => 'Chirp 无法打开它的数据';

  @override
  String get problemStorageBody => '读取磁盘时出了问题。请再试一次；如果一直这样，你可以全部抹掉，重新开始。';

  @override
  String get tryAgain => '再试一次';

  @override
  String get eraseEverything => '全部抹掉，重新开始';

  @override
  String get eraseTitle => '全部抹掉？';

  @override
  String get eraseBody => '你的资料、你的密钥，以及 Chirp 在这台设备上保存的一切都将永远消失。';

  @override
  String get eraseConfirm => '抹掉';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get renameTooltip => '更改名字';

  @override
  String get renameTitle => '更改你的名字';

  @override
  String get profileKeyLabel => '你的密钥';

  @override
  String get profileKeyHelp => '你的联系人会核对这串数字，以确认真的是你。';

  @override
  String get homeNextPhase => '你的资料和密钥已经就绪。对话将在下一阶段到来。';

  @override
  String get somethingWentWrong => '出了点问题。请再试一次。';
}

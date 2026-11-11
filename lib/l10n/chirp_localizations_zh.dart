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
  String get welcomeBody => '无需账号，没有服务器，没有日志。你的消息只保存在你的设备上。';

  @override
  String coreVersion(String version, int protocol) {
    return '核心 $version · 协议 $protocol';
  }

  @override
  String get coreUnavailable => '安全核心无法启动。';

  @override
  String get foundationNote => '这是新版 Chirp 的基础。对话功能将在后续阶段推出。';
}

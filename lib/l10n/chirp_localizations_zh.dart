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
  String get somethingWentWrong => '出了点问题。请再试一次。';

  @override
  String get profileTitle => '你的资料';

  @override
  String get addContact => '添加联系人';

  @override
  String get contactsEmptyTitle => '还没有联系人';

  @override
  String get contactsEmptyBody => '把你的二维码给附近的人看，或者粘贴别人发给你的邀请。在同一个网络里，不需要互联网。';

  @override
  String get contactPending => '正在等待另一台设备';

  @override
  String get contactVerified => '已验证';

  @override
  String get contactUnverified => '未验证';

  @override
  String get contactUnnamed => '还没有名字';

  @override
  String contactAdded(String name) {
    return '$name 现在是你的联系人了。';
  }

  @override
  String get inviteTabShow => '我的二维码';

  @override
  String get inviteTabPaste => '粘贴邀请';

  @override
  String get inviteQrLabel => '邀请二维码';

  @override
  String get inviteQrHelp => '让对方扫描这个二维码，或者把链接发给对方。每个二维码只能用一次，24 小时内有效。';

  @override
  String get inviteCopyLink => '复制邀请链接';

  @override
  String get inviteLinkCopied => '链接已复制。请通过你信任的渠道发送：它只能用一次，24 小时内有效。';

  @override
  String get inviteNewCode => '新的二维码';

  @override
  String get pasteLabel => '邀请链接';

  @override
  String get pasteHelp => '以 chirp://invite 开头';

  @override
  String get pasteAdd => '添加';

  @override
  String get pasteConnecting => '正在连接';

  @override
  String get qrScanLater => '用摄像头扫描二维码将在之后的版本中提供。现在请粘贴链接。';

  @override
  String get inviteInvalid => '这不是 Chirp 邀请，或者缺了一部分。';

  @override
  String get inviteRefused => '这个邀请已过期或已被使用。请向对方要一个新的。';

  @override
  String get inviteOwn => '这是你自己的邀请。';

  @override
  String get inviteUnreachable => '无法连接到另一台设备。你们是否在同一个网络中，并且都打开了 Chirp？';

  @override
  String get inviteAlreadyContact => '这个人已经是联系人了。';

  @override
  String get inviteProtocol => '另一台设备的回应不符合预期。请换一个新的邀请。';

  @override
  String get safetyNumberTitle => '安全码';

  @override
  String safetyNumberHelp(String name) {
    return '请与 $name 当面或通过电话核对这些数字。如果一致，就没有人在你们的对话中间。';
  }

  @override
  String get markVerified => '标记为已验证';

  @override
  String get networkUnavailable => '本地网络没有启动。';

  @override
  String get messageHint => '消息';

  @override
  String get send => '发送';

  @override
  String get nudge => '提醒对方';

  @override
  String nudgeSent(String name) {
    return '你提醒了 $name';
  }

  @override
  String nudgeReceived(String name) {
    return '$name 在提醒你';
  }

  @override
  String get nudgePreview => '发出了提醒';

  @override
  String get typing => '正在输入…';

  @override
  String get messageDeleted => '此消息已删除';

  @override
  String get messageEdited => '已编辑';

  @override
  String get statusPending => '等待送达';

  @override
  String get statusDelivered => '已送达';

  @override
  String get statusRead => '已读';

  @override
  String get you => '你';

  @override
  String get reply => '回复';

  @override
  String replyingTo(String name) {
    return '回复 $name';
  }

  @override
  String get quotedMissing => '此设备上没有这条消息';

  @override
  String get editMessage => '编辑';

  @override
  String get editingMessage => '正在编辑消息';

  @override
  String get copyText => '复制文本';

  @override
  String get textCopied => '已复制';

  @override
  String get deleteForMe => '为我删除';

  @override
  String get deleteForEveryone => '为所有人删除';

  @override
  String get reaction1 => '赞';

  @override
  String get reaction2 => '爱心';

  @override
  String get reaction3 => '好笑';

  @override
  String get reaction4 => '难过';

  @override
  String get reaction5 => '谢谢';

  @override
  String get reaction6 => '庆祝';

  @override
  String get react => '回应';

  @override
  String get conversationEmpty => '还没有消息。打个招呼吧！';

  @override
  String get contactDetails => '联系人详情';

  @override
  String get searchMessages => '搜索消息';

  @override
  String get searchNothing => '未找到';

  @override
  String get searchHelp => '搜索所有对话中的词语，不区分大小写和重音。';

  @override
  String get messageTooSoon => '请等几秒再试。';

  @override
  String get messageTooLate => '修改这条消息的时限已过。';

  @override
  String get messageInvalid => '消息为空或太长。';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条未读消息',
    );
    return '$_temp0';
  }

  @override
  String get chatSettingsTitle => '对话';

  @override
  String get readReceipts => '已读回执';

  @override
  String get readReceiptsHelp => '关闭后，你也看不到别人何时读了你的消息。';

  @override
  String get typingIndicator => '输入提示';

  @override
  String get typingIndicatorHelp => '关闭后，你也看不到别人正在输入。';

  @override
  String get messageOptions => '消息选项';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearanceMode => '浅色或深色';

  @override
  String get modeSystem => '跟随系统';

  @override
  String get modeLight => '浅色';

  @override
  String get modeDark => '深色';

  @override
  String get themeLabel => '主题';

  @override
  String get appearanceNotSaved => '无法保存外观。';

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
  String get conversationPick => '选择一个对话';

  @override
  String get close => '关闭';

  @override
  String get glassEffect => '玻璃效果';

  @override
  String get glassEffectHelp => '栏在滚动内容上方变为半透明。系统要求减少动画或提高对比度时关闭。';

  @override
  String get themeSystem => '系统颜色';

  @override
  String get networkTitle => '网络';

  @override
  String get networkLocalAlways => '本地网络始终开启：同一 Wi-Fi 下的人聊天时，数据不会离开这个网络。';

  @override
  String get internetToggle => '互联网';

  @override
  String get internetHelp =>
      '用于和其他网络中的人聊天。你的联系人会收到你的公网地址（IP），它会显示你的运营商和大致所在城市。';

  @override
  String get relaysTitle => '中继服务器';

  @override
  String get relaysHelp =>
      '没有中继时只能直连，而很多网络（移动网络几乎总是）不允许直连。中继能看到你和联系人的 IP 以及你们何时聊天，它转发已加密的消息，不读取也不保存。请使用你自己的，或你信任的人运行的中继。';

  @override
  String get relayAddress => '中继地址';

  @override
  String get relayAddressHelp => '以 https:// 开头';

  @override
  String get relayAdd => '添加';

  @override
  String get relayRemove => '移除';

  @override
  String get relayInvalid => '这个地址不可用。请使用以 https:// 开头、不含用户名和密码的地址，最多三个。';

  @override
  String get relayStatusNone => '没有中继：只能直连。';

  @override
  String get relayStatusConnected => '已连接到中继。';

  @override
  String get relayStatusWaiting => '中继还没有响应。';

  @override
  String get reachTitle => '连接';

  @override
  String get reachLan => '在本地网络';

  @override
  String get reachDirect => '通过互联网直连';

  @override
  String get reachRelay => '通过中继';

  @override
  String get reachUnreachable => '当前无法连接';

  @override
  String get reachUnknown => '尚未尝试';

  @override
  String get unreachableLocalOnly =>
      '在本地网络中无法连接。如果对方在其他网络，请在“你的资料”的“网络”中打开互联网。消息会在这里等待。';

  @override
  String get unreachableNoRelay =>
      '无法直接连接。没有中继服务器时，只有一方能接受外部连接才行，而很多网络（比如移动网络）不允许。消息会在这里等待。';

  @override
  String get unreachableOffline => '联系人似乎不在线。消息会在这里等待，对方上线后发出。';
}

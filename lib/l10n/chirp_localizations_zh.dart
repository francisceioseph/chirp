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
  String get contactsEmptyTitle => '这里还没有人';

  @override
  String get contactsEmptyBody => '想聊天，就互换邀请。消息加密后直接从一台设备发到另一台，不经过任何服务器。';

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
  String get bluetoothToggle => '蓝牙';

  @override
  String get bluetoothHelp =>
      '无需任何网络，与附近（几十米内）的联系人交谈。开启期间，附近扫描的人能知道这里有人在用 Chirp，但不知道是谁：只有你的联系人能认出你。会更耗电。';

  @override
  String get bluetoothUnavailable => '蓝牙没有启动。请检查系统中蓝牙是否已打开。';

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
  String get reachBluetooth => '在附近，通过蓝牙';

  @override
  String get unreachableLocalOnly =>
      '在本地网络中无法连接。如果对方在其他网络，请在“你的资料”的“网络”中打开互联网。消息会在这里等待。';

  @override
  String get unreachableNoRelay =>
      '无法直接连接。没有中继服务器时，只有一方能接受外部连接才行，而很多网络（比如移动网络）不允许。消息会在这里等待。';

  @override
  String get unreachableOffline => '联系人似乎不在线。消息会在这里等待，对方上线后发出。';

  @override
  String get attachFile => '附加文件';

  @override
  String get fileDownload => '下载';

  @override
  String get fileSave => '保存';

  @override
  String get fileRetry => '重试';

  @override
  String get fileSaved => '已保存。';

  @override
  String get fileWaiting => '正在等待联系人';

  @override
  String get fileFailed => '收到的内容与发送的不一致，已丢弃。';

  @override
  String get fileInvalid => '这个文件无法发送：超过 1 GB、无法读取，或是无法去除元数据的照片。';

  @override
  String fileView(String name) {
    return '打开照片 $name';
  }

  @override
  String filePreview(String name) {
    return '文件：$name';
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
  String get notificationsTitle => '通知';

  @override
  String get notificationsHelp => '当消息到达而对话不在屏幕上时，系统显示的内容。';

  @override
  String get notifyOff => '关闭';

  @override
  String get notifyHidden => '无内容';

  @override
  String get notifyHiddenHelp => '只显示“新消息”，不含名字和文字。';

  @override
  String get notifySender => '仅名字';

  @override
  String get notifySenderHelp => '谁发来的，不含文字。';

  @override
  String get notifyFull => '名字和消息';

  @override
  String get notifyFullHelp => '如果系统允许，文字也可能显示在锁屏上。';

  @override
  String get notificationNewMessage => '新消息';

  @override
  String get notificationOpen => '打开';

  @override
  String get notificationChannel => '消息';

  @override
  String get backgroundTitle => '后台';

  @override
  String get keepRunning => '关闭窗口后继续接收';

  @override
  String get keepRunningHelp => 'Psito Chirp 会留在系统托盘中。要完全退出，请使用其菜单中的“退出”。';

  @override
  String get startAtLogin => '登录时打开';

  @override
  String get startAtLoginHelp => '启动时隐藏在托盘中。';

  @override
  String trayOpen(String name) {
    return '打开 $name';
  }

  @override
  String get trayQuit => '退出';

  @override
  String get keepRunningHelpMobile => 'Psito Chirp 接收消息时会保留一条低调的通知。';

  @override
  String get receivingNow => '正在接收消息';

  @override
  String get batteryTitle => '省电';

  @override
  String get batteryHelp =>
      '手机闲置时，Android 可能会延迟消息。让 Psito Chirp 不受省电限制可以避免这种情况，但会多耗一点电。';

  @override
  String get batteryAllow => '不受限制';

  @override
  String get downloadsTitle => '下载';

  @override
  String get downloadsHelp => '不超过此大小的文件一到就会下载。更大的文件会等你点“下载”。';

  @override
  String get autoDownloadNever => '从不自动';

  @override
  String get autoDownloadSmall => '最多 4 MB';

  @override
  String get autoDownloadMedium => '最多 32 MB';

  @override
  String get autoDownloadLarge => '最多 256 MB';

  @override
  String get onlyVerified => '仅限已验证的联系人';

  @override
  String get onlyVerifiedHelp => '来自未核对安全码的联系人的文件都会等待。';

  @override
  String get voiceRecord => '录制语音消息';

  @override
  String get voiceRecording => '正在录音';

  @override
  String get voiceDiscard => '放弃';

  @override
  String get voiceSend => '发送语音消息';

  @override
  String get voiceNote => '语音消息';

  @override
  String get voicePlay => '播放语音消息';

  @override
  String get voiceStop => '停止';

  @override
  String get voicePreview => '语音消息';

  @override
  String get voiceTooShort => '太短了：请再多录一会儿。';

  @override
  String get audioUnavailable => '没有麦克风或扬声器，或系统不允许使用。';

  @override
  String get microphoneDenied => 'Psito Chirp 需要麦克风才能录音。你可以在系统设置中允许。';

  @override
  String get emptyShowCode => '显示我的二维码';

  @override
  String get emptyShowCodeBody => '在一起？让对方扫描二维码。这是最安全的方式：你们一开始就已验证。';

  @override
  String get emptyUseLink => '使用邀请链接';

  @override
  String get emptyUseLinkBody => '相隔很远？用任何方式发送你的链接，或粘贴收到的链接。只能用一次，24 小时内有效。';

  @override
  String get emptyPromise => '无需账号，无需手机号，没有日志。';

  @override
  String get contactsWillAppear => '你的联系人会显示在这里';

  @override
  String get filterAll => '全部';

  @override
  String get filterUnread => '未读';

  @override
  String get filterVerified => '已验证';

  @override
  String get filterEmpty => '此筛选下没有内容。';

  @override
  String groupReachable(int count) {
    return '可联系 · $count';
  }

  @override
  String groupUnreachable(int count) {
    return '无法联系 · $count';
  }

  @override
  String sayHi(String name) {
    return '跟 $name 打个招呼';
  }

  @override
  String get sayHiUnverified => '你们还没有核对安全码。可以聊天，但见面时请核对一下。';

  @override
  String get e2eVerified => '端到端加密。你们已当面核对过安全码。';

  @override
  String get e2eUnverified => '端到端加密。见面时请核对安全码。';

  @override
  String get checkCode => '核对安全码';

  @override
  String get inviteValidity => '仅可使用一次，24 小时内有效';

  @override
  String get pasteStep1 => '通过你们平时聊天的方式，向对方要链接。';

  @override
  String get pasteStep2 => '粘贴到这里。Chirp 会在局域网中寻找对方，开启互联网后也会在互联网上寻找。';

  @override
  String get pasteStep3 => '对方会显示为未验证：见面时请核对安全码。';

  @override
  String get pasteTip => '链接只能用一次，24 小时后失效。不要放在公开的地方。';

  @override
  String get statusInMailbox => '在对方的信箱中等待';

  @override
  String get mailboxTitle => '信箱';

  @override
  String get mailboxHelp =>
      '信箱是你自己或你信任的人运行的小型服务器，在此设备关机时保存联系人发来的内容，直到你打开 Chirp。消息到达时已经加密：它能看到谁在何时留下了内容，但看不到内容本身。文件仍需要双方同时在线。';

  @override
  String get mailboxCode => '信箱代码';

  @override
  String get mailboxCodeHelp =>
      '在服务器上运行 chirp-mailbox pair，并粘贴它显示的代码。代码只能使用一次，有效期 24 小时。';

  @override
  String get mailboxPair => '连接';

  @override
  String get mailboxPaired => '信箱已连接';

  @override
  String get mailboxStatusWaiting => '尚未检查。';

  @override
  String mailboxStatusChecked(String time) {
    return '上次检查：$time。';
  }

  @override
  String get mailboxStatusUnreachable => '信箱没有响应。发给你的消息可能在联系人那里等待。';

  @override
  String get mailboxUnpair => '断开';

  @override
  String get mailboxUnpairTitle => '断开信箱？';

  @override
  String get mailboxUnpairBody => '其中等待的内容将会丢失，联系人也不会再往那里留言。你可以用新的代码重新连接。';

  @override
  String get mailboxInvalid => '这个代码无效。请粘贴完整的 chirp://mailbox# 链接。';

  @override
  String get mailboxRefused => '信箱拒绝了这个代码。代码只能使用一次，24 小时后过期：请生成新的代码。';

  @override
  String get mailboxUnreachable => '无法连接到信箱。关闭互联网时，只有本地网络上的信箱可用。';

  @override
  String get contactRequestLeft =>
      '对方不在线，所以你的请求已放在对方的信箱中。对方打开 Chirp 后就会成为你的联系人。';

  @override
  String get photoTitle => '头像';

  @override
  String get photoHelp =>
      '只有你允许的联系人能看到，其他人都看不到。照片会裁成正方形，离开此设备时不带位置或原文件的任何其他数据。';

  @override
  String get photoChoose => '选择照片';

  @override
  String get photoChange => '更换照片';

  @override
  String get photoRemove => '移除照片';

  @override
  String get photoWhoSees => '谁能看到';

  @override
  String get photoEveryone => '我的所有联系人';

  @override
  String get photoChosen => '仅我选择的联系人';

  @override
  String get photoChosenHelp => '在每个联系人的页面上选择。';

  @override
  String get photoNobody => '没有人';

  @override
  String get photoRevokeNote => '移除某人后，你的照片会从对方的 Chirp 中删除，但对方可能已经保存了副本。';

  @override
  String get photoAllowed => '可以看到我的头像';

  @override
  String get photoAllowedHelp => '关闭后，你的照片会从对方的 Chirp 中删除。';

  @override
  String get groupNew => '新建群组';

  @override
  String get groupName => '群组名称';

  @override
  String get groupPickMembers => '成员';

  @override
  String get groupCreate => '创建';

  @override
  String get groupAdd => '添加';

  @override
  String get groupNoOneToAdd => '还没有可以添加的联系人。先添加联系人，再把他们拉进群组。';

  @override
  String get groupHelp => '每位成员都会直接从你的设备收到加密的消息，不经过服务器。目前只有同时也是你联系人的成员能收到。';

  @override
  String get groupLabel => '群组';

  @override
  String get groupClosed => '你已不在这个群组中。';

  @override
  String groupMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你和另外 $count 人',
      zero: '只有你',
    );
    return '$_temp0';
  }

  @override
  String get groupAdmin => '管理员';

  @override
  String get groupNotConnected => '不是你的联系人：你的消息暂时到不了对方';

  @override
  String get groupAddMembers => '添加成员';

  @override
  String get groupRemove => '移出群组';

  @override
  String get groupRename => '重命名群组';

  @override
  String get groupLeave => '退出群组';

  @override
  String groupLeaveTitle(String name) {
    return '退出 $name？';
  }

  @override
  String get groupLeaveBody => '成员会知道你已退出。消息会留在这里，但你不能再在这个群组里收发消息。';

  @override
  String get groupNotAdmin => '只有群组管理员可以这样做。';

  @override
  String get groupTooMany => '一个群组最多 64 名成员。';
}

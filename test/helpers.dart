// O apoio dos testes: um núcleo e um cofre falsos, em memória, e a montagem do app.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/chirp_app.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:psito_chirp/src/platform/background.dart';
import 'package:psito_chirp/src/platform/file_picker.dart';
import 'package:psito_chirp/src/platform/key_vault.dart';
import 'package:psito_chirp/src/platform/notifier.dart';

const testFingerprint = '12345 67890 13579 24680 11223 34455';

/// O núcleo em memória. O "banco" lembra a chave ou a senha com que nasceu, e recusa
/// as outras como o de verdade.
class FakeCore implements ChirpCore {
  FakeCore({
    this.info = const CoreInfo(version: '9.9.9', protocol: 1),
    this.failOpen,
  });

  @override
  final CoreInfo? info;

  /// Uma falha forçada ao abrir o banco.
  CoreFailure? failOpen;

  Uint8List? storedKey;
  String? storedPassphrase;
  FakeStore? store;
  int _keys = 0;

  @override
  int get minPassphraseChars => 8;

  @override
  StoreState storeState() => store == null
      ? StoreState.missing
      : storedPassphrase != null
      ? StoreState.passphrase
      : StoreState.keyInVault;

  @override
  Uint8List newStoreKey() => Uint8List.fromList(List.filled(32, ++_keys));

  @override
  Future<ProfileStore> openWithKey(Uint8List key) async {
    if (failOpen case final failure?) throw CoreException(failure);
    if (store == null) {
      storedKey = key;
      return store = FakeStore();
    }
    if (!listEquals(storedKey, key)) {
      throw const CoreException(CoreFailure.wrongKey);
    }
    return store!;
  }

  @override
  Future<ProfileStore> createWithPassphrase(String passphrase) async {
    if (store != null) throw const CoreException(CoreFailure.alreadyExists);
    if (passphrase.length < minPassphraseChars) {
      throw const CoreException(CoreFailure.weakPassphrase);
    }
    storedPassphrase = passphrase;
    return store = FakeStore();
  }

  @override
  Future<ProfileStore> openWithPassphrase(String passphrase) async {
    if (failOpen case final failure?) throw CoreException(failure);
    if (passphrase != storedPassphrase) {
      throw const CoreException(CoreFailure.wrongKey);
    }
    return store!;
  }

  @override
  Future<void> wipe() async {
    store = null;
    storedKey = null;
    storedPassphrase = null;
  }
}

class FakeStore implements ProfileStore {
  Profile? saved;

  /// A rede falsa: os contatos, os convites feitos e o que a rede responde.
  final List<Contact> people = [];
  final List<String> invites = [];
  bool networkStarted = false;
  CoreFailure? networkFailure;
  final _events = StreamController<CoreEvent>.broadcast();
  final Map<int, bool> _verified = {};

  /// As mensagens, de todas as conversas, na ordem.
  final List<ChatMessage> sent = [];
  int _nextMessage = 1;

  /// Quantas vezes a UI avisou que estava digitando.
  int typingCalls = 0;
  ChatSettings settings = const ChatSettings(readReceipts: true, typing: true);
  Appearance savedAppearance = const Appearance();
  NotificationMode notifications = NotificationMode.sender;
  DownloadPolicy autoDownload = const DownloadPolicy();
  bool running = true;
  NetworkSettings network = const NetworkSettings();

  /// Quantas vezes a rede foi religada por mudar os ajustes.
  int networkRestarts = 0;

  /// Algum retransmissor respondeu (no falso, quem testa diz).
  bool relayConnected = false;

  /// Se gravar a aparência falha (o disco cheio).
  bool appearanceFails = false;

  /// O "agora" das mensagens.
  DateTime now = DateTime(2026, 11, 11, 10, 30);

  /// Alguém leu um convite nosso.
  void someoneJoined(String name, {bool verified = true}) {
    final contact = Contact(
      id: people.length + 1,
      displayName: name,
      avatarSeed: people.length * 7919,
      verified: verified,
      established: true,
    );
    people.add(contact);
    _events.add(CoreEvent(CoreEventKind.contact, contact.id));
  }

  ChatMessage _put(ChatMessage message) {
    final i = sent.indexWhere((m) => m.id == message.id);
    if (i < 0) {
      sent.add(message);
    } else {
      sent[i] = message;
    }
    return message;
  }

  ChatMessage _new(
    int contactId, {
    required bool outgoing,
    String text = '',
    MessageKind kind = MessageKind.text,
    int? replyTo,
    ChatFile? file,
  }) => _put(
    ChatMessage(
      id: _nextMessage++,
      contactId: contactId,
      outgoing: outgoing,
      kind: kind,
      text: text,
      replyTo: replyTo,
      sentAt: now,
      receivedAt: now,
      status: MessageStatus.pending,
      canEdit: outgoing && kind == MessageKind.text,
      canDeleteForEveryone: outgoing && kind != MessageKind.nudge,
      file: file,
    ),
  );

  ChatMessage _byId(int id) => sent.firstWhere(
    (m) => m.id == id,
    orElse: () => throw const CoreException(CoreFailure.unknownMessage),
  );

  ChatMessage _copy(
    ChatMessage m, {
    String? text,
    MessageStatus? status,
    bool? edited,
    bool? deleted,
    int? myReaction,
    int? theirReaction,
    ChatFile? file,
  }) => ChatMessage(
    id: m.id,
    contactId: m.contactId,
    outgoing: m.outgoing,
    kind: m.kind,
    text: text ?? m.text,
    replyTo: m.replyTo,
    sentAt: m.sentAt,
    receivedAt: m.receivedAt,
    status: status ?? m.status,
    edited: edited ?? m.edited,
    deleted: deleted ?? m.deleted,
    myReaction: myReaction ?? m.myReaction,
    theirReaction: theirReaction ?? m.theirReaction,
    canEdit: (deleted ?? m.deleted) ? false : m.canEdit,
    canDeleteForEveryone: (deleted ?? m.deleted)
        ? false
        : m.canDeleteForEveryone,
    file: (deleted ?? m.deleted) ? null : (file ?? m.file),
  );

  /// Chega uma mensagem do contato.
  ChatMessage incoming(int contactId, String text, {int? replyTo}) {
    final m = _new(contactId, outgoing: false, text: text, replyTo: replyTo);
    _events.add(CoreEvent(CoreEventKind.messages, contactId));
    return m;
  }

  /// O conteúdo de cada arquivo (pelo id da mensagem), e onde cada um foi salvo.
  final Map<int, Uint8List> fileContents = {};
  final Map<int, String> savedFiles = {};

  /// Chega um arquivo do contato: [state] diz se já baixou.
  ChatMessage theySendFile(
    int contactId,
    String name, {
    int size = 2048,
    FileState state = FileState.downloading,
    Uint8List? thumbnail,
    Uint8List? content,
  }) {
    final m = _new(
      contactId,
      outgoing: false,
      kind: MessageKind.file,
      text: name,
      file: ChatFile(
        name: name,
        size: size,
        mime: _mime(name),
        thumbnail: thumbnail,
        chunks: 4,
        received: state == FileState.done ? 4 : 0,
        state: state,
      ),
    );
    if (content != null) fileContents[m.id] = content;
    _events.add(CoreEvent(CoreEventKind.messages, contactId));
    return m;
  }

  /// O download anda: [received] de 4 fatias (4 é inteiro).
  void fileProgress(int id, int received) {
    final m = _byId(id);
    _put(
      _copy(
        m,
        file: ChatFile(
          name: m.file!.name,
          size: m.file!.size,
          mime: m.file!.mime,
          thumbnail: m.file!.thumbnail,
          chunks: 4,
          received: received,
          state: received >= 4 ? FileState.done : FileState.downloading,
        ),
      ),
    );
    _events.add(CoreEvent(CoreEventKind.messages, m.contactId));
  }

  static String _mime(String name) => switch (name.split('.').last) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    _ => 'application/octet-stream',
  };

  /// O contato chama atenção.
  void theyNudge(int contactId) {
    _new(contactId, outgoing: false, kind: MessageKind.nudge);
    _events.add(CoreEvent(CoreEventKind.messages, contactId));
  }

  /// O contato está digitando.
  void theyType(int contactId) =>
      _events.add(CoreEvent(CoreEventKind.typing, contactId));

  /// A rede entrega (e o contato lê) as minhas.
  void deliver(int contactId, {bool read = false}) {
    for (final m in [...sent]) {
      if (m.contactId == contactId && m.outgoing) {
        _put(
          _copy(m, status: read ? MessageStatus.read : MessageStatus.delivered),
        );
      }
    }
    _events.add(CoreEvent(CoreEventKind.messages, contactId));
  }

  /// O contato reage a uma mensagem.
  void theyReact(int id, int kind) {
    final m = _put(_copy(_byId(id), theirReaction: kind));
    _events.add(CoreEvent(CoreEventKind.messages, m.contactId));
  }

  @override
  Stream<CoreEvent> events() => _events.stream;

  @override
  Future<List<Conversation>> conversations() async {
    final all = await contacts();
    final list = [
      for (final c in all)
        Conversation(
          contact: c,
          last: sent.where((m) => m.contactId == c.id).lastOrNull,
          unread: sent.where((m) => m.contactId == c.id && m.unread).length,
        ),
    ];
    list.sort((a, b) => (b.last?.id ?? 0).compareTo(a.last?.id ?? 0));
    return list;
  }

  @override
  Future<List<ChatMessage>> messages(
    int contactId, {
    int? before,
    int limit = 100,
  }) async {
    final all = [
      for (final m in sent)
        if (m.contactId == contactId && (before == null || m.id < before)) m,
    ];
    return all.length <= limit ? all : all.sublist(all.length - limit);
  }

  void _established(int contactId) {
    if (!people.any((c) => c.id == contactId && c.established)) {
      throw const CoreException(CoreFailure.unknownContact);
    }
    if (groups[contactId]?.active == false) {
      throw const CoreException(CoreFailure.notAMember);
    }
  }

  @override
  Future<ChatMessage> sendText(
    int contactId,
    String text, {
    int? replyTo,
  }) async {
    _established(contactId);
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 4000) {
      throw const CoreException(CoreFailure.invalidMessage);
    }
    return _new(contactId, outgoing: true, text: trimmed, replyTo: replyTo);
  }

  DateTime? _lastNudge;

  @override
  Future<ChatMessage> sendNudge(int contactId) async {
    _established(contactId);
    final last = _lastNudge;
    if (last != null && now.difference(last) < const Duration(seconds: 10)) {
      throw const CoreException(CoreFailure.tooSoon);
    }
    _lastNudge = now;
    return _new(contactId, outgoing: true, kind: MessageKind.nudge);
  }

  @override
  Future<ChatMessage> sendFile(int contactId, String path) async {
    _established(contactId);
    final name = path.split(RegExp(r'[/\\]')).last;
    if (name.endsWith('.bad')) {
      throw const CoreException(CoreFailure.invalidFile);
    }
    return _new(
      contactId,
      outgoing: true,
      kind: MessageKind.file,
      text: name,
      file: ChatFile(name: name, size: 1500, mime: _mime(name)),
    );
  }

  /// Quantas vezes pediram para baixar.
  int downloads = 0;

  @override
  Future<void> downloadFile(int messageId) async {
    downloads++;
    final m = _byId(messageId);
    final f = m.file!;
    _put(
      _copy(
        m,
        file: ChatFile(
          name: f.name,
          size: f.size,
          mime: f.mime,
          thumbnail: f.thumbnail,
          chunks: f.chunks,
          state: FileState.downloading,
        ),
      ),
    );
    _events.add(CoreEvent(CoreEventKind.messages, m.contactId));
  }

  @override
  Future<void> saveFile(int messageId, String path) async {
    if (_byId(messageId).file?.state != FileState.done) {
      throw const CoreException(CoreFailure.unknownMessage);
    }
    savedFiles[messageId] = path;
  }

  @override
  Future<Uint8List> fileBytes(int messageId) async =>
      fileContents[messageId] ??
      (throw const CoreException(CoreFailure.unknownMessage));

  // As notas de voz: sem som de verdade. [audio] falso faz o microfone e o
  // alto-falante faltarem; [recordedMs] é quanto a próxima gravação dura.

  bool audio = true;
  bool recordingVoice = false;
  int recordedMs = 3000;
  int voicesSent = 0;
  StreamController<VoiceProgress>? playback;
  int? playingVoice;

  @override
  Future<void> startVoice() async {
    if (!audio) throw const CoreException(CoreFailure.noAudio);
    recordingVoice = true;
  }

  @override
  Future<void> cancelVoice() async => recordingVoice = false;

  @override
  Future<ChatMessage> sendVoice(int contactId) async {
    _established(contactId);
    if (!recordingVoice) throw const CoreException(CoreFailure.noAudio);
    recordingVoice = false;
    if (recordedMs < 500) throw const CoreException(CoreFailure.invalidMessage);
    voicesSent++;
    return _new(
      contactId,
      outgoing: true,
      kind: MessageKind.file,
      text: 'voice.opus',
      file: const ChatFile(
        name: 'voice.opus',
        size: 9000,
        mime: 'audio/ogg; codecs=opus',
        voice: true,
      ),
    );
  }

  @override
  Future<Duration> voiceDuration(int messageId) async =>
      Duration(milliseconds: recordedMs);

  @override
  Stream<VoiceProgress> playVoice(int messageId) {
    if (!audio) {
      return Stream.error(const CoreException(CoreFailure.noAudio));
    }
    playback?.close();
    playingVoice = messageId;
    final controller = playback = StreamController<VoiceProgress>();
    controller.add(
      VoiceProgress(messageId: messageId, position: Duration.zero),
    );
    return controller.stream;
  }

  @override
  Future<void> stopVoice() async {
    playingVoice = null;
    await playback?.close();
    playback = null;
  }

  @override
  Future<ChatMessage> editMessage(int id, String text) async {
    final m = _byId(id);
    if (!m.canEdit) throw const CoreException(CoreFailure.tooLate);
    return _put(_copy(m, text: text.trim(), edited: true));
  }

  @override
  Future<ChatMessage> deleteForEveryone(int id) async {
    final m = _byId(id);
    if (!m.canDeleteForEveryone) throw const CoreException(CoreFailure.tooLate);
    return _put(
      _copy(m, text: '', deleted: true, myReaction: 0, theirReaction: 0),
    );
  }

  @override
  Future<void> deleteForMe(int id) async {
    _byId(id);
    sent.removeWhere((m) => m.id == id);
  }

  @override
  Future<ChatMessage> react(int id, int kind) async =>
      _put(_copy(_byId(id), myReaction: kind));

  @override
  Future<void> typing(int contactId) async => typingCalls++;

  @override
  Future<void> markRead(int contactId) async {
    for (final m in [...sent]) {
      if (m.contactId == contactId && m.unread) {
        _put(_copy(m, status: MessageStatus.read));
      }
    }
  }

  @override
  Future<List<ChatMessage>> search(String query) async {
    final words = query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return const [];
    return [
      for (final m in sent.reversed)
        if (!m.deleted && words.every(m.text.toLowerCase().contains)) m,
    ];
  }

  @override
  Future<ChatSettings> chatSettings() async => settings;

  @override
  Future<void> setChatSettings(ChatSettings settings) async =>
      this.settings = settings;

  @override
  Future<Appearance> appearance() async => savedAppearance;

  @override
  Future<NotificationMode> notificationMode() async => notifications;

  @override
  Future<void> setNotificationMode(NotificationMode mode) async =>
      notifications = mode;

  @override
  Future<DownloadPolicy> downloadPolicy() async => autoDownload;

  @override
  Future<void> setDownloadPolicy(DownloadPolicy policy) async =>
      autoDownload = policy;

  @override
  Future<bool> keepRunning() async => running;

  @override
  Future<void> setKeepRunning(bool on) async => running = on;

  @override
  Future<NetworkSettings> networkSettings() async => network;

  @override
  Future<NetworkSettings> setNetworkSettings(NetworkSettings settings) async {
    final relays = <String>[];
    for (final relay in settings.relays) {
      final clean = relay.trim();
      if (!RegExp(r'^https?://[^\s/@?#]+(/.*)?$').hasMatch(clean)) {
        throw const CoreException(CoreFailure.invalidRelay);
      }
      if (!relays.contains(clean)) relays.add(clean);
    }
    if (relays.length > maxRelays) {
      throw const CoreException(CoreFailure.invalidRelay);
    }
    network = NetworkSettings(
      internet: settings.internet,
      relays: relays,
      bluetooth: settings.bluetooth,
    );
    networkRestarts++;
    // Como o núcleo: religar a rede faz a UI reler tudo.
    _events.add(const CoreEvent(CoreEventKind.contact, 0));
    return network;
  }

  @override
  Future<NetworkStatus> networkStatus() async => NetworkStatus(
    running: true,
    internet: network.internet,
    relays: network.internet ? network.relays.length : 0,
    relayConnected: network.internet && relayConnected,
    bluetooth: !network.bluetooth
        ? BluetoothState.off
        : bluetoothWorks
        ? BluetoothState.on
        : BluetoothState.unavailable,
  );

  /// Se o rádio de mentira abre quando o Bluetooth é ligado.
  bool bluetoothWorks = true;

  /// A caixa postal ligada, e o código que a caixa de mentira aceita.
  MailboxState? mailboxState;
  static const mailboxLink = 'chirp://mailbox#AQ';

  @override
  Future<MailboxState?> mailbox() async => mailboxState;

  @override
  Future<MailboxState> pairMailbox(String link) async {
    final clean = link.trim();
    if (!clean.startsWith('chirp://mailbox#')) {
      throw const CoreException(CoreFailure.invalidMailbox);
    }
    if (clean != mailboxLink) {
      throw const CoreException(CoreFailure.mailboxRefused);
    }
    return mailboxState = MailboxState(
      pairedAt: DateTime(2026, 11, 12, 9),
      reachable: true,
    );
  }

  @override
  Future<void> unpairMailbox() async => mailboxState = null;

  /// Muda por onde o contato foi alcançado, como o nó faria.
  void reached(int contactId, ContactReach reach) {
    final i = people.indexWhere((c) => c.id == contactId);
    final c = people[i];
    people[i] = Contact(
      id: c.id,
      displayName: c.displayName,
      avatarSeed: c.avatarSeed,
      verified: c.verified,
      established: c.established,
      reach: reach,
      photo: c.photo,
    );
    _events.add(CoreEvent(CoreEventKind.contact, contactId));
  }

  @override
  Future<void> setAppearance(Appearance appearance) async {
    if (appearanceFails) throw const CoreException(CoreFailure.storage);
    savedAppearance = appearance;
  }

  @override
  Future<void> startNetwork() async {
    if (networkFailure case final failure?) throw CoreException(failure);
    networkStarted = true;
  }

  @override
  Future<void> stopNetwork() async => networkStarted = false;

  @override
  Future<String> createInvite({required bool qr}) async {
    final link = 'chirp://invite#${qr ? 'qr' : 'link'}${invites.length}';
    invites.add(link);
    return link;
  }

  /// `chirp://invite#nome` vira o contato "nome"; `#refused` e `#away` falham.
  @override
  Future<Contact> addContact(String link, {required bool scanned}) async {
    final trimmed = link.trim();
    if (!trimmed.startsWith('chirp://invite#')) {
      throw const CoreException(CoreFailure.invalidInvite);
    }
    final name = trimmed.substring('chirp://invite#'.length);
    if (name == 'refused') throw const CoreException(CoreFailure.inviteRefused);
    if (name == 'away') throw const CoreException(CoreFailure.unreachable);
    // Quem convidou está desligado e tem caixa postal: o pedido fica lá, pendente.
    final mailbox = name == 'mailbox';
    final contact = Contact(
      id: people.length + 1,
      displayName: mailbox ? '' : name,
      avatarSeed: people.length * 7919,
      verified: scanned,
      established: !mailbox,
    );
    people.add(contact);
    return contact;
  }

  @override
  Future<List<Contact>> contacts() async => [
    for (final c in people)
      Contact(
        id: c.id,
        displayName: c.displayName,
        avatarSeed: c.avatarSeed,
        verified: _verified[c.id] ?? c.verified,
        established: c.established,
        reach: c.reach,
        photo: c.photo,
        photoAllowed: photoAllowed.contains(c.id),
        isGroup: c.isGroup,
        groupActive: groups[c.id]?.active ?? false,
      ),
  ];

  /// Os grupos falsos, pelo id da conversa.
  final Map<int, FakeGroup> groups = {};

  void _changed(int id) => _events.add(CoreEvent(CoreEventKind.contact, id));

  FakeGroup _group(int id) =>
      groups[id] ?? (throw const CoreException(CoreFailure.unknownContact));

  void _admin(int id) {
    final g = _group(id);
    if (!g.admin || !g.active) throw const CoreException(CoreFailure.notAdmin);
  }

  @override
  Future<Contact> createGroup(String name, List<int> memberIds) async {
    if (name.trim().isEmpty) throw const CoreException(CoreFailure.invalidName);
    final id = people.length + 1;
    final contact = Contact(
      id: id,
      displayName: name.trim(),
      avatarSeed: id * 7919,
      verified: false,
      established: true,
      isGroup: true,
    );
    people.add(contact);
    groups[id] = FakeGroup(members: [...memberIds]);
    _changed(id);
    return (await contacts()).firstWhere((c) => c.id == id);
  }

  /// Chegou um grupo em que alguém (não eu) é o admin.
  int joinedGroup(
    String name,
    List<int> memberIds, {
    List<String> strangers = const [],
  }) {
    final id = people.length + 1;
    people.add(
      Contact(
        id: id,
        displayName: name,
        avatarSeed: id * 7919,
        verified: false,
        established: true,
        isGroup: true,
      ),
    );
    groups[id] = FakeGroup(
      members: [...memberIds],
      admin: false,
      strangers: [...strangers],
    );
    _changed(id);
    return id;
  }

  /// Um membro escreveu no grupo.
  ChatMessage groupMessage(int groupId, int authorId, String text) {
    final author = people.firstWhere((c) => c.id == authorId);
    final m = _new(groupId, outgoing: false, text: text);
    final withAuthor = ChatMessage(
      id: m.id,
      contactId: groupId,
      outgoing: false,
      kind: m.kind,
      text: text,
      sentAt: m.sentAt,
      receivedAt: m.receivedAt,
      status: m.status,
      authorName: author.displayName,
      authorSeed: author.avatarSeed,
    );
    _put(withAuthor);
    _events.add(CoreEvent(CoreEventKind.messages, groupId));
    return withAuthor;
  }

  @override
  Future<GroupInfo> group(int id) async {
    final g = _group(id);
    final c = people.firstWhere((p) => p.id == id);
    return GroupInfo(
      id: id,
      name: c.displayName,
      iAmAdmin: g.admin,
      active: g.active,
      members: [
        for (final m in g.members)
          GroupMember(
            key: Uint8List.fromList([m]),
            name: people.firstWhere((p) => p.id == m).displayName,
            avatarSeed: m * 7919,
            contactId: m,
          ),
        for (final (i, name) in g.strangers.indexed)
          GroupMember(
            key: Uint8List.fromList([200 + i]),
            name: name,
            avatarSeed: 200 + i,
            isAdmin: !g.admin && i == 0,
          ),
      ],
    );
  }

  @override
  Future<void> renameGroup(int id, String name) async {
    _admin(id);
    if (name.trim().isEmpty) throw const CoreException(CoreFailure.invalidName);
    final i = people.indexWhere((p) => p.id == id);
    final c = people[i];
    people[i] = Contact(
      id: c.id,
      displayName: name.trim(),
      avatarSeed: c.avatarSeed,
      verified: false,
      established: true,
      isGroup: true,
    );
    _changed(id);
  }

  @override
  Future<void> addGroupMembers(int id, List<int> memberIds) async {
    _admin(id);
    final g = _group(id);
    for (final m in memberIds) {
      if (!g.members.contains(m)) g.members.add(m);
    }
    _changed(id);
  }

  @override
  Future<void> removeGroupMember(int id, GroupMember member) async {
    _admin(id);
    _group(id).members.remove(member.contactId);
    _changed(id);
  }

  @override
  Future<void> leaveGroup(int id) async {
    _group(id).active = false;
    _changed(id);
  }

  /// Os contatos que veem a foto no modo "só os marcados".
  final Set<int> photoAllowed = {};

  /// As fotos escolhidas (o caminho), na ordem.
  final List<String> photoPaths = [];

  /// Um JPEG mínimo, de mentira: a UI só desenha o que o núcleo deu.
  static final Uint8List fakeJpeg = Uint8List.fromList(_onePixelPng);

  @override
  Future<Profile> setProfilePhoto(String path) async {
    if (!path.endsWith('.jpg') && !path.endsWith('.png')) {
      throw const CoreException(CoreFailure.invalidFile);
    }
    photoPaths.add(path);
    return saved = _withPhoto(saved!, fakeJpeg, saved!.photoVisibility);
  }

  @override
  Future<Profile> removeProfilePhoto() async =>
      saved = _withPhoto(saved!, null, saved!.photoVisibility);

  @override
  Future<Profile> setPhotoVisibility(PhotoVisibility visibility) async =>
      saved = _withPhoto(saved!, saved!.photo, visibility);

  @override
  Future<Contact> setPhotoAllowed(
    int contactId, {
    required bool allowed,
  }) async {
    allowed ? photoAllowed.add(contactId) : photoAllowed.remove(contactId);
    return (await contacts()).firstWhere((c) => c.id == contactId);
  }

  static Profile _withPhoto(
    Profile p,
    Uint8List? photo,
    PhotoVisibility visibility,
  ) => Profile(
    displayName: p.displayName,
    version: p.version,
    fingerprint: p.fingerprint,
    avatarSeed: p.avatarSeed,
    photo: photo,
    photoVisibility: visibility,
  );

  @override
  Future<String> safetyNumber(int contactId) async =>
      List.generate(60, (i) => '${(i + contactId) % 10}').join();

  @override
  Future<Contact> setVerified(int contactId, {required bool verified}) async {
    _verified[contactId] = verified;
    return (await contacts()).firstWhere((c) => c.id == contactId);
  }

  @override
  Future<Profile?> profile() async => saved;

  @override
  Future<Profile> createProfile(String name) async {
    if (saved != null) throw const CoreException(CoreFailure.alreadyExists);
    return saved = _profile(name, 1);
  }

  @override
  Future<Profile> rename(String name) async =>
      saved = _profile(name, saved!.version + 1);

  /// Um contato já estabelecido, para as conversas.
  Contact befriend(String name) {
    final contact = Contact(
      id: people.length + 1,
      displayName: name,
      avatarSeed: people.length * 7919 + 13,
      verified: true,
      established: true,
    );
    people.add(contact);
    return contact;
  }

  static Profile _profile(String name, int version) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 64 || trimmed.contains('\n')) {
      throw const CoreException(CoreFailure.invalidName);
    }
    return Profile(
      displayName: trimmed,
      version: version,
      fingerprint: testFingerprint,
      avatarSeed: 0x5a5a5,
    );
  }
}

/// O cofre em memória; [available] falso faz de conta que o sistema não tem cofre.
class FakeVault implements KeyVault {
  FakeVault({this.available = true});

  bool available;
  Uint8List? key;

  @override
  Future<Uint8List?> read() async {
    if (!available) throw const VaultUnavailable();
    return key;
  }

  @override
  Future<void> write(Uint8List key) async {
    if (!available) throw const VaultUnavailable();
    this.key = key;
  }

  @override
  Future<void> delete() async {
    if (!available) throw const VaultUnavailable();
    key = null;
  }
}

/// Um núcleo e um cofre que já têm um perfil.
Future<(FakeCore, FakeVault)> withProfile([String name = 'Lutino']) async {
  final core = FakeCore();
  final vault = FakeVault();
  final key = core.newStoreKey();
  vault.key = key;
  await (await core.openWithKey(key)).createProfile(name);
  return (core, vault);
}

void setWindow(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> pumpChirp(
  WidgetTester tester, {
  FakeCore? core,
  FakeVault? vault,
  Color? accent,
  FilePicker? filePicker,
  Notifier? notifier,
  Background? background,
  bool startHidden = false,
}) async {
  await tester.pumpWidget(
    ChirpApp(
      core: core ?? FakeCore(),
      vault: vault ?? FakeVault(),
      systemAccent: accent == null ? null : () async => accent,
      filePicker: filePicker ?? FakeFilePicker(),
      notifier: notifier ?? FakeNotifier(),
      background: background ?? const NoBackground(),
      startHidden: startHidden,
    ),
  );
  await tester.pumpAndSettle();
}

/// O segundo plano, sem janela, bandeja nem serviço: guarda o que pediram. Com
/// [tray], é o desktop; sem, o Android.
class FakeBackground implements Background {
  FakeBackground({
    this.tray = true,
    bool? canStartAtLogin,
    this.restricted = false,
  }) : canStartAtLogin = canStartAtLogin ?? tray;

  /// O último `setup`: ligado ou não, e os textos.
  ({bool keepRunning, BackgroundTexts texts})? running;

  bool visible = true;
  int broughtToFront = 0;

  /// A economia de bateria segura o app; pedir libera.
  bool restricted;
  int batteryAsks = 0;

  @override
  final bool tray;

  @override
  final bool canStartAtLogin;

  @override
  bool startsAtLogin = false;

  @override
  bool get supported => true;

  @override
  Future<void> setup({
    required bool keepRunning,
    required BackgroundTexts texts,
  }) async {
    running = (keepRunning: keepRunning, texts: texts);
    if (!keepRunning) visible = true;
  }

  @override
  Future<void> bringToFront() async {
    broughtToFront++;
    visible = true;
  }

  @override
  Future<void> hide() async => visible = false;

  @override
  bool setStartAtLogin(bool on) {
    startsAtLogin = on;
    return true;
  }

  @override
  Future<bool> batteryRestricted() async => restricted;

  @override
  Future<void> askUnrestrictedBattery() async {
    batteryAsks++;
    restricted = false;
  }
}

/// As notificações, sem sistema: guarda as que estão na tela.
class FakeNotifier implements Notifier {
  /// Quantas vezes pediram para preparar (a permissão).
  int inits = 0;

  /// As notificações na tela, pelo contato.
  final Map<int, ({String title, String body})> shown = {};

  final _opened = StreamController<int>.broadcast();

  /// Quem usa clica na notificação do contato.
  void tap(int contactId) => _opened.add(contactId);

  @override
  Stream<int> get opened => _opened.stream;

  @override
  Future<bool> init({required String open, required String channel}) async {
    inits++;
    return true;
  }

  @override
  Future<void> show({
    required int contactId,
    required String title,
    required String body,
  }) async => shown[contactId] = (title: title, body: body);

  @override
  Future<void> clear(int contactId) async => shown.remove(contactId);
}

/// O seletor de arquivos, sem janela: devolve o que o teste mandar.
class FakeFilePicker implements FilePicker {
  FakeFilePicker({this.pick, this.save, this.canSave = true});

  String? pick;
  String? save;

  @override
  final bool canSave;

  /// Os nomes que o app sugeriu ao salvar.
  final List<String> suggested = [];

  @override
  Future<String?> pickFile() async => pick;

  @override
  Future<String?> saveLocation(String name) async {
    suggested.add(name);
    return save;
  }
}

/// Um PNG de 1×1 pixel, que o `Image.memory` desenha nos testes.
const _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x64, 0x60, 0xF8, 0x5F, //
  0x0F, 0x00, 0x02, 0x87, 0x01, 0x80, 0xEB, 0x47, 0xBA, 0x92, 0x00, 0x00, //
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
];

/// Um grupo do [FakeStore]: os membros que são contatos, os que não são (só o nome),
/// se sou o admin e se ainda sou membro.
class FakeGroup {
  FakeGroup({
    required this.members,
    this.admin = true,
    this.strangers = const [],
  });

  final List<int> members;
  final List<String> strangers;
  bool admin;
  bool active = true;
}

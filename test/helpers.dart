// O apoio dos testes: um núcleo e um cofre falsos, em memória, e a montagem do app.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_chirp/chirp_app.dart';
import 'package:psito_chirp/src/core/chirp_core.dart';
import 'package:psito_chirp/src/platform/key_vault.dart';

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
      canDeleteForEveryone: outgoing && kind == MessageKind.text,
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
  );

  /// Chega uma mensagem do contato.
  ChatMessage incoming(int contactId, String text, {int? replyTo}) {
    final m = _new(contactId, outgoing: false, text: text, replyTo: replyTo);
    _events.add(CoreEvent(CoreEventKind.messages, contactId));
    return m;
  }

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
    network = NetworkSettings(internet: settings.internet, relays: relays);
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
  );

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
    final contact = Contact(
      id: people.length + 1,
      displayName: name,
      avatarSeed: people.length * 7919,
      verified: scanned,
      established: true,
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
      ),
  ];

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
}) async {
  await tester.pumpWidget(
    ChirpApp(
      core: core ?? FakeCore(),
      vault: vault ?? FakeVault(),
      systemAccent: accent == null ? null : () async => accent,
    ),
  );
  await tester.pumpAndSettle();
}

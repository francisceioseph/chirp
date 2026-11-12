// lib/src/core/chirp_core.dart
//
// A porta para o núcleo em Rust. A UI só conhece o ChirpCore e o ProfileStore; o
// BridgeCore é a ponte gerada pelo flutter_rust_bridge (lib/src/bridge/), e os testes
// usam um falso. Os tipos da ponte não passam daqui.

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../bridge/api/info.dart' as bridge;
import '../bridge/api/store.dart' as bridge;
import '../bridge/error.dart' as bridge;
import '../bridge/frb_generated.dart';

/// A versão do núcleo e a do protocolo que ele fala no fio.
@immutable
class CoreInfo {
  const CoreInfo({required this.version, required this.protocol});

  final String version;
  final int protocol;
}

/// Como abrir o banco deste aparelho.
enum StoreState {
  /// Ainda não existe: é a primeira abertura.
  missing,

  /// A chave está no cofre do sistema.
  keyInVault,

  /// A chave vem de uma senha.
  passphrase,
}

/// O que deu errado no núcleo. Não carrega texto: a UI escolhe a mensagem.
enum CoreFailure {
  wrongKey,
  badKey,
  weakPassphrase,
  invalidName,
  alreadyExists,
  newerStore,
  noRandomness,
  noProfile,
  invalidInvite,
  inviteRefused,
  ownInvite,
  unreachable,
  protocol,
  unknownContact,
  unknownMessage,
  invalidMessage,
  tooSoon,
  tooLate,

  /// O endereço do retransmissor não serve (ou são mais de três).
  invalidRelay,

  /// O arquivo não serve (grande demais, ilegível, ou uma foto que não deu para
  /// limpar).
  invalidFile,

  /// Sem microfone ou alto-falante, ou o sistema não deixou usar.
  noAudio,
  storage,
}

class CoreException implements Exception {
  const CoreException(this.failure);

  final CoreFailure failure;

  @override
  String toString() => 'CoreException(${failure.name})';
}

/// O perfil deste aparelho.
@immutable
class Profile {
  const Profile({
    required this.displayName,
    required this.version,
    required this.fingerprint,
    required this.avatarSeed,
  });

  final String displayName;
  final int version;

  /// A impressão digital da identidade: 30 dígitos em 6 grupos de 5.
  final String fingerprint;

  /// A semente do avatar gerado a partir da chave.
  final int avatarSeed;
}

/// Um contato.
@immutable
class Contact {
  const Contact({
    required this.id,
    required this.displayName,
    required this.avatarSeed,
    required this.verified,
    required this.established,
    this.reach = ContactReach.unknown,
  });

  final int id;
  final String displayName;
  final int avatarSeed;

  /// O número de segurança foi conferido (QR frente a frente, ou marcado à mão).
  final bool verified;

  /// O aperto de mão fechou dos dois lados.
  final bool established;

  /// Por onde foi alcançado da última vez, com a rede ligada.
  final ContactReach reach;
}

/// Por onde um contato foi alcançado da última vez.
enum ContactReach {
  /// Ainda não tentou (ou a rede está desligada).
  unknown,

  /// Direto, na rede local.
  lan,

  /// Direto, pela internet.
  direct,

  /// Pelo servidor de retransmissão.
  relay,

  /// Não alcançou.
  unreachable,
}

/// A internet e os servidores de retransmissão (os dois desligados no começo).
@immutable
class NetworkSettings {
  const NetworkSettings({this.internet = false, this.relays = const []});

  final bool internet;

  /// Os endereços dos retransmissores (`https://...`), até três.
  final List<String> relays;

  NetworkSettings copyWith({bool? internet, List<String>? relays}) =>
      NetworkSettings(
        internet: internet ?? this.internet,
        relays: relays ?? this.relays,
      );
}

/// Quantos retransmissores, no máximo (o núcleo recusa mais).
const maxRelays = 3;

/// Como a rede está agora.
@immutable
class NetworkStatus {
  const NetworkStatus({
    this.running = false,
    this.internet = false,
    this.relays = 0,
    this.relayConnected = false,
  });

  /// O nó está ligado.
  final bool running;
  final bool internet;

  /// Quantos retransmissores valem (com a internet ligada).
  final int relays;

  /// Algum retransmissor respondeu.
  final bool relayConnected;
}

enum MessageKind {
  text,

  /// Chamou atenção.
  nudge,

  /// Um arquivo ([ChatMessage.file] diz qual).
  file,
}

/// Em que pé está um arquivo.
enum FileState {
  /// Grande demais para baixar sozinho: espera quem usa pedir.
  waiting,

  /// Baixando, ou esperando o contato aparecer.
  downloading,

  /// Inteiro e conferido.
  done,

  /// O que chegou não bateu com o que foi oferecido.
  failed,
}

/// O arquivo de uma mensagem.
@immutable
class ChatFile {
  const ChatFile({
    required this.name,
    required this.size,
    required this.mime,
    this.thumbnail,
    this.received = 0,
    this.chunks = 1,
    this.state = FileState.done,
    this.voice = false,
  });

  final String name;
  final int size;
  final String mime;

  /// A miniatura em JPEG, feita por quem mandou.
  final Uint8List? thumbnail;
  final int received;
  final int chunks;
  final FileState state;

  /// Uma nota de voz, que a conversa toca ali mesmo.
  final bool voice;

  bool get isImage => mime.startsWith('image/');

  /// Quanto já chegou, de 0 a 1.
  double get progress => chunks == 0 ? 1 : received / chunks;
}

/// Onde está a nota de voz que toca.
@immutable
class VoiceProgress {
  const VoiceProgress({
    required this.messageId,
    required this.position,
    this.done = false,
  });

  final int messageId;
  final Duration position;
  final bool done;
}

/// Para as minhas: na fila, entregue, lida. Para as do contato, `pending` é não lida.
enum MessageStatus { pending, delivered, read }

/// Quantos tipos de reação há; 0 é nenhuma, de 1 a [reactionKinds].
const reactionKinds = 6;

/// Uma mensagem de uma conversa.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.contactId,
    required this.outgoing,
    required this.kind,
    required this.text,
    required this.sentAt,
    required this.receivedAt,
    required this.status,
    this.replyTo,
    this.edited = false,
    this.deleted = false,
    this.myReaction = 0,
    this.theirReaction = 0,
    this.canEdit = false,
    this.canDeleteForEveryone = false,
    this.file,
  });

  final int id;
  final int contactId;
  final bool outgoing;
  final MessageKind kind;
  final String text;

  /// A mensagem citada, se ela existe neste aparelho.
  final int? replyTo;

  /// Pelo relógio de quem mandou.
  final DateTime sentAt;

  /// Quando chegou (ou foi escrita, se é minha).
  final DateTime receivedAt;
  final MessageStatus status;
  final bool edited;
  final bool deleted;
  final int myReaction;
  final int theirReaction;
  final bool canEdit;
  final bool canDeleteForEveryone;

  /// O arquivo, se a mensagem é um.
  final ChatFile? file;

  bool get unread => !outgoing && status == MessageStatus.pending;
}

/// Uma conversa na lista: o contato, a última mensagem e as não lidas.
@immutable
class Conversation {
  const Conversation({required this.contact, this.last, this.unread = 0});

  final Contact contact;
  final ChatMessage? last;
  final int unread;
}

/// Os recibos de leitura e o "digitando". Desligar vale para os dois lados.
@immutable
class ChatSettings {
  const ChatSettings({required this.readReceipts, required this.typing});

  final bool readReceipts;
  final bool typing;
}

/// O que as notificações mostram: nada, só "Nova mensagem", o nome de quem mandou,
/// ou o nome e o texto. O padrão é o nome.
enum NotificationMode { off, hidden, sender, full }

/// Até que tamanho o arquivo de um contato baixa sozinho: nunca, 4, 32 ou 256 MiB.
enum AutoDownload { never, small, medium, large }

/// O baixar sozinho: o limite e se só dos contatos verificados. O padrão é até
/// 32 MiB, de qualquer contato.
@immutable
class DownloadPolicy {
  const DownloadPolicy({
    this.limit = AutoDownload.medium,
    this.onlyVerified = false,
  });

  final AutoDownload limit;
  final bool onlyVerified;

  DownloadPolicy copyWith({AutoDownload? limit, bool? onlyVerified}) =>
      DownloadPolicy(
        limit: limit ?? this.limit,
        onlyVerified: onlyVerified ?? this.onlyVerified,
      );

  @override
  bool operator ==(Object other) =>
      other is DownloadPolicy &&
      other.limit == limit &&
      other.onlyVerified == onlyVerified;

  @override
  int get hashCode => Object.hash(limit, onlyVerified);
}

/// Claro, escuro ou o que o sistema disser.
enum AppearanceMode { system, light, dark }

/// A aparência escolhida: o id do tema (ChirpThemes), o claro ou escuro e o vidro.
@immutable
class Appearance {
  const Appearance({
    this.theme = 'lutino',
    this.mode = AppearanceMode.system,
    this.glass = false,
  });

  final String theme;
  final AppearanceMode mode;
  final bool glass;

  Appearance copyWith({String? theme, AppearanceMode? mode, bool? glass}) =>
      Appearance(
        theme: theme ?? this.theme,
        mode: mode ?? this.mode,
        glass: glass ?? this.glass,
      );

  @override
  bool operator ==(Object other) =>
      other is Appearance &&
      other.theme == theme &&
      other.mode == mode &&
      other.glass == glass;

  @override
  int get hashCode => Object.hash(theme, mode, glass);
}

enum CoreEventKind {
  /// Um contato novo ou mudado; com o id 0, releia tudo.
  contact,

  /// A conversa com o contato mudou.
  messages,

  /// O contato está digitando.
  typing,
}

@immutable
class CoreEvent {
  const CoreEvent(this.kind, this.contactId);

  final CoreEventKind kind;
  final int contactId;
}

/// O que a UI pode pedir ao núcleo.
abstract interface class ChirpCore {
  /// Nulo quando a biblioteca nativa não abriu.
  CoreInfo? get info;

  /// O mínimo de caracteres de uma senha.
  int get minPassphraseChars;

  StoreState storeState();

  /// Uma chave nova para o banco, para guardar no cofre.
  Uint8List newStoreKey();

  Future<ProfileStore> openWithKey(Uint8List key);

  Future<ProfileStore> createWithPassphrase(String passphrase);

  Future<ProfileStore> openWithPassphrase(String passphrase);

  /// Apaga o banco deste aparelho.
  Future<void> wipe();
}

/// O banco aberto.
abstract interface class ProfileStore {
  Future<Profile?> profile();

  Future<Profile> createProfile(String name);

  Future<Profile> rename(String name);

  /// Liga o nó da rede local (precisa do perfil). Chamar de novo não faz nada.
  Future<void> startNetwork();

  /// Desliga o nó, antes de apagar tudo.
  Future<void> stopNetwork();

  /// Um convite novo, como link. [qr]: vai ser mostrado como QR, frente a frente.
  Future<String> createInvite({required bool qr});

  /// Lê um convite e faz o aperto de mão pela rede.
  Future<Contact> addContact(String link, {required bool scanned});

  Future<List<Contact>> contacts();

  /// O número de segurança: 60 dígitos, igual nos dois aparelhos.
  Future<String> safetyNumber(int contactId);

  Future<Contact> setVerified(int contactId, {required bool verified});

  /// O que muda sem a UI pedir: contatos, mensagens que chegam, o "digitando".
  Stream<CoreEvent> events();

  /// As conversas, a mais recente primeiro.
  Future<List<Conversation>> conversations();

  /// As últimas [limit] mensagens, em ordem; antes de [before] para as anteriores.
  Future<List<ChatMessage>> messages(
    int contactId, {
    int? before,
    int limit = 100,
  });

  Future<ChatMessage> sendText(int contactId, String text, {int? replyTo});

  /// Chama a atenção. Uma vez a cada 10 segundos (`CoreFailure.tooSoon`).
  Future<ChatMessage> sendNudge(int contactId);

  /// Manda o arquivo em [path]. Uma foto sai sem os metadados (o EXIF); uma que
  /// não dá para limpar não sai (`CoreFailure.invalidFile`).
  Future<ChatMessage> sendFile(int contactId, String path);

  /// Baixa (ou volta a baixar) o arquivo de uma mensagem do contato.
  Future<void> downloadFile(int messageId);

  /// Salva uma cópia em claro do arquivo em [path].
  Future<void> saveFile(int messageId, String path);

  /// O arquivo em claro, para mostrar uma foto (até 32 MiB).
  Future<Uint8List> fileBytes(int messageId);

  /// Liga o microfone para uma nota de voz (`CoreFailure.noAudio` sem ele).
  Future<void> startVoice();

  /// Para de gravar e joga fora.
  Future<void> cancelVoice();

  /// Para de gravar e manda a nota. Com menos de meio segundo, não sai
  /// (`CoreFailure.invalidMessage`).
  Future<ChatMessage> sendVoice(int contactId);

  /// Quanto dura a nota de voz de uma mensagem já baixada.
  Future<Duration> voiceDuration(int messageId);

  /// Toca a nota de voz de uma mensagem (a que tocava para). O fluxo fecha no fim.
  Stream<VoiceProgress> playVoice(int messageId);

  Future<void> stopVoice();

  Future<ChatMessage> editMessage(int id, String text);

  Future<ChatMessage> deleteForEveryone(int id);

  Future<void> deleteForMe(int id);

  /// [kind] de 1 a [reactionKinds]; 0 tira a reação.
  Future<ChatMessage> react(int id, int kind);

  /// Estou digitando (a UI chama de tempos em tempos enquanto digita).
  Future<void> typing(int contactId);

  /// Li a conversa.
  Future<void> markRead(int contactId);

  /// Busca em todas as conversas.
  Future<List<ChatMessage>> search(String query);

  Future<ChatSettings> chatSettings();

  Future<void> setChatSettings(ChatSettings settings);

  Future<Appearance> appearance();

  Future<NetworkSettings> networkSettings();

  /// Grava (o núcleo confere os retransmissores) e religa a rede com eles. Devolve
  /// o que ficou gravado.
  Future<NetworkSettings> setNetworkSettings(NetworkSettings settings);

  Future<NetworkStatus> networkStatus();

  Future<void> setAppearance(Appearance appearance);

  Future<NotificationMode> notificationMode();

  Future<void> setNotificationMode(NotificationMode mode);

  Future<DownloadPolicy> downloadPolicy();

  Future<void> setDownloadPolicy(DownloadPolicy policy);

  /// Continuar recebendo com a janela fechada (no desktop, na bandeja).
  Future<bool> keepRunning();

  Future<void> setKeepRunning(bool on);
}

/// O núcleo de verdade, pela ponte.
class BridgeCore implements ChirpCore {
  BridgeCore._(this.info, this._dir);

  @override
  final CoreInfo? info;

  /// A biblioteca nativa só abre uma vez por processo.
  static bool _initialized = false;

  /// A pasta de suporte do app, onde fica o banco.
  final String _dir;

  /// Abre a biblioteca nativa. Se ela faltar ou não carregar, o app abre do mesmo
  /// jeito e diz que o núcleo não iniciou, em vez de fechar sem explicação.
  ///
  /// [dir] troca a pasta do banco (os testes de integração usam uma temporária).
  static Future<BridgeCore> open({String? dir}) async {
    dir ??= (await getApplicationSupportDirectory()).path;
    try {
      if (!_initialized) {
        await RustLib.init();
        _initialized = true;
      }
      final info = bridge.coreInfo();
      return BridgeCore._(
        CoreInfo(version: info.version, protocol: info.protocol),
        dir,
      );
    } catch (error) {
      debugPrint('chirp: core failed to start: $error');
      return BridgeCore._(null, dir);
    }
  }

  @override
  int get minPassphraseChars => bridge.minPassphraseChars();

  @override
  StoreState storeState() => switch (bridge.storeState(dir: _dir)) {
    bridge.StoreState.missing => StoreState.missing,
    bridge.StoreState.keyInVault => StoreState.keyInVault,
    bridge.StoreState.passphrase => StoreState.passphrase,
  };

  @override
  Uint8List newStoreKey() => _guard(bridge.newStoreKey);

  @override
  Future<ProfileStore> openWithKey(Uint8List key) => _guardAsync(
    () async =>
        _BridgeStore(await bridge.ChirpStore.openWithKey(dir: _dir, key: key)),
  );

  @override
  Future<ProfileStore> createWithPassphrase(String passphrase) => _guardAsync(
    () async => _BridgeStore(
      await bridge.ChirpStore.createWithPassphrase(
        dir: _dir,
        passphrase: passphrase,
      ),
    ),
  );

  @override
  Future<ProfileStore> openWithPassphrase(String passphrase) => _guardAsync(
    () async => _BridgeStore(
      await bridge.ChirpStore.openWithPassphrase(
        dir: _dir,
        passphrase: passphrase,
      ),
    ),
  );

  @override
  Future<void> wipe() => _guardAsync(() => bridge.wipeStore(dir: _dir));
}

class _BridgeStore implements ProfileStore {
  _BridgeStore(this._store);

  final bridge.ChirpStore _store;

  @override
  Future<Profile?> profile() =>
      _guardAsync(() async => _profile(await _store.profile()));

  @override
  Future<Profile> createProfile(String name) => _guardAsync(
    () async => _profile(await _store.createProfile(name: name))!,
  );

  @override
  Future<Profile> rename(String name) =>
      _guardAsync(() async => _profile(await _store.rename(name: name))!);

  @override
  Future<void> startNetwork() => _guardAsync(_store.startNetwork);

  @override
  Future<void> stopNetwork() => _guardAsync(_store.stopNetwork);

  @override
  Future<String> createInvite({required bool qr}) =>
      _guardAsync(() => _store.createInvite(qr: qr));

  @override
  Future<Contact> addContact(String link, {required bool scanned}) =>
      _guardAsync(
        () async =>
            _contact(await _store.addContact(link: link, scanned: scanned)),
      );

  @override
  Future<List<Contact>> contacts() => _guardAsync(
    () async => [for (final c in await _store.contacts()) _contact(c)],
  );

  @override
  Future<String> safetyNumber(int contactId) =>
      _guardAsync(() => _store.safetyNumber(contactId: contactId));

  @override
  Future<Contact> setVerified(int contactId, {required bool verified}) =>
      _guardAsync(
        () async => _contact(
          await _store.setVerified(contactId: contactId, verified: verified),
        ),
      );

  @override
  Stream<CoreEvent> events() => _store.watchEvents().map(
    (e) => CoreEvent(switch (e.kind) {
      bridge.EventKind.contact => CoreEventKind.contact,
      bridge.EventKind.messages => CoreEventKind.messages,
      bridge.EventKind.typing => CoreEventKind.typing,
    }, e.contactId),
  );

  @override
  Future<List<Conversation>> conversations() => _guardAsync(
    () async => [
      for (final c in await _store.conversations())
        Conversation(
          contact: _contact(c.contact),
          last: c.last == null ? null : _message(c.last!),
          unread: c.unread,
        ),
    ],
  );

  @override
  Future<List<ChatMessage>> messages(
    int contactId, {
    int? before,
    int limit = 100,
  }) => _guardAsync(
    () async => [
      for (final m in await _store.messages(
        contactId: contactId,
        before: before,
        limit: limit,
      ))
        _message(m),
    ],
  );

  @override
  Future<ChatMessage> sendText(int contactId, String text, {int? replyTo}) =>
      _guardAsync(
        () async => _message(
          await _store.sendText(
            contactId: contactId,
            text: text,
            replyTo: replyTo,
          ),
        ),
      );

  @override
  Future<ChatMessage> sendFile(int contactId, String path) => _guardAsync(
    () async =>
        _message(await _store.sendFile(contactId: contactId, path: path)),
  );

  @override
  Future<void> downloadFile(int messageId) =>
      _guardAsync(() => _store.downloadFile(messageId: messageId));

  @override
  Future<void> saveFile(int messageId, String path) =>
      _guardAsync(() => _store.saveFile(messageId: messageId, path: path));

  @override
  Future<Uint8List> fileBytes(int messageId) =>
      _guardAsync(() => _store.fileBytes(messageId: messageId));

  @override
  Future<void> startVoice() => _guardAsync(_store.startVoice);

  @override
  Future<void> cancelVoice() => _guardAsync(_store.cancelVoice);

  @override
  Future<ChatMessage> sendVoice(int contactId) => _guardAsync(
    () async => _message(await _store.sendVoice(contactId: contactId)),
  );

  @override
  Future<Duration> voiceDuration(int messageId) => _guardAsync(
    () async => Duration(
      milliseconds: (await _store.voiceDuration(messageId: messageId)).toInt(),
    ),
  );

  @override
  Stream<VoiceProgress> playVoice(int messageId) => _store
      .playVoice(messageId: messageId)
      .map(
        (p) => VoiceProgress(
          messageId: p.messageId,
          position: Duration(milliseconds: p.positionMs.toInt()),
          done: p.done,
        ),
      )
      .handleError(
        (Object error) => throw CoreException(_failure(error as bridge.CoreError)),
        test: (error) => error is bridge.CoreError,
      );

  @override
  Future<void> stopVoice() => _guardAsync(_store.stopVoice);

  @override
  Future<ChatMessage> sendNudge(int contactId) => _guardAsync(
    () async => _message(await _store.sendNudge(contactId: contactId)),
  );

  @override
  Future<ChatMessage> editMessage(int id, String text) => _guardAsync(
    () async => _message(await _store.editMessage(id: id, text: text)),
  );

  @override
  Future<ChatMessage> deleteForEveryone(int id) =>
      _guardAsync(() async => _message(await _store.deleteForEveryone(id: id)));

  @override
  Future<void> deleteForMe(int id) =>
      _guardAsync(() => _store.deleteForMe(id: id));

  @override
  Future<ChatMessage> react(int id, int kind) =>
      _guardAsync(() async => _message(await _store.react(id: id, kind: kind)));

  @override
  Future<void> typing(int contactId) =>
      _guardAsync(() => _store.typing(contactId: contactId));

  @override
  Future<void> markRead(int contactId) =>
      _guardAsync(() => _store.markRead(contactId: contactId));

  @override
  Future<List<ChatMessage>> search(String query) => _guardAsync(
    () async => [
      for (final m in await _store.search(query: query)) _message(m),
    ],
  );

  @override
  Future<ChatSettings> chatSettings() => _guardAsync(() async {
    final s = await _store.chatSettings();
    return ChatSettings(readReceipts: s.readReceipts, typing: s.typing);
  });

  @override
  Future<void> setChatSettings(ChatSettings settings) => _guardAsync(
    () => _store.setChatSettings(
      settings: bridge.ChatSettings(
        readReceipts: settings.readReceipts,
        typing: settings.typing,
      ),
    ),
  );

  @override
  Future<NetworkSettings> networkSettings() => _guardAsync(() async {
    final n = await _store.networkSettings();
    return NetworkSettings(internet: n.internet, relays: n.relays);
  });

  @override
  Future<NetworkSettings> setNetworkSettings(NetworkSettings settings) =>
      _guardAsync(() async {
        final n = await _store.setNetworkSettings(
          settings: bridge.NetworkSettings(
            internet: settings.internet,
            relays: settings.relays,
          ),
        );
        return NetworkSettings(internet: n.internet, relays: n.relays);
      });

  @override
  Future<NetworkStatus> networkStatus() => _guardAsync(() async {
    final n = await _store.networkStatus();
    return NetworkStatus(
      running: n.running,
      internet: n.internet,
      relays: n.relays,
      relayConnected: n.relayConnected,
    );
  });

  @override
  Future<NotificationMode> notificationMode() => _guardAsync(
    () async =>
        NotificationMode.values[(await _store.notificationMode()).index],
  );

  @override
  Future<void> setNotificationMode(NotificationMode mode) => _guardAsync(
    () => _store.setNotificationMode(
      mode: bridge.NotificationMode.values[mode.index],
    ),
  );

  @override
  Future<DownloadPolicy> downloadPolicy() => _guardAsync(() async {
    final p = await _store.downloadPolicy();
    return DownloadPolicy(
      limit: AutoDownload.values[p.limit.index],
      onlyVerified: p.onlyVerified,
    );
  });

  @override
  Future<void> setDownloadPolicy(DownloadPolicy policy) => _guardAsync(
    () => _store.setDownloadPolicy(
      policy: bridge.DownloadPolicy(
        limit: bridge.AutoDownload.values[policy.limit.index],
        onlyVerified: policy.onlyVerified,
      ),
    ),
  );

  @override
  Future<bool> keepRunning() => _guardAsync(_store.keepRunning);

  @override
  Future<void> setKeepRunning(bool on) =>
      _guardAsync(() => _store.setKeepRunning(on_: on));

  @override
  Future<Appearance> appearance() => _guardAsync(() async {
    final a = await _store.appearance();
    return Appearance(
      theme: a.theme,
      mode: AppearanceMode.values[a.brightness.index],
      glass: a.glass,
    );
  });

  @override
  Future<void> setAppearance(Appearance appearance) => _guardAsync(
    () => _store.setAppearance(
      appearance: bridge.AppearanceView(
        theme: appearance.theme,
        brightness: bridge.ThemeBrightness.values[appearance.mode.index],
        glass: appearance.glass,
      ),
    ),
  );
}

ChatMessage _message(bridge.MessageView m) => ChatMessage(
  id: m.id,
  contactId: m.contactId,
  outgoing: m.outgoing,
  kind: switch (m.kind) {
    bridge.MessageKind.text => MessageKind.text,
    bridge.MessageKind.nudge => MessageKind.nudge,
    bridge.MessageKind.file => MessageKind.file,
  },
  text: m.text,
  replyTo: m.replyTo,
  sentAt: DateTime.fromMillisecondsSinceEpoch(m.sentAt),
  receivedAt: DateTime.fromMillisecondsSinceEpoch(m.receivedAt),
  status: switch (m.status) {
    bridge.MessageStatus.pending => MessageStatus.pending,
    bridge.MessageStatus.delivered => MessageStatus.delivered,
    bridge.MessageStatus.read => MessageStatus.read,
  },
  edited: m.edited,
  deleted: m.deleted,
  myReaction: m.myReaction,
  theirReaction: m.theirReaction,
  canEdit: m.canEdit,
  canDeleteForEveryone: m.canDeleteForEveryone,
  file: switch (m.file) {
    null => null,
    final f => ChatFile(
      name: f.name,
      size: f.size.toInt(),
      mime: f.mime,
      thumbnail: f.thumbnail.isEmpty ? null : f.thumbnail,
      received: f.received,
      chunks: f.chunks,
      state: FileState.values[f.state.index],
      voice: f.voice,
    ),
  },
);

Contact _contact(bridge.ContactView c) => Contact(
  id: c.id,
  displayName: c.displayName,
  avatarSeed: c.avatarSeed,
  verified: c.verified,
  established: c.established,
  reach: ContactReach.values[c.reach.index],
);

Profile? _profile(bridge.Profile? p) => p == null
    ? null
    : Profile(
        displayName: p.displayName,
        version: p.version,
        fingerprint: p.fingerprint,
        avatarSeed: p.avatarSeed,
      );

CoreFailure _failure(bridge.CoreError error) => switch (error) {
  bridge.CoreError.wrongKey => CoreFailure.wrongKey,
  bridge.CoreError.badKey => CoreFailure.badKey,
  bridge.CoreError.weakPassphrase => CoreFailure.weakPassphrase,
  bridge.CoreError.invalidName => CoreFailure.invalidName,
  bridge.CoreError.alreadyExists => CoreFailure.alreadyExists,
  bridge.CoreError.newerStore => CoreFailure.newerStore,
  bridge.CoreError.noRandomness => CoreFailure.noRandomness,
  bridge.CoreError.noProfile => CoreFailure.noProfile,
  bridge.CoreError.invalidInvite => CoreFailure.invalidInvite,
  bridge.CoreError.inviteRefused => CoreFailure.inviteRefused,
  bridge.CoreError.ownInvite => CoreFailure.ownInvite,
  bridge.CoreError.unreachable => CoreFailure.unreachable,
  bridge.CoreError.protocol => CoreFailure.protocol,
  bridge.CoreError.unknownContact => CoreFailure.unknownContact,
  bridge.CoreError.unknownMessage => CoreFailure.unknownMessage,
  bridge.CoreError.invalidMessage => CoreFailure.invalidMessage,
  bridge.CoreError.tooSoon => CoreFailure.tooSoon,
  bridge.CoreError.tooLate => CoreFailure.tooLate,
  bridge.CoreError.invalidRelay => CoreFailure.invalidRelay,
  bridge.CoreError.invalidFile => CoreFailure.invalidFile,
  bridge.CoreError.noAudio => CoreFailure.noAudio,
  bridge.CoreError.storage => CoreFailure.storage,
};

T _guard<T>(T Function() call) {
  try {
    return call();
  } on bridge.CoreError catch (error) {
    throw CoreException(_failure(error));
  }
}

Future<T> _guardAsync<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on bridge.CoreError catch (error) {
    throw CoreException(_failure(error));
  }
}

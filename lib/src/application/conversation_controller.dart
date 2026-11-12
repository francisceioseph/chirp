// lib/src/application/conversation_controller.dart
//
// Uma conversa aberta: as mensagens, o que está sendo respondido ou editado, o
// "digitando" para o outro lado e as chamadas de atenção que chegam. Enquanto a
// conversa está aberta, o que chega é marcado como lido.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/chirp_core.dart';
import 'contacts_controller.dart';

/// Quantas mensagens por página.
const messagesPage = 60;

/// De quanto em quanto tempo o "digitando" sai, enquanto se digita.
const typingEvery = Duration(seconds: 4);

class ConversationController extends ChangeNotifier {
  ConversationController(
    this.contacts,
    this.contactId, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ContactsController contacts;
  final int contactId;
  final DateTime Function() _now;

  ProfileStore get _store => contacts.store;

  List<ChatMessage> _messages = const [];
  List<ChatMessage> get messages => _messages;

  bool _loaded = false;
  bool get loaded => _loaded;

  /// Ainda há mensagens antes da primeira carregada.
  bool _hasOlder = false;
  bool get hasOlder => _hasOlder;

  ChatMessage? _replyTo;
  ChatMessage? get replyTo => _replyTo;

  ChatMessage? _editing;
  ChatMessage? get editing => _editing;

  /// Sobe a cada chamada de atenção que chega com a conversa aberta.
  final nudges = ValueNotifier<int>(0);

  final Set<int> _seenNudges = {};
  StreamSubscription<CoreEvent>? _subscription;
  DateTime? _typingSent;
  bool _disposed = false;

  Contact? get contact => contacts.byId(contactId);

  bool get theyAreTyping => contacts.isTyping(contactId);

  bool _opened = false;

  Future<void> open() async {
    contacts.viewing(contactId, open: true);
    _opened = true;
    _subscription = contacts.events.listen((event) {
      if (event.contactId == contactId || event.contactId == 0) {
        if (event.kind == CoreEventKind.messages) reload();
      }
    });
    _foreground = contacts.foreground;
    contacts.addListener(_contactsChanged);
    await reload(first: true);
  }

  bool _foreground = true;

  /// O app voltou à frente: o que chegou enquanto isso conta como lido agora.
  void _contactsChanged() {
    final back = contacts.foreground && !_foreground;
    _foreground = contacts.foreground;
    if (back && _messages.any((m) => m.unread)) reload();
    _notify();
  }

  /// Relê as mensagens carregadas (e as novas), e marca como lidas.
  Future<void> reload({bool first = false}) async {
    try {
      final count = _messages.length < messagesPage
          ? messagesPage
          : _messages.length + messagesPage;
      final fresh = await _store.messages(contactId, limit: count);
      if (_disposed) return;
      if (first) {
        _hasOlder = fresh.length >= count;
        _seenNudges.addAll([
          for (final m in fresh)
            if (m.kind == MessageKind.nudge) m.id,
        ]);
      } else {
        for (final m in fresh) {
          if (m.kind == MessageKind.nudge && _seenNudges.add(m.id)) {
            if (!m.outgoing) nudges.value++;
          }
        }
      }
      _messages = fresh;
      _loaded = true;
      _notify();
      // Com o app em segundo plano, ninguém leu: fica para quando ele voltar.
      if (contacts.foreground && fresh.any((m) => m.unread)) {
        await _store.markRead(contactId);
        await contacts.reload();
      }
    } on CoreException {
      _loaded = true;
      _notify();
    }
  }

  bool _loadingOlder = false;

  /// Carrega a página anterior.
  Future<void> loadOlder() async {
    if (!_hasOlder || _messages.isEmpty || _loadingOlder) return;
    _loadingOlder = true;
    try {
      final older = await _store.messages(
        contactId,
        before: _messages.first.id,
        limit: messagesPage,
      );
      if (_disposed) return;
      _hasOlder = older.length >= messagesPage;
      _seenNudges.addAll([
        for (final m in older)
          if (m.kind == MessageKind.nudge) m.id,
      ]);
      _messages = [...older, ..._messages];
      _notify();
    } on CoreException {
      // Fica o que já estava.
    } finally {
      _loadingOlder = false;
    }
  }

  ChatMessage? byId(int? id) {
    if (id == null) return null;
    for (final m in _messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  void startReply(ChatMessage message) {
    _editing = null;
    _replyTo = message;
    _notify();
  }

  void startEdit(ChatMessage message) {
    _replyTo = null;
    _editing = message;
    _notify();
  }

  void cancelComposer() {
    _replyTo = null;
    _editing = null;
    _notify();
  }

  /// Manda o texto (ou grava a edição). Lança CoreException.
  Future<void> send(String text) async {
    final editing = _editing;
    if (editing != null) {
      await _store.editMessage(editing.id, text);
    } else {
      await _store.sendText(contactId, text, replyTo: _replyTo?.id);
    }
    _replyTo = null;
    _editing = null;
    _typingSent = null;
    await reload();
    await contacts.reload();
  }

  /// Avisa o outro lado que estou digitando, no máximo a cada [typingEvery].
  void typed() {
    final now = _now();
    final last = _typingSent;
    if (last != null && now.difference(last) < typingEvery) return;
    _typingSent = now;
    _store.typing(contactId).catchError((Object _) {});
  }

  Future<void> nudge() async {
    final sent = await _store.sendNudge(contactId);
    _seenNudges.add(sent.id);
    await reload();
    await contacts.reload();
  }

  /// Manda um arquivo. Lança CoreException (uma foto que não dá para limpar, por
  /// exemplo).
  Future<void> sendFile(String path) async {
    await _store.sendFile(contactId, path);
    await reload();
    await contacts.reload();
  }

  // As notas de voz: a gravação em andamento, a que toca, e quanto cada uma dura.

  DateTime? _recordingSince;

  /// Desde quando grava; `null` sem gravação.
  DateTime? get recordingSince => _recordingSince;

  int? _playingId;
  Duration _position = Duration.zero;
  StreamSubscription<VoiceProgress>? _playback;
  final Map<int, Duration> _durations = {};
  final Set<int> _askedDurations = {};

  /// A nota que toca agora, e onde ela está.
  int? get playingId => _playingId;
  Duration get playingPosition => _position;

  /// Quanto dura a nota de [message], se já se sabe; senão pergunta ao núcleo e
  /// avisa quando souber.
  Duration? voiceDuration(ChatMessage message) {
    final known = _durations[message.id];
    if (known != null) return known;
    final file = message.file;
    if (file == null || !file.voice || file.state != FileState.done) {
      return null;
    }
    if (_askedDurations.add(message.id)) {
      _store
          .voiceDuration(message.id)
          .then((duration) {
            _durations[message.id] = duration;
            _notify();
          })
          .catchError((Object _) {});
    }
    return null;
  }

  /// Liga o microfone. Lança CoreException (`noAudio`).
  Future<void> startVoice() async {
    await stopVoice();
    await _store.startVoice();
    _recordingSince = _now();
    _notify();
  }

  Future<void> cancelVoice() async {
    if (_recordingSince == null) return;
    _recordingSince = null;
    _notify();
    await _store.cancelVoice();
  }

  /// Para de gravar e manda. Lança CoreException (`invalidMessage` se curta demais).
  Future<void> sendVoice() async {
    if (_recordingSince == null) return;
    _recordingSince = null;
    _notify();
    await _store.sendVoice(contactId);
    await reload();
    await contacts.reload();
  }

  /// Toca a nota de [message] (a que tocava para). Volta quando o som começa;
  /// lança CoreException se não der.
  Future<void> playVoice(ChatMessage message) async {
    await stopVoice();
    final started = Completer<void>();
    _playingId = message.id;
    _position = Duration.zero;
    _notify();
    void finish() {
      if (_playingId == message.id) {
        _playingId = null;
        _position = Duration.zero;
        _notify();
      }
      if (!started.isCompleted) started.complete();
    }

    _playback = _store
        .playVoice(message.id)
        .listen(
          (progress) {
            if (!started.isCompleted) started.complete();
            if (progress.done) return finish();
            _position = progress.position;
            _notify();
          },
          onError: (Object error) {
            if (!started.isCompleted) started.completeError(error);
            finish();
          },
          onDone: finish,
        );
    await started.future;
  }

  Future<void> stopVoice() async {
    final playback = _playback;
    _playback = null;
    if (playback == null) return;
    // Sem esperar: o fim do fluxo vem do núcleo, que para logo abaixo.
    unawaited(playback.cancel());
    _playingId = null;
    _position = Duration.zero;
    _notify();
    await _store.stopVoice().catchError((Object _) {});
  }

  Future<void> downloadFile(ChatMessage message) async {
    await _store.downloadFile(message.id);
    await reload();
  }

  Future<void> saveFile(ChatMessage message, String path) =>
      _store.saveFile(message.id, path);

  Future<Uint8List> fileBytes(ChatMessage message) =>
      _store.fileBytes(message.id);

  Future<void> react(ChatMessage message, int kind) async {
    await _store.react(message.id, message.myReaction == kind ? 0 : kind);
    await reload();
  }

  Future<void> deleteForMe(ChatMessage message) async {
    await _store.deleteForMe(message.id);
    if (_replyTo?.id == message.id || _editing?.id == message.id) {
      cancelComposer();
    }
    await reload();
    await contacts.reload();
  }

  Future<void> deleteForEveryone(ChatMessage message) async {
    await _store.deleteForEveryone(message.id);
    if (_editing?.id == message.id) cancelComposer();
    await reload();
    await contacts.reload();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    // A nota não segue tocando, nem o microfone ligado, com a conversa fechada.
    if (_playback != null) {
      _playback?.cancel();
      _store.stopVoice().catchError((Object _) {});
    }
    if (_recordingSince != null) _store.cancelVoice().catchError((Object _) {});
    if (_opened) contacts.viewing(contactId, open: false);
    _subscription?.cancel();
    contacts.removeListener(_contactsChanged);
    nudges.dispose();
    super.dispose();
  }
}

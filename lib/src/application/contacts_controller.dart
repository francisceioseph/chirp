// lib/src/application/contacts_controller.dart
//
// Os contatos, as conversas e a rede local, para as telas: liga o nó, carrega a lista,
// escuta o que muda sem a UI pedir (alguém leu nosso convite, chegou mensagem, alguém
// digita) e faz os convites e o aperto de mão. Os eventos são repassados a quem abre
// uma conversa (o ConversationController).
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/chirp_core.dart';

/// Por quanto tempo o "digitando" vale depois do último aviso.
const typingShownFor = Duration(seconds: 6);

class ContactsController extends ChangeNotifier {
  ContactsController(this.store);

  final ProfileStore store;

  List<Conversation> _conversations = const [];

  /// As conversas, a mais recente primeiro.
  List<Conversation> get conversations => _conversations;

  List<Contact> get contacts => [for (final c in _conversations) c.contact];

  /// Quantas mensagens não lidas, em todas as conversas.
  int get unread => _conversations.fold(0, (sum, c) => sum + c.unread);

  /// A rede não ligou: a lista aparece, mas não dá para convidar nem adicionar.
  CoreFailure? _networkFailure;
  CoreFailure? get networkFailure => _networkFailure;

  bool _loaded = false;
  bool get loaded => _loaded;

  /// A internet e os retransmissores, para explicar por que um contato não é
  /// alcançado.
  NetworkSettings _network = const NetworkSettings();
  NetworkSettings get network => _network;

  final Map<int, Timer> _typing = {};

  /// O contato está digitando agora.
  bool isTyping(int contactId) => _typing.containsKey(contactId);

  final _events = StreamController<CoreEvent>.broadcast();

  /// Os eventos do núcleo, para as telas abertas.
  Stream<CoreEvent> get events => _events.stream;

  StreamSubscription<CoreEvent>? _subscription;
  bool _disposed = false;

  Future<void> start() async {
    await reload();
    try {
      await store.startNetwork();
      await _subscription?.cancel();
      _subscription = store.events().listen(_onEvent);
      _networkFailure = null;
    } on CoreException catch (error) {
      _networkFailure = error.failure;
    }
    _notify();
  }

  void _onEvent(CoreEvent event) {
    if (_disposed) return;
    switch (event.kind) {
      case CoreEventKind.typing:
        _typing.remove(event.contactId)?.cancel();
        _typing[event.contactId] = Timer(typingShownFor, () {
          _typing.remove(event.contactId);
          _notify();
        });
        _notify();
      case CoreEventKind.messages:
        // Quem mandou a mensagem parou de digitar.
        _typing.remove(event.contactId)?.cancel();
        reload();
      case CoreEventKind.contact:
        reload();
    }
    _events.add(event);
  }

  Future<void> reload() async {
    try {
      _conversations = await store.conversations();
      _network = await store.networkSettings();
    } on CoreException {
      // A lista fica a de antes.
    }
    _loaded = true;
    _notify();
  }

  Future<String> createInvite({required bool qr}) => store.createInvite(qr: qr);

  /// Lê o convite e faz o aperto de mão. Devolve o contato, ou lança CoreException.
  Future<Contact> add(String link, {required bool scanned}) async {
    final contact = await store.addContact(link, scanned: scanned);
    await reload();
    return contact;
  }

  Future<String> safetyNumber(int id) => store.safetyNumber(id);

  Future<void> setVerified(int id, {required bool verified}) async {
    await store.setVerified(id, verified: verified);
    await reload();
  }

  Contact? byId(int id) {
    for (final conversation in _conversations) {
      if (conversation.contact.id == id) return conversation.contact;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    for (final timer in _typing.values) {
      timer.cancel();
    }
    _events.close();
    super.dispose();
  }
}

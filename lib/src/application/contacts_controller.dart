// lib/src/application/contacts_controller.dart
//
// Os contatos e a rede local, para as telas: liga o nó, carrega a lista, escuta o que
// muda sem a UI pedir (alguém leu nosso convite) e faz os convites e o aperto de mão.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/chirp_core.dart';

class ContactsController extends ChangeNotifier {
  ContactsController(this.store);

  final ProfileStore store;

  List<Contact> _contacts = const [];
  List<Contact> get contacts => _contacts;

  /// A rede não ligou: a lista aparece, mas não dá para convidar nem adicionar.
  CoreFailure? _networkFailure;
  CoreFailure? get networkFailure => _networkFailure;

  bool _loaded = false;
  bool get loaded => _loaded;

  StreamSubscription<int>? _changes;
  bool _disposed = false;

  Future<void> start() async {
    await reload();
    try {
      await store.startNetwork();
      await _changes?.cancel();
      _changes = store.contactChanges().listen((_) => reload());
      _networkFailure = null;
    } on CoreException catch (error) {
      _networkFailure = error.failure;
    }
    _notify();
  }

  Future<void> reload() async {
    try {
      _contacts = await store.contacts();
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
    for (final contact in _contacts) {
      if (contact.id == id) return contact;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _changes?.cancel();
    super.dispose();
  }
}

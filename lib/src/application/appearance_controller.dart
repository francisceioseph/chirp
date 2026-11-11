// lib/src/application/appearance_controller.dart
//
// A aparência do app: o padrão até o banco abrir, depois a que está nele. Mudar
// aparece na hora e grava; se a gravação falha, volta a de antes.

import 'package:flutter/foundation.dart';

import '../core/chirp_core.dart';

class AppearanceController extends ChangeNotifier {
  Appearance _value = const Appearance();
  Appearance get value => _value;

  ProfileStore? _store;

  /// O banco abriu (ou trocou): lê a aparência dele. Com `null` (o banco apagado),
  /// volta ao padrão.
  Future<void> attach(ProfileStore? store) async {
    if (identical(store, _store)) return;
    _store = store;
    if (store == null) {
      _publish(const Appearance());
      return;
    }
    try {
      final saved = await store.appearance();
      if (identical(store, _store)) _publish(saved);
    } on CoreException {
      // Fica o padrão: a aparência não vale uma tela de erro.
    }
  }

  /// Muda e grava. Devolve `false` se não gravou (e a de antes voltou).
  Future<bool> change(Appearance next) async {
    final store = _store;
    final before = _value;
    if (store == null || next == before) return next == before;
    _publish(next);
    try {
      await store.setAppearance(next);
      return true;
    } on CoreException {
      if (identical(store, _store) && _value == next) _publish(before);
      return false;
    }
  }

  void _publish(Appearance value) {
    if (value == _value) return;
    _value = value;
    notifyListeners();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/conversation_nest.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_discovery.dart';
import 'package:chirp/utils/app_logger.dart';

class PresenceController extends ChangeNotifier {
  final FlockDiscovery _discovery;
  final TielNestRepository _repo;
  final Identity _me;

  final _tiels = ConversationNest<Tiel>();
  Timer? _cleanupTimer;

  PresenceController({
    required FlockDiscovery discovery,
    required TielNestRepository repo,
    required Identity me,
  }) : _discovery = discovery,
       _repo = repo,
       _me = me;

  Identity get me => _me;

  List<Tiel> get allTiels => _tiels.all;

  List<Tiel> get onlineTiels =>
      _tiels.all.where((t) => t.status == TielStatus.connected).toList();

  Tiel? getTiel(String id) => _tiels[id];

  Future<void> init() async {
    _log("🚀 Iniciando radar de presença...");

    try {
      await _hydrateFromDisk();
      await _discovery.advertise(_me.id, _me.name);

      _discovery.discover((id, name, address) {
        _onTielFound(id, name, address);
      });

      _startCleanupTimer();

      _log("✅ Radar operando normalmente.");
    } catch (e) {
      _log("💥 Falha ao iniciar radar de presença", isError: true, error: e);
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _hydrateFromDisk() async {
    _log("📦 Carregando Tiels conhecidos do ninho...");
    final history = await _repo.list();

    for (var tiel in history) {
      // Começamos todos como 'away' até que o radar os encontre novamente
      _tiels.put(tiel.copyWith(status: TielStatus.away));
    }
    notifyListeners();
  }

  void _onTielFound(String id, String name, String address) {
    if (id == _me.id) return;

    _tiels.upsert(
      id,
      create: () {
        _log("🐣 Novo Tiel detectado no radar: $name ($id)");
        return Tiel(
          id: id,
          name: name,
          address: address,
          lastSeen: DateTime.now(),
          status: TielStatus.discovered,
        );
      },
      update: (existing) {
        final isReconnecting = existing.status == TielStatus.away;
        if (isReconnecting) _log("📡 Tiel retornou ao alcance: $name");

        return existing.copyWith(
          name: name,
          address: address,
          lastSeen: DateTime.now(),
          status: existing.publicKey != null
              ? TielStatus.connected
              : TielStatus.discovered,
        );
      },
    );

    notifyListeners();
  }

  void _checkConnectivity() {
    final now = DateTime.now();
    bool changed = false;

    _tiels.updateAll((id, tiel) {
      if (tiel.status == TielStatus.away) return tiel;

      // Se não ouvimos o "pio" do tiel por mais de 120 segundos, ele voou para longe
      if (now.difference(tiel.lastSeen).inSeconds > 120) {
        _log("💤 Tiel ficou inativo (away): ${tiel.name}");
        changed = true;
        return tiel.copyWith(status: TielStatus.away);
      }
      return tiel;
    });

    if (changed) notifyListeners();
  }

  void updateTiel(Tiel tiel) {
    _tiels.put(tiel);
    notifyListeners();
  }

  // --- Helpers ---

  void _log(String message, {bool isError = false, dynamic error}) {
    if (isError) {
      log.e("[PresenceController] $message", error: error);
    } else {
      log.d("[PresenceController] $message");
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _discovery.stop();
    _log("🛑 Radar de presença desligado.");
    super.dispose();
  }
}

import 'dart:async';

import 'package:chirp/models/tiel.dart';
import 'package:chirp/services/flock_discovery.dart';
import 'package:chirp/services/flock_manager.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/material.dart';

class ChirpController extends ChangeNotifier {
  final FlockDiscovery _flockDiscovery;
  final FlockManager _flockManager;
  final String _tielId;

  Timer? _cleanupTimer;

  final Map<String, Tiel> _nearbyTiels = {};
  final List<String> _messages = [];

  String get tielId => _tielId;
  List<Tiel> get nearbyTiels => _nearbyTiels.values.toList();
  List<String> get messages => _messages;

  ChirpController(this._flockDiscovery, this._flockManager, this._tielId) {
    _setupListeners();
  }

  void _setupListeners() {
    _flockManager.messages.listen((msg) {
      _messages.add(msg);

      log.d("📩 Mensagem recebida no Controller: $msg");
      notifyListeners();
    });
  }

  Future<void> startServices() async {
    log.d("🚀 Stretching the tiel wings...");

    try {
      _flockManager.init();

      await _flockDiscovery.advertise(_tielId);
      await _flockDiscovery.discover((String name, String address) {
        _onPeerFound(name, address);
      });

      _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        removeInactiveTiels();
      });
    } catch (e) {
      log.e("❌ Erro ao iniciar serviços", error: e);
    }
  }

  void sendChirp(String targetId, String text) {
    try {
      _flockManager.send(targetId, text);
      _messages.add("Você: $text");
      notifyListeners();
    } catch (e) {
      log.e("⚠️ Falha ao enviar chirp para $targetId", error: e);
    }
  }

  @override
  void dispose() {
    _flockDiscovery.stop();
    _flockManager.dispose();
    _cleanupTimer?.cancel();

    super.dispose();
  }

  void _onPeerFound(String name, String address) {
    if (name == _tielId) return;

    if (!_nearbyTiels.containsKey(name)) {
      _nearbyTiels[name] = Tiel(
        id: name.hashCode.toString(),
        name: name,
        address: address,
        lastSeen: DateTime.now(),
      );

      log.i("🐦 New Tiel found: $name em $address");
      notifyListeners();
    }
  }

  void removeInactiveTiels() {
    final now = DateTime.now();
    final initialLength = _nearbyTiels.length;

    _nearbyTiels.removeWhere((key, tiel) {
      return now.difference(tiel.lastSeen).inSeconds > 60;
    });

    if (initialLength != _nearbyTiels.length) {
      notifyListeners();
    }
  }
}

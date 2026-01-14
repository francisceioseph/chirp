import 'dart:async';

import 'package:chirp/models/message.dart';
import 'package:chirp/models/tiel.dart';
import 'package:chirp/services/flock_discovery.dart';
import 'package:chirp/services/flock_manager.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ChatType { individual, flock }

class ChirpController extends ChangeNotifier {
  final FlockDiscovery _flockDiscovery;
  final FlockManager _flockManager;
  final String _tielId;

  final uuid = Uuid();

  Timer? _cleanupTimer;
  String? _activeChatId;

  final Map<String, Tiel> _nearbyTiels = {};
  final Map<String, List<ChirpMessage>> _conversations = {};
  final Map<String, ChatType> _chatMetadata = {};

  String get tielId => _tielId;
  List<Tiel> get nearbyTiels => _nearbyTiels.values.toList();

  String? get activeChatId => _activeChatId;

  ChirpController(this._flockDiscovery, this._flockManager, this._tielId) {
    _setupListeners();
  }

  List<ChirpMessage> getMessagesFor(String chatId) =>
      _conversations[chatId] ?? [];

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

  void selectChat(String? chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  void sendChirp(
    String targetId,
    String text, {
    ChatType type = ChatType.individual,
  }) {
    try {
      _flockManager.send(targetId, text);

      final message = ChirpMessage(
        id: uuid.v4(),
        senderId: _tielId,
        body: text,
        dateCreated: DateTime.now(),
        isFromMe: true,
      );

      _chatMetadata[targetId] = type;
      _addMessageToConversation(targetId, message);

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

  void _setupListeners() {
    _flockManager.messages.listen((dynamic incoming) {
      _addMessageToConversation(incoming.senderId, incoming);
    });
  }

  void _addMessageToConversation(String chatId, ChirpMessage message) {
    _conversations.putIfAbsent(chatId, () => []);
    _conversations[chatId]!.add(message);

    log.d("📩 Mensagem organizada para o chat: $chatId");
    notifyListeners();
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

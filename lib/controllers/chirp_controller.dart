import 'dart:async';
import 'dart:convert';

import 'package:chirp/models/identity.dart';
import 'package:chirp/models/message.dart';
import 'package:chirp/models/tiel.dart';
import 'package:chirp/services/flock_discovery.dart';
import 'package:chirp/services/flock_manager.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChirpController extends ChangeNotifier {
  final uuid = Uuid();

  final FlockDiscovery _flockDiscovery;
  final FlockManager _flockManager;
  final Identity _me;

  Timer? _cleanupTimer;
  String? _activeChatId;

  final Map<String, Tiel> _tiels = {};
  final Map<String, Flock> _flocks = {};

  final Map<String, List<ChirpMessage>> _conversations = {};

  String get tielId => _me.id;
  String? get activeChatId => _activeChatId;

  List<Conversation> get allConversations => [
    ..._tiels.values,
    ..._flocks.values,
  ];

  ChirpController(this._flockDiscovery, this._flockManager, this._me) {
    _setupListeners();
  }

  // ### MESSAGE MANAGEMENT ###

  List<ChirpMessage> getMessagesFor(String chatId) =>
      _conversations[chatId] ?? [];

  void selectChat(String? chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  Future<void> startServices() async {
    log.d("🚀 Stretching the tiel wings...");

    try {
      _flockManager.init();

      await _flockDiscovery.advertise(_me.id, _me.name, _me.publicKey);
      await _flockDiscovery.discover((
        String id,
        String name,
        String pubKey,
        String address,
      ) {
        _onPeerFound(id, name, pubKey, address);
      });

      _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        updateTielsStatus();
      });
    } catch (e) {
      log.e("❌ Erro ao iniciar serviços", error: e);
    }
  }

  void sendChirp(String targetId, String text) {
    try {
      final message = ChirpMessage(
        id: uuid.v4(),
        senderId: _me.id,
        author: _me.name,
        body: text,
        dateCreated: DateTime.now(),
        isFromMe: true,
      );

      _flockManager.chirp(targetId, message);

      _addMessageToConversation(targetId, message);
    } catch (e) {
      log.e("⚠️ Falha ao enviar chirp para $targetId", error: e);
    }
  }

  void _addMessageToConversation(String chatId, ChirpMessage message) {
    _conversations.putIfAbsent(chatId, () => []);
    _conversations[chatId]!.add(message);

    log.d("📩 Mensagem organizada para o chat: $chatId");
    notifyListeners();
  }

  //  ### DISCOVERY LOGIC ###

  @override
  void dispose() {
    _flockDiscovery.stop();
    _flockManager.dispose();
    _cleanupTimer?.cancel();

    super.dispose();
  }

  void _setupListeners() {
    _flockManager.messages.listen((dynamic rawData) {
      try {
        final Map<String, dynamic> dataMap = jsonDecode(rawData);
        final ChirpMessage incoming = ChirpMessage.fromJson(dataMap);

        Future.microtask(() {
          _addMessageToConversation(incoming.senderId, incoming);
        });
      } catch (e) {
        log.e("Erro ao processar mensagem recebida $e");
      }
    });
  }

  void _onPeerFound(
    String tielId,
    String tielName,
    String tielPubKey,
    String tielAddress,
  ) {
    if (tielId == _me.id) return;

    _tiels.update(
      tielName,
      (existing) => existing.copyWith(
        name: tielName,
        address: tielAddress,
        lastSeen: DateTime.now(),
        status: .online,
      ),
      ifAbsent: () => Tiel(
        id: tielId,
        name: tielName,
        address: tielAddress,
        lastSeen: DateTime.now(),
        status: .online,
        publicKey: tielPubKey,
      ),
    );

    notifyListeners();
  }

  void updateTielsStatus() {
    final now = DateTime.now();
    var changed = false;

    _tiels.updateAll((name, tiel) {
      if (now.difference(tiel.lastSeen).inSeconds > 120) {
        changed = true;
        return tiel.copyWith(status: .disconnected);
      }

      if (now.difference(tiel.lastSeen).inSeconds > 120) {
        changed = true;
        return tiel.copyWith(status: .away);
      }

      return tiel;
    });

    if (changed) {
      notifyListeners();
    }
  }
}

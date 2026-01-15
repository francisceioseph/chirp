import 'dart:async';
import 'dart:convert';

import 'package:chirp/models/chirp_packet.dart';
import 'package:chirp/models/identity.dart';
import 'package:chirp/models/message.dart';
import 'package:chirp/models/tiel.dart';
import 'package:chirp/services/flock_discovery.dart';
import 'package:chirp/services/flock_manager.dart';
import 'package:chirp/services/secure_chirp.dart';
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
  final List<ChirpRequestPacket> _pendingRequests = [];

  String get tielId => _me.id;
  String? get activeChatId => _activeChatId;
  List<ChirpRequestPacket> get pendingRequests => _pendingRequests;
  int get notificationCount => _pendingRequests.length;

  List<Conversation> get allConversations => [
    ..._tiels.values,
    ..._flocks.values,
  ];

  ChirpController(this._flockDiscovery, this._flockManager, this._me) {
    _setupListeners();
  }

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

      await _flockDiscovery.advertise(_me.id, _me.name);
      await _flockDiscovery.discover((String id, String name, String address) {
        _onTielFound(id, name, address);
      });

      _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        updateTielsStatus();
      });
    } catch (e) {
      log.e("❌ Erro ao iniciar serviços $e");
    }
  }

  void requestFriendship(Tiel target) {
    final packet = ChirpRequestPacket(
      fromId: _me.id,
      fromName: _me.name,
      publicKey: _me.publicKey,
    );

    _flockManager.sendPacket(target.id, packet);

    _tiels.update(target.id, (tiel) => tiel.copyWith(status: .pending));
    notifyListeners();
  }

  void acceptFriendship(ChirpRequestPacket request) {
    final packet = ChirpAcceptPacket(
      fromId: _me.id,
      fromName: _me.name,
      publicKey: _me.publicKey,
    );

    _flockManager.sendPacket(request.fromId, packet);

    _tiels.update(
      request.fromId,
      (tiel) => tiel.copyWith(publicKey: request.publicKey, status: .connected),
    );

    _pendingRequests.removeWhere((req) => req.fromId == request.fromId);
    notifyListeners();
  }

  void sendChirp(String targetId, String text) {
    final tiel = _tiels[targetId];

    if (tiel == null || tiel.publicKey == null || tiel.status != .connected) {
      log.w("⚠️ Tentativa de envio para $targetId sem handshake completo.");
      return;
    }

    try {
      final message = ChirpMessage(
        id: uuid.v4(),
        senderId: _me.id,
        author: _me.name,
        body: text,
        dateCreated: DateTime.now(),
        isFromMe: true,
      );

      final jsonMessage = jsonEncode(message.toJson());
      final envelope = SecureChirp.encrypt(tiel.publicKey!, jsonMessage);

      final packet = ChirpMessagePacket(
        fromId: _me.id,
        fromName: _me.name,
        envelope: envelope,
      );

      _flockManager.sendPacket(targetId, packet);

      _addMessageToConversation(targetId, message);

      log.i("🦜🔐 Chirp criptografado e enviado para ${tiel.name}");
    } catch (e) {
      log.e("❌ Falha no mecanismo de envio seguro para $targetId", error: e);
    }
  }

  void updateTielsStatus() {
    final now = DateTime.now();
    var changed = false;

    _tiels.updateAll((name, tiel) {
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

  void _addMessageToConversation(String chatId, ChirpMessage message) {
    _conversations.putIfAbsent(chatId, () => []);
    _conversations[chatId]!.add(message);

    log.d("📩 Mensagem organizada para o chat: $chatId");
    notifyListeners();
  }

  void _setupListeners() {
    _flockManager.packets.listen((dynamic rawData) {
      try {
        final Map<String, dynamic> json = jsonDecode(rawData);
        final packet = ChirpPacket.fromJson(json);

        _handleIncomingPacket(packet);
      } catch (e) {
        log.e("Erro ao processar pacote recebido $e");
      }
    });
  }

  void _handleIncomingPacket(ChirpPacket packet) {
    switch (packet) {
      case ChirpRequestPacket():
        _pendingRequests.add(packet);
        notifyListeners();
        break;

      case ChirpAcceptPacket():
        _tiels.update(
          packet.fromId,
          (t) => t.copyWith(
            publicKey: packet.publicKey,
            status: TielStatus.connected,
          ),
        );
        notifyListeners();
        break;

      case ChirpMessagePacket():
        _handleIncomingMessage(packet);
        break;

      case ChirpIdentityPacket():
        break;
    }
  }

  void _handleIncomingMessage(ChirpMessagePacket packet) {
    try {
      final decryptedJson = SecureChirp.decrypt(
        _me.privateKey!,
        packet.envelope,
      );

      final Map<String, dynamic> msgMap = jsonDecode(decryptedJson);
      final incomingMessage = ChirpMessage.fromJson(msgMap);

      _addMessageToConversation(packet.fromId, incomingMessage);
    } catch (e) {
      log.e("Falha ao descriptografar mensagem: $e");
    }
  }

  void _onTielFound(String id, String name, String address) {
    if (id == _me.id) return;

    _tiels.update(
      name,
      (existing) => existing.copyWith(
        name: name,
        address: address,
        lastSeen: DateTime.now(),
      ),
      ifAbsent: () => Tiel(
        id: id,
        name: name,
        address: address,
        lastSeen: DateTime.now(),
        status: .discovered,
      ),
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _flockDiscovery.stop();
    _flockManager.dispose();
    _cleanupTimer?.cancel();

    super.dispose();
  }
}

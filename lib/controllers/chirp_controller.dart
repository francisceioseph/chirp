import 'dart:async';
import 'dart:convert';

import 'package:chirp/models/chirp_packet.dart';
import 'package:chirp/models/identity.dart';
import 'package:chirp/models/message.dart';
import 'package:chirp/models/tiel.dart';
import 'package:chirp/repositories/message_nest_repository.dart';
import 'package:chirp/repositories/tiel_nest_repository.dart';
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

  final MessageNestRepository _messagesRepo;
  final TielNestRepository _tielsRepo;

  Timer? _cleanupTimer;
  String? _activeChatId;

  final Map<String, Tiel> _tiels = {};
  final Map<String, Flock> _flocks = {};

  final Map<String, List<ChirpMessage>> _messagesByChatId = {};
  final List<ChirpRequestPacket> _pendingRequests = [];

  String get myId => _me.id;
  String get myName => _me.name;

  String? get activeChatId => _activeChatId;

  List<ChirpRequestPacket> get pendingRequests {
    return _pendingRequests
        .where((packet) => _tiels.containsKey(packet.fromId))
        .toList();
  }

  int get notificationCount => pendingRequests.length;

  List<Conversation> get allConversations => [
    ..._tiels.values,
    ..._flocks.values,
  ];

  ChirpController(
    this._flockDiscovery,
    this._flockManager,
    this._messagesRepo,
    this._tielsRepo,
    this._me,
  ) {
    _setupListeners();
  }

  Conversation? getConversationFor(String conversationId) {
    return allConversations
        .where((conv) => conv.id == conversationId)
        .firstOrNull;
  }

  List<ChirpMessage> getMessagesFor(String chatId) =>
      _messagesByChatId[chatId] ?? [];

  void selectChat(String? chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  Future<void> startServices() async {
    log.d("🚀 Stretching the tiel wings...");

    try {
      _flockManager.init();

      await _hydrateTiels();
      await _hydrateMessages();

      notifyListeners();

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

    if (_tiels.containsKey(target.id)) {
      _tiels[target.id] = _tiels[target.id]!.copyWith(
        status: TielStatus.pending,
      );

      notifyListeners();
    }
  }

  void acceptFriendship(ChirpRequestPacket request) async {
    final packet = ChirpAcceptPacket(
      fromId: _me.id,
      fromName: _me.name,
      publicKey: _me.publicKey,
    );

    _flockManager.sendPacket(request.fromId, packet);

    final tiel = _tiels[request.fromId];

    final newTiel = tiel!.copyWith(
      publicKey: request.publicKey,
      status: .connected,
    );

    _tiels[request.fromId] = newTiel;
    _pendingRequests.removeWhere((req) => req.fromId == request.fromId);

    await _tielsRepo.save(newTiel);

    notifyListeners();
  }

  Future<void> sendChirp(String targetId, String text) async {
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

      await _messagesRepo.save(message);

      _addMessageToConversation(targetId, message);

      log.i("🦜🔐 Chirp criptografado e enviado para ${tiel.name}");
    } catch (e) {
      log.e("❌ Falha no mecanismo de envio seguro para $targetId", error: e);
    }
  }

  void updateTielsStatus() {
    final now = DateTime.now();
    var changed = false;

    _tiels.updateAll((id, tiel) {
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

  Future<void> _hydrateMessages() async {
    for (var chat in allConversations) {
      final history = await _messagesRepo.list(chat.id);

      if (history.isNotEmpty) {
        _messagesByChatId[chat.id] = history;
      }
    }
  }

  Future<void> _hydrateTiels() async {
    try {
      final tiels = await _tielsRepo.list();

      for (var tiel in tiels) {
        _tiels[tiel.id] = tiel.copyWith(status: .away);
      }
    } catch (e) {
      log.e("Error hydrating tiels: $e");
    }
  }

  void _addMessageToConversation(String chatId, ChirpMessage message) {
    _messagesByChatId.putIfAbsent(chatId, () => []);

    bool alreadyExists = _messagesByChatId[chatId]!.any(
      (m) => m.id == message.id,
    );

    if (!alreadyExists) {
      _messagesByChatId[chatId]!.add(message);
      _messagesByChatId[chatId]!.sort(
        (a, b) => a.dateCreated.compareTo(b.dateCreated),
      );

      log.d("📩 Chirp added to $chatId");
      notifyListeners();
    }
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

  void _handleIncomingMessage(ChirpMessagePacket packet) async {
    try {
      final decryptedJson = SecureChirp.decrypt(
        _me.privateKey!,
        packet.envelope,
      );

      final Map<String, dynamic> msgMap = jsonDecode(decryptedJson);
      var message = ChirpMessage.fromJson(msgMap);

      await _messagesRepo.save(message);

      _addMessageToConversation(packet.fromId, message);
    } catch (e) {
      log.e("Falha ao descriptografar mensagem: $e");
    }
  }

  void _onTielFound(String id, String name, String address) {
    if (id == _me.id) return;

    _tiels.update(
      id,
      (existing) {
        final newStatus = existing.publicKey != null
            ? TielStatus.connected
            : TielStatus.discovered;

        return existing.copyWith(
          name: name,
          address: address,
          lastSeen: DateTime.now(),
          status: newStatus,
        );
      },
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

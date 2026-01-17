import 'dart:async';
import 'dart:convert';

import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/message.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_file_picker_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
import 'package:chirp/domain/usecases/friendship/accept_friendship_use_case.dart';
import 'package:chirp/domain/usecases/friendship/request_friendship_use_case.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_discovery.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';
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

  final RequestFriendshipUseCase _requestFriendshipUseCase;
  final AcceptFriendshipUseCase _acceptFriendshipUseCase;
  final SendChirpUseCase _sendChirpUseCase;
  final OfferFileUseCase _offerFileUseCase;
  final OpenFilePickerUseCase _openFilePickerUseCase;

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

  ChirpController({
    required FlockDiscovery flockDiscovery,
    required FlockManager flockManager,
    required Identity me,

    required TielNestRepository tielsRepository,
    required MessageNestRepository messagesRepository,

    required RequestFriendshipUseCase requestFriendshipUseCase,
    required AcceptFriendshipUseCase acceptFriendshipUseCase,
    required SendChirpUseCase sendChirpUseCase,
    required OfferFileUseCase offerFileUseCase,
    required OpenFilePickerUseCase openFilePickerUseCase,
  }) : _flockDiscovery = flockDiscovery,
       _flockManager = flockManager,
       _me = me,
       _tielsRepo = tielsRepository,
       _messagesRepo = messagesRepository,
       _requestFriendshipUseCase = requestFriendshipUseCase,
       _acceptFriendshipUseCase = acceptFriendshipUseCase,
       _sendChirpUseCase = sendChirpUseCase,
       _offerFileUseCase = offerFileUseCase,
       _openFilePickerUseCase = openFilePickerUseCase {
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

  Future<void> requestFriendship(Tiel target) async {
    try {
      final tiel = await _requestFriendshipUseCase.execute(target);

      if (_tiels.containsKey(tiel.id)) {
        _tiels[tiel.id] = tiel;
        notifyListeners();

        log.i("🐦 Solicitação de amizade enviada para ${target.name}");
      }
    } catch (e) {
      log.e("❌ Falha ao solicitar amizade: $e");
    }
  }

  Future<void> acceptFriendship(ChirpRequestPacket request) async {
    try {
      final tiel = _tiels[request.fromId];

      if (tiel != null) {
        final newTiel = await _acceptFriendshipUseCase.execute(tiel, request);

        _tiels[request.fromId] = newTiel;
        _pendingRequests.removeWhere((req) => req.fromId == request.fromId);

        notifyListeners();
      }
    } catch (e) {
      log.e("Falha ao aceitar amizade");
    }
  }

  Future<void> sendChirp(String targetId, String text) async {
    final tiel = _tiels[targetId];

    if (tiel == null || tiel.publicKey == null || tiel.status != .connected) {
      log.w("Tentativa de envio para $targetId sem handshake completo.");
      return;
    }

    try {
      final message = await _sendChirpUseCase.execute(tiel, text);
      _addMessageToConversation(targetId, message);
    } catch (e) {
      log.e("Falha no mecanismo de envio seguro para $targetId", error: e);
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

  Future<void> pickAndOfferFile(String targetId) async {
    final tiel = _tiels[targetId];

    if (tiel == null || tiel.publicKey == null || tiel.status != .connected) {
      log.w("Tentativa de envio para $targetId sem handshake completo.");
      return;
    }

    try {
      final output = await _openFilePickerUseCase.execute();

      if (output.isNotEmpty) {
        _offerFileUseCase.execute(tiel, output.metadata!);
      }
    } catch (e) {
      log.e("Erro ao selecionar arquivos $e");
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

      case ChirpFileOfferPacket():
        log.w("File offer not implemented");
        break;

      case ChirpFileAcceptPacket():
        log.w("File accpet not implemented yet");
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

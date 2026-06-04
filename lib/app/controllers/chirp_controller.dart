import 'dart:async';

import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/messages_nest.dart';
import 'package:chirp/domain/usecases/chat/parse_incoming_packet_use_case.dart';
import 'package:chirp/domain/usecases/chat/receive_chirp_use_case.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChirpController extends ChangeNotifier {
  final uuid = Uuid();

  final FlockManager _flockManager;
  final Identity _me;

  final TielNestRepository _tielsRepo;

  final ParseIncomingPacketUseCase _parseIncomingPacketUseCase;
  final ReceiveChirpUseCase _receiveChirpUseCase;

  final FriendshipController _friendshipCtrl;

  String? _activeChatId;

  final _messages = MessagesNest();

  String get myId => _me.id;
  String get myName => _me.name;

  String? get activeChatId => _activeChatId;
  Map<String, Tiel> get _tiels => _tielsRepo.cached;

  List<Tiel> get allConversations => [..._tiels.values];

  ChirpController({
    required FlockManager flockManager,
    required Identity me,

    required TielNestRepository tielsRepository,

    required ParseIncomingPacketUseCase parseIncomingPacketUseCase,
    required ReceiveChirpUseCase receiveChirpUseCase,

    required FriendshipController friendshipCtrl,
  }) : _flockManager = flockManager,
       _me = me,
       _tielsRepo = tielsRepository,
       _parseIncomingPacketUseCase = parseIncomingPacketUseCase,
       _receiveChirpUseCase = receiveChirpUseCase,

       _friendshipCtrl = friendshipCtrl {
    _tielsRepo.addListener(notifyListeners);
  }

  Future<void> startServices() async {
    log.i("🚀 [Serviços] Iniciando motores do bando...");

    try {
      _setupListeners();
      _flockManager.init();
      log.i("✅ [Serviços] Bando pronto para voar.");
    } catch (e) {
      log.e("❌ [Serviços] Falha crítica na inicialização", error: e);
    }
  }

  void _setupListeners() {
    _flockManager.packets.listen((dynamic rawData) {
      try {
        final packet = _parseIncomingPacketUseCase.execute(rawData);
        _processIncomingPacket(packet);
      } catch (e) {
        log.e("[Serviços] Erro ao processar pacote recebido $e");
      }
    });
  }

  void _processIncomingPacket(ChirpPacket packet) {
    switch (packet) {
      case ChirpRequestPacket():
        _friendshipCtrl.handlePendingFriendship(packet);
        break;

      case ChirpAcceptPacket():
        _friendshipCtrl.handleCompleteHandshake(packet);
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
    final sender = packet.fromId;

    try {
      log.d("📥 [Chat] Novo pacote recebido de $sender. Descriptografando...");

      final message = await _receiveChirpUseCase.execute(packet);

      _messages.add(packet.fromId, message);
      notifyListeners();

      log.i("📩 [Chat] Mensagem de $sender processada e guardada no ninho.");
    } catch (e) {
      log.e(
        "🔐 [Chat] Erro de segurança: Não foi possível ler mensagem de $sender",
        error: e,
      );
    }
  }

  @override
  void dispose() {
    _flockManager.dispose();

    super.dispose();
  }
}

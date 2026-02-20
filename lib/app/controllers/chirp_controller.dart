import 'dart:async';

import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/infrastructure/data/chirp_cache.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/message.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/messages_nest.dart';
import 'package:chirp/domain/usecases/chat/parse_incoming_packet_use_case.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_file_picker_use_case.dart';
import 'package:chirp/domain/usecases/chat/receive_chirp_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_discovery.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
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

  final SendChirpUseCase _sendChirpUseCase;
  final OfferFileUseCase _offerFileUseCase;
  final OpenFilePickerUseCase _openFilePickerUseCase;
  final ParseIncomingPacketUseCase _parseIncomingPacketUseCase;
  final ReceiveChirpUseCase _receiveChirpUseCase;

  final FriendshipController _friendshipCtrl;

  Timer? _cleanupTimer;
  String? _activeChatId;

  // o problema acontece porque tiels não usa o tiels repository, mas o chirp cache
  final _tiels = ChirpCache<Tiel>();
  final _flocks = ChirpCache<Flock>();
  final _messages = MessagesNest();

  String get myId => _me.id;
  String get myName => _me.name;

  String? get activeChatId => _activeChatId;

  List<Conversation> get allConversations => [..._tiels.all, ..._flocks.all];

  ChirpController({
    required FlockDiscovery flockDiscovery,
    required FlockManager flockManager,
    required Identity me,

    required TielNestRepository tielsRepository,
    required MessageNestRepository messagesRepository,

    required SendChirpUseCase sendChirpUseCase,
    required OfferFileUseCase offerFileUseCase,
    required OpenFilePickerUseCase openFilePickerUseCase,
    required ParseIncomingPacketUseCase parseIncomingPacketUseCase,
    required ReceiveChirpUseCase receiveChirpUseCase,

    required FriendshipController friendshipCtrl,
  }) : _flockDiscovery = flockDiscovery,
       _flockManager = flockManager,
       _me = me,
       _tielsRepo = tielsRepository,
       _messagesRepo = messagesRepository,
       _sendChirpUseCase = sendChirpUseCase,
       _offerFileUseCase = offerFileUseCase,
       _openFilePickerUseCase = openFilePickerUseCase,
       _parseIncomingPacketUseCase = parseIncomingPacketUseCase,
       _receiveChirpUseCase = receiveChirpUseCase,

       _friendshipCtrl = friendshipCtrl {
    _setupListeners();

    _tielsRepo.addListener(notifyListeners);
  }

  Conversation? getConversationFor(String conversationId) {
    return allConversations
        .where((conv) => conv.id == conversationId)
        .firstOrNull;
  }

  List<ChirpMessage> getMessagesFor(String chatId) => _messages.forChat(chatId);

  void selectChat(String? chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  Future<void> startServices() async {
    log.i("🚀 [Serviços] Iniciando motores do bando...");

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

      log.i("✅ [Serviços] Bando pronto para voar.");
    } catch (e) {
      log.e("❌ [Serviços] Falha crítica na inicialização", error: e);
    }
  }

  Future<void> sendChirp(String targetId, String text) async {
    final tiel = _tiels[targetId];

    if (tiel == null || tiel.publicKey == null || tiel.status != .connected) {
      log.w(
        "🚫 [Chat] Tentativa de envio negada: ${tiel?.name ?? targetId} não está conectado.",
      );
      return;
    }

    try {
      log.d(
        "📤 [Chat] Criptografando e enviando mensagem para ${tiel.name}...",
      );

      final message = await _sendChirpUseCase.execute(tiel, text);

      _messages.add(targetId, message);
      notifyListeners();

      log.i("✨ [Chat] Mensagem entregue ao bando para ${tiel.name}");
    } catch (e) {
      log.e("💥 [Chat] Erro no envio seguro para ${tiel.name}", error: e);
    }
  }

  void updateTielsStatus() {
    final now = DateTime.now();
    final birdsGoneAway = <String>[];

    _tiels.updateAll((id, tiel) {
      if (tiel.status == TielStatus.away) return tiel;

      if (now.difference(tiel.lastSeen).inSeconds > 120) {
        birdsGoneAway.add(tiel.name);
        return tiel.copyWith(status: TielStatus.away);
      }

      return tiel;
    });

    if (birdsGoneAway.isNotEmpty) {
      log.d(
        "💤 [Status] ${birdsGoneAway.length} Tiels ficaram inativos: ${birdsGoneAway.join(', ')}",
      );
      notifyListeners();
    }
  }

  Future<void> pickAndOfferFile(String targetId) async {
    final tiel = _tiels[targetId];

    if (tiel == null ||
        tiel.publicKey == null ||
        tiel.status != TielStatus.connected) {
      log.w(
        "🚫 [Arquivos] Oferta negada: ${tiel?.name ?? targetId} não possui handshake completo.",
      );
      return;
    }

    try {
      log.d("📂 [Arquivos] Abrindo seletor para enviar para ${tiel.name}...");
      final output = await _openFilePickerUseCase.execute();

      if (output.metadata != null) {
        final fileName = output.metadata!.name;
        final fileSize = output.metadata!.size;

        log.d(
          "📦 [Arquivos] Arquivo selecionado: $fileName ($fileSize bytes). Enviando oferta...",
        );

        _offerFileUseCase.execute(tiel, output.metadata!);

        log.d(
          "✨ [Arquivos] Oferta de '$fileName' enviada com sucesso para ${tiel.name}.",
        );
      } else {
        log.d("📝 [Arquivos] Seleção de arquivo cancelada pelo usuário.");
      }
    } catch (e) {
      log.e(
        "💥 [Arquivos] Falha no fluxo de oferta de arquivo para ${tiel.name}",
        error: e,
      );
    }
  }

  Future<void> _hydrateMessages() async {
    try {
      log.d("📦 [Hidratação] Iniciando leitura do histórico de mensagens...");

      for (var chat in allConversations) {
        final history = await _messagesRepo.list(chat.id);

        if (history.isNotEmpty) {
          _messages.addAll(chat.id, history);
        }
      }

      log.i("✅ [Hidratação] Concluída com sucesso");
    } catch (e) {
      log.e("💥 [Hidratação] Falha ao restaurar mensagens do banco local $e");
    }
  }

  Future<void> _hydrateTiels() async {
    try {
      log.d("[Hidratação] Hidratando lista de tiels");

      final tiels = await _tielsRepo.list();

      for (var tiel in tiels) {
        _tiels.update(tiel.id, (t) => t.copyWith(status: .away));
      }

      log.d("[Hidratação] Lista de tiels hidratadas.");
    } catch (e) {
      log.e("[Hidratação] Erro ao hidratar lista de tiels: $e");
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
        _friendshipCtrl.handlePendingRequest(packet);
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

  void _onTielFound(String id, String name, String address) {
    if (id == _me.id) return;

    _tiels.upsert(
      id,
      create: () {
        log.d("🐣 [Radar] Novo Tiel descoberto: $name ($id) em $address");
        return Tiel(
          id: id,
          name: name,
          address: address,
          lastSeen: DateTime.now(),
          status: TielStatus.discovered,
        );
      },
      update: (existing) {
        log.d("📡 [Radar] Ping de presença: $name ($id)");

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

import 'dart:async';

import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/domain/entities/conversation.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/chirp_message.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/messages_nest.dart';
import 'package:chirp/domain/usecases/chat/parse_incoming_packet_use_case.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_file_picker_use_case.dart';
import 'package:chirp/domain/usecases/chat/receive_chirp_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChirpController extends ChangeNotifier {
  final uuid = Uuid();

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
    required MessageNestRepository messagesRepository,

    required SendChirpUseCase sendChirpUseCase,
    required OfferFileUseCase offerFileUseCase,
    required OpenFilePickerUseCase openFilePickerUseCase,
    required ParseIncomingPacketUseCase parseIncomingPacketUseCase,
    required ReceiveChirpUseCase receiveChirpUseCase,

    required FriendshipController friendshipCtrl,
  }) : _flockManager = flockManager,
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
    return null;

    // TODO: REVIEW THIS LATER. REMOVAL DUE TO NEW CTRL.
    // return allConversations
    //     .where((conv) => conv.id == conversationId)
    //     .firstOrNull;
  }

  List<ChirpMessage> getMessagesFor(String chatId) => _messages.forChat(chatId);

  void selectChat(String? chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  Future<void> startServices() async {
    log.i("🚀 [Serviços] Iniciando motores do bando...");

    try {
      await _tielsRepo.list();
      _tielsRepo.cached.updateAll(
        (_, tiel) => tiel.copyWith(status: TielStatus.away),
      );

      await _hydrateMessages();

      notifyListeners();

      log.i("✅ [Serviços] Bando pronto para voar.");
    } catch (e) {
      log.e("❌ [Serviços] Falha crítica na inicialização", error: e);
    }
  }

  Future<void> sendChirp(String targetId, String text) async {
    final tiel = _tiels[targetId];

    if (tiel == null ||
        tiel.publicKey == null ||
        tiel.status != TielStatus.connected) {
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

      // for (var chat in allConversations) {
      //   final history = await _messagesRepo.list(chat.id);

      //   if (history.isNotEmpty) {
      //     _messages.addAll(chat.id, history);
      //   }
      // }

      log.i("✅ [Hidratação] Concluída com sucesso");
    } catch (e) {
      log.e("💥 [Hidratação] Falha ao restaurar mensagens do banco local $e");
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

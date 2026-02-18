import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/usecases/chat/parse_incoming_packet_use_case.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_file_picker_use_case.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/utils/app_logger.dart';

// Especialistas
import 'presence_controller.dart';
import 'chat_controller.dart';
import 'friendship_controller.dart';

class ChirpController extends ChangeNotifier {
  // --- Sub-Controllers ---
  final PresenceController presence;
  final ChatController chat;
  final FriendshipController friendship;

  // --- Infra & UseCases ---
  final FlockManager _flockManager;
  final ParseIncomingPacketUseCase _parsePacketUseCase;
  final OpenFilePickerUseCase _openFilePickerUseCase;
  final OfferFileUseCase _offerFileUseCase;

  // --- Estado de UI ---
  String? _activeChatId;

  ChirpController({
    required this.presence,
    required this.chat,
    required this.friendship,
    required FlockManager flockManager,
    required ParseIncomingPacketUseCase parsePacketUseCase,
    required OpenFilePickerUseCase openFilePickerUseCase,
    required OfferFileUseCase offerFileUseCase,
  }) : _flockManager = flockManager,
       _parsePacketUseCase = parsePacketUseCase,
       _openFilePickerUseCase = openFilePickerUseCase,
       _offerFileUseCase = offerFileUseCase {
    _setupCentralListener();
  }

  // --- Getters Restaurados ---

  String? get activeChatId => _activeChatId;

  bool get hasNotifications => friendship.notificationCount > 0;

  /// Recupera todas as conversas unificando as fontes (Tiels, Flocks, etc.)
  List<Conversation> get allConversations => [
    ...presence.allTiels,
    // ...futuros Flocks aqui
  ];

  // --- Ciclo de Vida ---

  Future<void> startServices() async {
    _log("🚀 [Maestro] Iniciando motores do bando...");
    try {
      _flockManager.init();
      await presence.init(); // Presence cuida da própria hidratação e radar
      _log("✅ [Maestro] Bando pronto para voar.");
    } catch (e) {
      _log(
        "❌ [Maestro] Falha crítica na inicialização",
        isError: true,
        error: e,
      );
    }
  }

  // --- Coordenação de Conversas ---

  void selectChat(String? chatId) {
    _activeChatId = chatId;
    _log("📍 Chat ativo alterado para: $chatId");
    notifyListeners();
  }

  Conversation? getConversationFor(String conversationId) {
    return allConversations
        .where((conv) => conv.id == conversationId)
        .firstOrNull;
  }

  // --- Coordenação de Amizade (Ponte entre Presence e Friendship) ---

  Future<void> acceptFriendship(ChirpRequestPacket request) async {
    try {
      final tiel = presence.getTiel(request.fromId);
      if (tiel != null) {
        // O Friendship cuida da lógica da UseCase
        final authorizedTiel = await friendship.acceptFriendship(tiel, request);
        // O Presence atualiza o radar com o novo Tiel (agora com chave pública)
        presence.updateTiel(authorizedTiel);
        notifyListeners();
      }
    } catch (e) {
      _log("💥 Falha ao coordenar aceite de amizade", isError: true, error: e);
    }
  }

  // --- Coordenação de Mensagens ---

  Future<void> sendChirp(String targetId, String text) async {
    final tiel = presence.getTiel(targetId);

    if (tiel == null ||
        tiel.publicKey == null ||
        tiel.status != TielStatus.connected) {
      _log(
        "🚫 [Chat] Envio negado: ${tiel?.name ?? targetId} não está conectado.",
      );
      return;
    }

    await chat.sendChirp(tiel, text);
  }

  // --- Coordenação de Arquivos (Restaurado!) ---

  Future<void> pickAndOfferFile(String targetId) async {
    final tiel = presence.getTiel(targetId);

    if (tiel == null ||
        tiel.publicKey == null ||
        tiel.status != TielStatus.connected) {
      _log("🚫 [Arquivos] Oferta negada: Tiel não autorizado ou offline.");
      return;
    }

    try {
      _log("📂 [Arquivos] Abrindo seletor para ${tiel.name}...");
      final output = await _openFilePickerUseCase.execute();

      if (output.metadata != null) {
        _log("📦 [Arquivos] Enviando '${output.metadata!.name}'...");
        _offerFileUseCase.execute(tiel, output.metadata!);
        _log("✨ [Arquivos] Oferta enviada com sucesso.");
      }
    } catch (e) {
      _log("💥 [Arquivos] Erro no fluxo de arquivos", isError: true, error: e);
    }
  }

  // --- Roteamento Central de Pacotes ---

  void _setupCentralListener() {
    _flockManager.packets.listen((rawData) {
      try {
        final packet = _parsePacketUseCase.execute(rawData);
        _routePacket(packet);
      } catch (e) {
        _log("⚠️ Erro ao processar pacote recebido", isError: true, error: e);
      }
    });
  }

  void _routePacket(ChirpPacket packet) {
    switch (packet) {
      case ChirpRequestPacket():
        // Validação: Só aceitamos pedidos de quem está no radar
        if (presence.getTiel(packet.fromId) != null) {
          friendship.addIncomingRequest(packet);
        }
        break;

      case ChirpAcceptPacket():
        _handleAcceptPacket(packet);
        break;

      case ChirpMessagePacket():
        chat.handleIncomingPacket(packet);
        break;

      default:
        _log(
          "ℹ️ Pacote ${packet.runtimeType} recebido mas não tratado pelo Maestro.",
        );
    }
  }

  void _handleAcceptPacket(ChirpAcceptPacket packet) {
    final tiel = presence.getTiel(packet.fromId);
    if (tiel != null) {
      final authorizedTiel = tiel.copyWith(
        publicKey: packet.publicKey,
        status: TielStatus.connected,
      );
      presence.updateTiel(authorizedTiel);
      _log("🤝 Handshake completo com ${tiel.name}");
    }
  }

  // --- Logs & Limpeza ---

  void _log(String message, {bool isError = false, dynamic error}) {
    if (isError) {
      log.e("[Maestro] $message", error: error);
    } else {
      log.d("[Maestro] $message");
    }
  }

  @override
  void dispose() {
    presence.dispose();
    chat.clear();
    friendship.clear();
    super.dispose();
  }
}

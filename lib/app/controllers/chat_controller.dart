import 'package:flutter/material.dart';
import 'package:chirp/domain/entities/message.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/messages_nest.dart';
import 'package:chirp/domain/usecases/chat/receive_chirp_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/utils/app_logger.dart';

class ChatController extends ChangeNotifier {
  final SendChirpUseCase _sendChirpUseCase;
  final ReceiveChirpUseCase _receiveChirpUseCase;
  final MessageNestRepository _messagesRepo;

  final MessagesNest _messages = MessagesNest();

  final Set<String> _hydratedChats = {};

  ChatController({
    required SendChirpUseCase sendChirpUseCase,
    required ReceiveChirpUseCase receiveChirpUseCase,
    required MessageNestRepository messagesRepository,
  }) : _sendChirpUseCase = sendChirpUseCase,
       _receiveChirpUseCase = receiveChirpUseCase,
       _messagesRepo = messagesRepository;

  List<ChirpMessage> getMessagesFor(String chatId) {
    if (!_hydratedChats.contains(chatId)) {
      _hydrateChat(chatId);
    }
    return _messages.forChat(chatId);
  }

  // --- Ações ---

  Future<void> sendChirp(Tiel target, String text) async {
    _log("📤 Enviando chirp para ${target.name}...");

    try {
      final message = await _sendChirpUseCase.execute(target, text);
      _messages.add(target.id, message);
      notifyListeners();

      _log("✨ Mensagem entregue e salva para ${target.name}");
    } catch (e) {
      _log(
        "💥 Falha ao enviar chirp para ${target.name}",
        isError: true,
        error: e,
      );
      rethrow;
    }
  }

  Future<void> handleIncomingPacket(ChirpMessagePacket packet) async {
    final senderId = packet.fromId;
    _log("📥 Novo pacote recebido de $senderId. Descriptografando...");

    try {
      final message = await _receiveChirpUseCase.execute(packet);

      if (!_hydratedChats.contains(senderId)) {
        await _hydrateChat(senderId);
      }

      _messages.add(senderId, message);
      notifyListeners();

      _log("📩 Mensagem de $senderId processada e guardada no ninho.");
    } catch (e) {
      _log(
        "🔐 Erro de segurança ao ler mensagem de $senderId",
        isError: true,
        error: e,
      );
    }
  }

  // --- Persistência (Hidratação) ---

  Future<void> _hydrateChat(String chatId) async {
    if (_hydratedChats.contains(chatId)) return;

    _log("📦 Hidratando histórico do chat: $chatId");
    try {
      final history = await _messagesRepo.list(chatId);
      if (history.isNotEmpty) {
        _messages.addAll(chatId, history);
        _hydratedChats.add(chatId);
        notifyListeners();
      } else {
        _hydratedChats.add(chatId);
      }
    } catch (e) {
      _log(
        "💥 Erro ao restaurar mensagens do chat $chatId",
        isError: true,
        error: e,
      );
    }
  }

  void clear() {
    _messages.clear();
    _hydratedChats.clear();
    _log("🧹 Ninho de mensagens limpo.");
  }

  // --- Helpers ---

  void _log(String message, {bool isError = false, dynamic error}) {
    if (isError) {
      log.e("[ChatController] $message", error: error);
    } else {
      log.d("[ChatController] $message");
    }
  }
}

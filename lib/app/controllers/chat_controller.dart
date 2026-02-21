import 'package:chirp/domain/entities/conversation.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/usecases/chat/open_or_create_conversation_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
import 'package:chirp/infrastructure/repositories/conversation_nest_repository.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

class ChatController extends ChangeNotifier {
  final ConversationNestRepository _conversationRepo;

  final SendChirpUseCase _sendChirpUseCase;
  final OpenOrCreateConversationUseCase _openOrCreateConversationUseCase;

  String? _activeConvesationId;

  ChatController({
    required ConversationNestRepository conversationRepo,
    required OpenOrCreateConversationUseCase openOrCreateConversationUseCase,
    required SendChirpUseCase sendChirpUseCase,
  }) : _conversationRepo = conversationRepo,
       _sendChirpUseCase = sendChirpUseCase,
       _openOrCreateConversationUseCase = openOrCreateConversationUseCase;

  List<Conversation> get conversations => [..._conversationRepo.cached.values];

  String? get activeConversationId => _activeConvesationId;

  set activeConversationId(String? value) {
    _activeConvesationId = value;
    notifyListeners();
  }

  Future<void> openOrCreateConversation(Tiel tiel) async {
    try {
      log.d("[Chat] Creating conversation with ${tiel.name}");

      final conversation = await _openOrCreateConversationUseCase.execute(tiel);
      activeConversationId = conversation.id;

      notifyListeners();

      log.i("✨ [Chat] Conversation created with ${tiel.name}");
    } catch (e) {
      log.e("💥 [Chat] Erro ao criar conversa com ${tiel.name}", error: e);
    }
  }

  Future<void> sendChirp({
    required String conversationId,
    required String text,
    required String targetId,
  }) async {
    try {
      log.d("📤 [Chat] Criptografando e enviando mensagem para $targetId...");

      await _sendChirpUseCase.execute(
        conversationId: conversationId,
        targetId: targetId,
        text: text,
      );

      notifyListeners();

      log.i("✨ [Chat] Mensagem entregue ao bando para $targetId");
    } catch (e) {
      log.e("💥 [Chat] Erro no envio seguro para $targetId", error: e);
    }
  }
}

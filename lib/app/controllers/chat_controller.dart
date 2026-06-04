import 'package:chirp/domain/entities/chirp_message.dart';
import 'package:chirp/domain/entities/conversation.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_file_picker_use_case.dart';
import 'package:chirp/domain/usecases/chat/open_or_create_conversation_use_case.dart';
import 'package:chirp/domain/usecases/chat/receive_chirp_use_case.dart';
import 'package:chirp/domain/usecases/chat/send_chirp_use_case.dart';
import 'package:chirp/infrastructure/repositories/conversation_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/foundation.dart';

class ChatController extends ChangeNotifier {
  final ConversationNestRepository _conversationRepo;
  final MessageNestRepository _msgRepo;

  final SendChirpUseCase _sendChirpUseCase;
  final ReceiveChirpUseCase _receiveChirpUseCase;
  final OpenOrCreateConversationUseCase _openOrCreateConversationUseCase;
  final OpenFilePickerUseCase _openFilePickerUseCase;
  final OfferFileUseCase _offerFileUseCase;

  String? _currentConversationId;

  ChatController({
    required ConversationNestRepository conversationRepo,
    required MessageNestRepository msgRepo,
    required SendChirpUseCase sendChirpUseCase,
    required ReceiveChirpUseCase receiveChirpUseCase,
    required OpenFilePickerUseCase openFilePickerUseCase,
    required OfferFileUseCase offerFileUseCase,
    required OpenOrCreateConversationUseCase openOrCreateConversationUseCase,
  }) : _conversationRepo = conversationRepo,
       _msgRepo = msgRepo,
       _sendChirpUseCase = sendChirpUseCase,
       _receiveChirpUseCase = receiveChirpUseCase,
       _openFilePickerUseCase = openFilePickerUseCase,
       _offerFileUseCase = offerFileUseCase,
       _openOrCreateConversationUseCase = openOrCreateConversationUseCase;

  List<Conversation> get conversations => [..._conversationRepo.cached.values];

  Conversation? get conversation => _conversationRepo.cached.values
      .where((conv) => conv.id == _currentConversationId)
      .firstOrNull;

  List<ChirpMessage> get messages =>
      _msgRepo.cached.values
          .where((msg) => msg.conversationId == _currentConversationId)
          .toList()
        ..sort((a, b) => a.dateCreated.compareTo(b.dateCreated));

  set selectedConversationId(String? value) {
    _currentConversationId = value;
    notifyListeners();
  }

  Future<void> openOrCreateConversation(Tiel tiel) async {
    try {
      log.d("[Chat] Creating conversation with ${tiel.name}");

      final conversation = await _openOrCreateConversationUseCase.execute(tiel);
      selectedConversationId = conversation.id;

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

  Future<void> receiveChirp(ChirpMessagePacket packet) async {
    final senderId = packet.fromId;

    try {
      log.d(
        "📥 [Chat] Novo pacote recebido de $senderId. Descriptografando...",
      );

      await _receiveChirpUseCase.execute(packet);
      notifyListeners();
    } catch (e) {
      log.e(
        "🔐 [Chat] Erro de segurança: Não foi possível ler mensagem de $senderId",
        error: e,
      );
    }
  }

  Future<void> pickAndOfferFile(String targetId) async {
    try {
      log.d("📂 [Arquivos] Abrindo seletor para $targetId...");
      final output = await _openFilePickerUseCase.execute(targetId);

      if (output.metadata != null) {
        final fileName = output.metadata!.name;
        final fileSize = output.metadata!.size;

        _offerFileUseCase.execute(targetId, output.metadata!);

        log.d(
          "✨ [Arquivos] Arquivo '$fileName' | $fileSize enviado com sucesso para $targetId.",
        );
      } else {
        log.d("📝 [Arquivos] Seleção de arquivo cancelada pelo usuário.");
      }
    } catch (e) {
      log.e(
        "💥 [Arquivos] Falha no fluxo de oferta de arquivo para $targetId",
        error: e,
      );
    }
  }
}

import 'package:flutter/foundation.dart';

class ChatController extends ChangeNotifier {
  // final SendChirpUseCase _sendChirpUseCase;

  // final TielNestRepository _tielRepo;
  // final MessageNestRepository _messageRepo;

  // String? _activeConvesationId;

  // ChatController({
  //   required SendChirpUseCase sendChirpUseCase,
  //   required TielNestRepository tielRepo,
  //   required MessageNestRepository messageRepo,
  // }) : _sendChirpUseCase = sendChirpUseCase,
  //      _tielRepo = tielRepo,
  //      _messageRepo = messageRepo;

  // List<Conversation> get conversations => [..._tielRepo.cached.values];

  // String? get activeConversationId => _activeConvesationId;

  // set activeConversationId(String? value) {
  //   _activeConvesationId = value;
  //   notifyListeners();
  // }

  // Future<void> start() async {
  //   await _messageRepo.list();
  // }

  // Conversation? getConversationById(String conversationId) => conversations
  //     .where((conversation) => conversation.id == conversationId)
  //     .firstOrNull;

  // Future<List<ChirpMessage>> listMessagesFor(String conversationId) {
  //   return _messageRepo.list(
  //     where: (msg) => msg.conversationId == conversationId,
  //   );
  // }

  // Future<void> sendChirpMessage(String targetId, String text) async {
  //   final tiel = _tielRepo.cached[targetId];

  //   if (tiel == null ||
  //       tiel.publicKey == null ||
  //       tiel.status != TielStatus.connected) {
  //     log.w(
  //       "🚫 [Chat] Tentativa de envio negada: ${tiel?.name ?? targetId} não está conectado.",
  //     );

  //     return;
  //   }

  //   try {
  //     log.d(
  //       "📤 [Chat] Criptografando e enviando mensagem para ${tiel.name}...",
  //     );

  //     final message = await _sendChirpUseCase.execute(tiel, text);

  //     await _messageRepo.save(targetId, message);
  //     notifyListeners();

  //     log.i("✨ [Chat] Mensagem entregue ao bando para ${tiel.name}");
  //   } catch (e) {
  //     log.e("💥 [Chat] Erro no envio seguro para ${tiel.name}", error: e);
  //   }
  // }
}

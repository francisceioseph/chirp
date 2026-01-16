import 'package:chirp/models/message.dart';
import 'package:chirp/repositories/secure_nest_repository.dart';

abstract class ISecureNest {
  Future<void> setup();
  Future<void> archiveChirp(ChirpMessage message);
  Future<List<ChirpMessage>> getConversationHistory(String conversationId);
  Future<void> wipeAllData();
}

class SecureNestService implements ISecureNest {
  final SecureNestPort _port;

  SecureNestService(this._port);

  @override
  Future<void> setup() async {
    await _port.init();
  }

  @override
  Future<void> archiveChirp(ChirpMessage message) async {
    await _port.saveMessage(message);
  }

  @override
  Future<List<ChirpMessage>> getConversationHistory(
    String conversationId,
  ) async {
    final history = await _port.getMessages(conversationId);
    history.sort((a, b) => a.dateCreated.compareTo(b.dateCreated));

    return history;
  }

  @override
  Future<void> wipeAllData() async {
    await _port.deleteAll();
  }
}

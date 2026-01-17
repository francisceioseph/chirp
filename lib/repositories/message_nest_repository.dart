import 'package:chirp/domain/entities/message.dart';
import 'package:chirp/services/secure_nest.dart';

class MessageNestRepository {
  final ISecureNest _nest;
  final String _boxName = "messages_vault";

  MessageNestRepository(this._nest);

  Future<void> save(ChirpMessage message) async {
    await _nest.save(_boxName, message.id, message.toJson());
  }

  Future<List<ChirpMessage>> list(String conversationId) async {
    final messages = await _nest.getAll(_boxName);

    return messages
        .map((json) => ChirpMessage.fromJson(json))
        .where((message) => message.senderId == conversationId)
        .toList()
      ..sort((a, b) => a.dateCreated.compareTo(b.dateCreated));
  }

  Future<void> deleteAll() async {
    await _nest.deleteAll(_boxName);
  }
}

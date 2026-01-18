import 'package:chirp/domain/entities/message.dart';

class MessagesNest {
  final Map<String, List<ChirpMessage>> _nest = {};

  List<ChirpMessage> forChat(String chatId) {
    return List.unmodifiable(_nest[chatId] ?? []);
  }

  void add(String chatId, ChirpMessage message) {
    final list = _nest.putIfAbsent(chatId, () => []);

    final alreadyExists = list.any((m) => m.id == message.id);

    if (!alreadyExists) {
      list.add(message);
      list.sort((a, b) => a.dateCreated.compareTo(b.dateCreated));
    }
  }

  void addAll(String chatId, List<ChirpMessage> messages) {
    for (final m in messages) {
      add(chatId, m);
    }
  }

  void clear() => _nest.clear();
}

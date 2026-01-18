import 'package:chirp/domain/entities/tiel.dart';

class ConversationNest<T extends Conversation> {
  final Map<String, T> _nest = {};

  List<T> get all => List.unmodifiable(_nest.values);

  T? operator [](String id) => _nest[id];

  void put(T item) => _nest[item.id] = item;

  void update(String id, T Function(T existing) action) {
    final existing = _nest[id];
    if (existing != null) {
      _nest[id] = action(existing);
    }
  }

  void updateAll(T Function(String key, T value) update) {
    _nest.updateAll(update);
  }

  void upsert(
    String id, {
    required T Function() create,
    required T Function(T existing) update,
  }) {
    final existing = _nest[id];
    _nest[id] = (existing == null) ? create() : update(existing);
  }

  bool contains(String id) => _nest.containsKey(id);
}

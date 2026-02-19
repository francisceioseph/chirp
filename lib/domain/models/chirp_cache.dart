class ChirpCache<T> {
  final Map<String, T> _nest = {};

  List<T> get all => List.unmodifiable(_nest.values);

  T? operator [](String id) => _nest[id];

  void add(String key, T item) => _nest[key] = item;

  void update(String key, T Function(T existing) update) {
    final existing = _nest[key];
    if (existing != null) {
      _nest[key] = update(existing);
    }
  }

  void updateAll(T Function(String key, T value) update) {
    _nest.updateAll(update);
  }

  void upsert(
    String key, {
    required T Function() create,
    required T Function(T existing) update,
  }) {
    final existing = _nest[key];
    _nest[key] = (existing == null) ? create() : update(existing);
  }

  void clear() {
    _nest.clear();
  }

  bool contains(String key) => _nest.containsKey(key);
}

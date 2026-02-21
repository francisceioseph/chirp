import 'package:chirp/domain/entities/nest_entity.dart';
import 'package:chirp/infrastructure/services/secure_nest.dart';
import 'package:flutter/foundation.dart';

abstract class NestRepository<T extends NestEntity> extends ChangeNotifier {
  @protected
  final ISecureNest nest;

  @protected
  final String boxName;

  @protected
  final Map<String, T> cache = {};

  @protected
  final T Function(Map<String, dynamic> json) fromJson;

  Map<String, T> get cached => cache;

  NestRepository({
    required this.nest,
    required this.boxName,
    required this.fromJson,
  });

  Future<void> save(String key, T data) async {
    cache[key] = data;
    await nest.save(boxName, key, data.toJson());
    notifyListeners();
  }

  Future<void> init() async {
    final jsons = await nest.getAll(boxName);
    final entities = jsons.map((json) => fromJson(json));

    for (var entity in entities) {
      cache[entity.id] = entity;
    }
  }

  Future<T?> get(String key) async {
    if (cache.containsKey(key)) return cache[key];

    final data = await nest.get(boxName, key);
    if (data == null) return null;

    final entity = fromJson(Map<String, dynamic>.from(data));
    cache[key] = entity;

    return entity;
  }

  Future<List<T>> list({bool Function(T data)? where}) async {
    final items = cache.values.toList();

    if (where != null) {
      return items.where(where).toList();
    }

    return items;
  }

  Future<void> updateAll(T Function(String key, T data) onUpdate) async {
    for (var key in cache.keys) {
      final updated = onUpdate(key, cache[key]!);
      cache[key] = updated;
      await nest.save(boxName, key, updated.toJson());
    }

    notifyListeners();
  }
}

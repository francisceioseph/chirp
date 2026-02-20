import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/infrastructure/repositories/nest_repository.dart';

class TielNestRepository extends NestRepository<Tiel> {
  TielNestRepository({required super.nest}) : super(boxName: 'tiels_vault');

  @override
  Future<Tiel?> get(String key) async {
    if (cache.containsKey(key)) {
      return cache[key]!;
    }

    final json = await nest.get(boxName, key);

    if (json != null) {
      final tiel = Tiel.fromJson(json);
      cache[key] = tiel;

      return tiel;
    }

    return null;
  }

  @override
  Future<List<Tiel>> list() async {
    final allJson = await nest.getAll(boxName);
    final tiels = allJson.map((json) => Tiel.fromJson(json)).toList();

    tiels.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));

    cache.clear();
    for (var tiel in tiels) {
      cache[tiel.id] = tiel;
    }
    return tiels;
  }

  @override
  Future<void> save(String key, Tiel data) async {
    cache[key] = data;
    await nest.save(boxName, key, data.toJson());
  }
}

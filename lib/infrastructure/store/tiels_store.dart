import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_cache.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';

class TielsStore {
  final TielNestRepository _repository;
  final _cache = ChirpCache<Tiel>();

  TielsStore(this._repository);

  List<Tiel> get tiels => _cache.all;

  Future<void> save(Tiel tiel) async {
    await _repository.save(tiel);
    _cache.add(tiel.id, tiel);
  }

  Future<void> loadFromDisk() async {
    final tiels = await _repository.list();

    _cache.clear();

    for (var tiel in tiels) {
      _cache.add(tiel.id, tiel);
    }
  }
}

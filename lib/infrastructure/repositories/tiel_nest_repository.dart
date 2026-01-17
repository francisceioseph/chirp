import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/infrastructure/services/secure_nest.dart';

class TielNestRepository {
  final ISecureNest _nest;
  final String _boxName = "tiels_vault";

  TielNestRepository(this._nest);

  Future<void> save(Tiel tiel) async {
    await _nest.save(_boxName, tiel.id, tiel.toJson());
  }

  Future<List<Tiel>> list() async {
    final tiels = await _nest.getAll(_boxName);

    return tiels.map((json) => Tiel.fromJson(json)).toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
  }

  Future<void> deleteAll() async {
    await _nest.deleteAll(_boxName);
  }
}

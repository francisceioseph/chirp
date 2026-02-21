import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/infrastructure/repositories/nest_repository.dart';

class TielNestRepository extends NestRepository<Tiel> {
  TielNestRepository({required super.nest})
    : super(boxName: 'tiels_vault', fromJson: Tiel.fromJson);

  @override
  Future<void> init() async {
    await super.init();

    cache.updateAll((_, tiel) => tiel.copyWith(status: TielStatus.away));
  }
}

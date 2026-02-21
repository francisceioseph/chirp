import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';

class UpdateTielsStatusUseCase {
  final TielNestRepository _tielsRepository;

  UpdateTielsStatusUseCase({required TielNestRepository tielsRepository})
    : _tielsRepository = tielsRepository;

  Future<void> execute() async {
    final now = DateTime.now();

    await _tielsRepository.updateAll((key, tiel) {
      if (tiel.status == TielStatus.away) return tiel;

      if (now.difference(tiel.lastSeen).inSeconds > 120) {
        return tiel.copyWith(status: TielStatus.away);
      }

      return tiel;
    });
  }
}

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/utils/app_logger.dart';

class TielFoundUseCase {
  final TielNestRepository _tielsRepository;
  final Identity _identity;

  TielFoundUseCase({
    required TielNestRepository tielsRepository,
    required Identity identity,
  }) : _tielsRepository = tielsRepository,
       _identity = identity;

  Future<void> execute(String id, String name, String address) async {
    if (id == _identity.id) {
      return;
    }

    log.d("📡 [Radar] Ping de presença: $name ($id)");

    Tiel tiel;

    if (_tielsRepository.cached.containsKey(id)) {
      final existing = _tielsRepository.cached[id]!;
      final newStatus = existing.publicKey != null
          ? TielStatus.connected
          : TielStatus.discovered;

      tiel = existing.copyWith(
        name: name,
        address: address,
        lastSeen: DateTime.now(),
        status: newStatus,
      );
    } else {
      tiel = Tiel(
        id: id,
        name: name,
        address: address,
        lastSeen: DateTime.now(),
        status: TielStatus.discovered,
      );
    }

    await _tielsRepository.save(id, tiel);
  }
}

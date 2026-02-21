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

    final existing = _tielsRepository.cached[id];
    final status = _resolveTielStatus(existing);

    final tiel = existing == null
        ? Tiel(
            id: id,
            name: name,
            address: address,
            lastSeen: DateTime.now(),
            status: status,
          )
        : existing.copyWith(
            name: name,
            address: address,
            lastSeen: DateTime.now(),
            status: status,
          );

    await _tielsRepository.save(id, tiel);
  }

  TielStatus _resolveTielStatus(Tiel? existing) {
    if (existing == null) {
      return TielStatus.discovered;
    }

    if (existing.status == TielStatus.pending) {
      return TielStatus.pending;
    }

    if (existing.status == TielStatus.connected) {
      return TielStatus.connected;
    }

    return (existing.publicKey != null)
        ? TielStatus.connected
        : TielStatus.discovered;
  }
}

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/data/tiels_store.dart';

class RequestFriendshipUseCase {
  final Identity _me;
  final FlockManager _flockManager;
  final TielsStore _store;

  RequestFriendshipUseCase({
    required FlockManager flockManager,
    required TielsStore store,
    required Identity me,
  }) : _flockManager = flockManager,
       _store = store,
       _me = me;

  Future<Tiel> execute(Tiel target) async {
    final packet = ChirpRequestPacket(
      fromId: _me.id,
      fromName: _me.name,
      publicKey: _me.publicKey,
    );

    _flockManager.sendPacket(target.id, packet);

    final updatedTiel = target.copyWith(status: TielStatus.pending);
    await _store.save(updatedTiel);

    return updatedTiel;
  }
}

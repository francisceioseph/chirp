import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';

import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/store/tiels_store.dart';

class AcceptFriendshipUseCase {
  final FlockManager _flockManager;
  final TielsStore _store;
  final Identity _me;

  AcceptFriendshipUseCase({
    required FlockManager flockManager,
    required TielsStore store,
    required Identity me,
  }) : _flockManager = flockManager,
       _store = store,
       _me = me;

  Future<Tiel> execute(Tiel target, ChirpRequestPacket request) async {
    final packet = ChirpAcceptPacket(
      fromId: _me.id,
      fromName: _me.name,
      publicKey: _me.publicKey,
    );

    _flockManager.sendPacket(target.id, packet);

    final tiel = target.copyWith(
      publicKey: request.publicKey,
      status: .connected,
    );

    await _store.save(tiel);

    return tiel;
  }
}

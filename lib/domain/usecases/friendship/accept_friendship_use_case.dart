import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';

class AcceptFriendshipUseCase {
  final FlockManager _flockManager;
  final TielNestRepository _tielsRepo;
  final Identity _me;

  AcceptFriendshipUseCase({
    required FlockManager flockManager,
    required TielNestRepository tielsRepo,
    required Identity me,
  }) : _flockManager = flockManager,
       _tielsRepo = tielsRepo,
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

    await _tielsRepo.save(tiel);

    return tiel;
  }
}

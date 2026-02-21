import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';

class RequestFriendshipUseCase {
  final Identity _me;
  final FlockManager _flockManager;
  final TielNestRepository _tielsRepo;

  RequestFriendshipUseCase({
    required FlockManager flockManager,
    required TielNestRepository tielsRepo,
    required Identity me,
  }) : _flockManager = flockManager,
       _tielsRepo = tielsRepo,
       _me = me;

  Future<Tiel> execute(Tiel target) async {
    final packet = ChirpRequestPacket(
      fromId: _me.id,
      fromName: _me.name,
      publicKey: _me.publicKey,
    );

    _flockManager.sendPacket(target.id, packet);

    final newTiel = target.copyWith(status: TielStatus.pending);
    await _tielsRepo.save(newTiel.id, newTiel);

    return newTiel;
  }
}

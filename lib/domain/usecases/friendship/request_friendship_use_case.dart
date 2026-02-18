import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';

class RequestFriendshipUseCase {
  final IdentityService _identityService;
  final FlockManager _flockManager;
  final TielNestRepository _tielsRepo;

  RequestFriendshipUseCase({
    required FlockManager flockManager,
    required TielNestRepository tielsRepo,
    required IdentityService identityService,
  }) : _flockManager = flockManager,
       _tielsRepo = tielsRepo,
       _identityService = identityService;

  Future<Tiel> execute(Tiel target) async {
    final identity = await _identityService.loadOrCreateIdentity();

    final packet = ChirpRequestPacket(
      fromId: identity.id,
      fromName: identity.name,
      publicKey: identity.publicKey,
    );

    _flockManager.sendPacket(target.id, packet);

    final updatedTiel = target.copyWith(status: TielStatus.pending);

    await _tielsRepo.save(updatedTiel);

    return updatedTiel;
  }
}

import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';

class AcceptFriendshipUseCase {
  final FlockManager _flockManager;
  final TielNestRepository _tielsRepo;
  final IdentityService _identityService;

  AcceptFriendshipUseCase({
    required FlockManager flockManager,
    required TielNestRepository tielsRepo,
    required IdentityService identityService,
  }) : _flockManager = flockManager,
       _tielsRepo = tielsRepo,
       _identityService = identityService;

  Future<Tiel> execute(Tiel target, ChirpRequestPacket request) async {
    final identity = await _identityService.loadOrCreateIdentity();

    final packet = ChirpAcceptPacket(
      fromId: identity.id,
      fromName: identity.name,
      publicKey: identity.publicKey,
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

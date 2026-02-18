import 'dart:convert';

import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_file_metadata.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';

class OfferFileUseCase {
  final FlockManager _flockManager;
  final IdentityService _identityService;

  OfferFileUseCase({
    required FlockManager flockManager,
    required IdentityService identityService,
  }) : _flockManager = flockManager,
       _identityService = identityService;

  void execute(Tiel target, ChirpFileMetadata metadata) async {
    final jsonData = jsonEncode(metadata.toJson());
    final envelope = SecureChirp.encrypt(target.publicKey!, jsonData);

    final identity = await _identityService.loadOrCreateIdentity();

    final packet = ChirpFileOfferPacket(
      fromId: identity.id,
      fromName: identity.name,
      envelope: envelope,
    );

    _flockManager.sendPacket(target.id, packet);
  }
}

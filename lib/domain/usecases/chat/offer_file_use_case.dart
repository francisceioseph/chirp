import 'dart:convert';

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_file_metadata.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';

class OfferFileUseCase {
  final FlockManager _flockManager;
  final TielNestRepository _tielRepo;
  final Identity _me;

  OfferFileUseCase({
    required FlockManager flockManager,
    required TielNestRepository tielRepo,
    required Identity me,
  }) : _flockManager = flockManager,
       _tielRepo = tielRepo,
       _me = me;

  void execute(String targetId, ChirpFileMetadata metadata) {
    final tiel = _tielRepo.cached[targetId];

    if (_canOfferFile(tiel) == false) {
      return;
    }

    final jsonData = jsonEncode(metadata.toJson());
    final envelope = SecureChirp.encrypt(tiel!.publicKey!, jsonData);

    final packet = ChirpFileOfferPacket(
      fromId: _me.id,
      fromName: _me.name,
      envelope: envelope,
    );

    _flockManager.sendPacket(tiel.id, packet);
  }

  bool _canOfferFile(Tiel? tiel) =>
      tiel != null &&
      tiel.publicKey != null &&
      tiel.status == TielStatus.connected;
}

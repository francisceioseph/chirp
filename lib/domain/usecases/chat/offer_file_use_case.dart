import 'dart:convert';

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_file_metadata.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';

class OfferFileUseCase {
  final FlockManager _flockManager;
  final Identity _me;

  OfferFileUseCase({required FlockManager flockManager, required Identity me})
    : _flockManager = flockManager,
      _me = me;

  void execute(Tiel target, ChirpFileMetadata metadata) {
    final jsonData = jsonEncode(metadata.toJson());
    final envelope = SecureChirp.encrypt(target.publicKey!, jsonData);

    final packet = ChirpFileOfferPacket(
      fromId: _me.id,
      fromName: _me.name,
      envelope: envelope,
    );

    _flockManager.sendPacket(target.id, packet);
  }
}

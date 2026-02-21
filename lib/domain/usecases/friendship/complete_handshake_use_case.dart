import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';

class CompleteHandshakeUseCase {
  final TielNestRepository _tielsRepo;

  CompleteHandshakeUseCase({required TielNestRepository tielsRepo})
    : _tielsRepo = tielsRepo;

  Future<void> execute(ChirpAcceptPacket packet) async {
    final tiel = _tielsRepo.cached[packet.fromId];

    final updatedTiel = tiel == null
        ? Tiel(
            id: packet.fromId,
            name: packet.fromName,
            address: "0.0.0.0",
            publicKey: packet.publicKey,
            status: TielStatus.connected,
            lastSeen: DateTime.now(),
          )
        : tiel.copyWith(
            publicKey: packet.publicKey,
            status: TielStatus.connected,
          );

    await _tielsRepo.save(updatedTiel.id, updatedTiel);
  }
}

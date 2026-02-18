import 'dart:convert';

import 'package:chirp/domain/entities/message.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';
import 'package:uuid/uuid.dart';

class SendChirpUseCase {
  final FlockManager _flockManager;
  final MessageNestRepository _messagesRepo;
  final IdentityService _identityService;

  final _uuid = Uuid();

  SendChirpUseCase({
    required FlockManager flockManager,
    required MessageNestRepository messagesRepo,
    required IdentityService identityService,
  }) : _flockManager = flockManager,
       _messagesRepo = messagesRepo,
       _identityService = identityService;

  Future<ChirpMessage> execute(Tiel target, String text) async {
    final identity = await _identityService.loadOrCreateIdentity();

    final message = ChirpMessage(
      id: _uuid.v4(),
      senderId: identity.id,
      author: identity.name,
      body: text,
      dateCreated: DateTime.now(),
      isFromMe: true,
    );

    final jsonMessage = jsonEncode(message.toJson());
    final envelope = SecureChirp.encrypt(target.publicKey!, jsonMessage);

    final packet = ChirpMessagePacket(
      fromId: identity.id,
      fromName: identity.name,
      envelope: envelope,
    );

    _flockManager.sendPacket(target.id, packet);

    await _messagesRepo.save(message);

    return message;
  }
}

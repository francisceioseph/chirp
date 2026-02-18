import 'dart:convert';

import 'package:chirp/domain/entities/message.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';

class ReceiveChirpUseCase {
  final IdentityService _identityService;
  final MessageNestRepository _messageRepo;

  ReceiveChirpUseCase({
    required IdentityService identityService,
    required MessageNestRepository messageRepo,
  }) : _identityService = identityService,
       _messageRepo = messageRepo;

  Future<ChirpMessage> execute(ChirpMessagePacket packet) async {
    final identity = await _identityService.loadOrCreateIdentity();

    final decryptedJson = SecureChirp.decrypt(
      identity.privateKey!,
      packet.envelope,
    );

    final Map<String, dynamic> msgMap = jsonDecode(decryptedJson);
    final message = ChirpMessage.fromJson(msgMap);

    await _messageRepo.save(message);

    return message;
  }
}

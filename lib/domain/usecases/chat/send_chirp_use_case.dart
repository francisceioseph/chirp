import 'dart:convert';

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/message.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';
import 'package:uuid/uuid.dart';

class SendChirpUseCase {
  final FlockManager _flockManager;
  final MessageNestRepository _messagesRepo;
  final Identity _me;

  final _uuid = Uuid();

  SendChirpUseCase({
    required FlockManager flockManager,
    required MessageNestRepository messagesRepo,
    required Identity me,
  }) : _flockManager = flockManager,
       _messagesRepo = messagesRepo,
       _me = me;

  Future<ChirpMessage> execute(Tiel target, String text) async {
    final message = ChirpMessage(
      id: _uuid.v4(),
      senderId: _me.id,
      author: _me.name,
      body: text,
      dateCreated: DateTime.now(),
      isFromMe: true,
    );

    final jsonMessage = jsonEncode(message.toJson());
    final envelope = SecureChirp.encrypt(target.publicKey!, jsonMessage);

    final packet = ChirpMessagePacket(
      fromId: _me.id,
      fromName: _me.name,
      envelope: envelope,
    );

    _flockManager.sendPacket(target.id, packet);

    await _messagesRepo.save(message);

    return message;
  }
}

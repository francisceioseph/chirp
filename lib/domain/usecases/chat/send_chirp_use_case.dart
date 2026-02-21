import 'dart:convert';

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/chirp_message.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

class SendChirpUseCase {
  final Identity _me;

  final FlockManager _flockManager;

  final TielNestRepository _tielRepo;
  final MessageNestRepository _msgRepo;

  final _uuid = Uuid();

  SendChirpUseCase({
    required FlockManager flockManager,
    required TielNestRepository tielRepo,
    required MessageNestRepository msgRepo,
    required Identity me,
  }) : _flockManager = flockManager,
       _tielRepo = tielRepo,
       _msgRepo = msgRepo,
       _me = me;

  Future<void> execute({
    required String conversationId,
    required String text,
    required String targetId,
  }) async {
    final target = await _tielRepo.get(targetId);

    if (target == null ||
        target.publicKey == null ||
        target.status != TielStatus.connected) {
      log.w(
        "🚫 [Chat] Tentativa de envio negada: ${target?.name ?? targetId} não está conectado.",
      );

      return;
    }

    final message = ChirpMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
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

    await _msgRepo.save(message.id, message);
  }
}

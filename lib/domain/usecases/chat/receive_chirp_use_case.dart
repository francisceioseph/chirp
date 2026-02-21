import 'dart:convert';

import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/entities/chirp_message.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/infrastructure/repositories/message_nest_repository.dart';
import 'package:chirp/infrastructure/services/secure_chirp.dart';

class ReceiveChirpUseCase {
  final Identity _me;
  final MessageNestRepository _messageRepo;

  ReceiveChirpUseCase({
    required Identity me,
    required MessageNestRepository messageRepo,
  }) : _me = me,
       _messageRepo = messageRepo;

  Future<ChirpMessage> execute(ChirpMessagePacket packet) async {
    final decryptedJson = SecureChirp.decrypt(_me.privateKey!, packet.envelope);

    final Map<String, dynamic> msgMap = jsonDecode(decryptedJson);
    final message = ChirpMessage.fromJson(msgMap);

    await _messageRepo.save(message.id, message);

    return message;
  }
}

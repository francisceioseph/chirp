import 'dart:convert';

import 'package:chirp/domain/models/chirp_packet.dart';

class ParseIncomingPacketUseCase {
  ChirpPacket execute(dynamic rawData) {
    final Map<String, dynamic> json = jsonDecode(rawData);
    return ChirpPacket.fromJson(json);
  }
}

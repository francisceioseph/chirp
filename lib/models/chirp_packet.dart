import 'package:chirp/models/chirp_envelope.dart';

enum ChirpPacketAction { identity, request, accept, message }

sealed class ChirpPacket {
  final String fromId;
  final String fromName;
  final ChirpPacketAction action;

  ChirpPacket({
    required this.fromId,
    required this.fromName,
    required this.action,
  });

  Map<String, dynamic> toJson();

  factory ChirpPacket.fromJson(Map<String, dynamic> json) {
    final action = json['action'];
    return switch (action) {
      'identity' => ChirpIdentityPacket.fromJson(json),
      'request' => ChirpRequestPacket.fromJson(json),
      'accept' => ChirpAcceptPacket.fromJson(json),
      'message' => ChirpMessagePacket.fromJson(json),
      _ => throw Exception("Ação desconhecida"),
    };
  }
}

class ChirpIdentityPacket extends ChirpPacket {
  ChirpIdentityPacket({required super.fromId, required super.fromName})
    : super(action: .identity);

  @override
  Map<String, dynamic> toJson() => {
    'action': action.name,
    'fromId': fromId,
    'fromName': fromName,
  };

  factory ChirpIdentityPacket.fromJson(Map<String, dynamic> json) =>
      ChirpIdentityPacket(fromId: json['fromId'], fromName: json['fromName']);
}

class ChirpRequestPacket extends ChirpPacket {
  final String publicKey;

  ChirpRequestPacket({
    required super.fromId,
    required super.fromName,
    required this.publicKey,
  }) : super(action: .request);

  @override
  Map<String, dynamic> toJson() => {
    'action': action.name,
    'fromId': fromId,
    'fromName': fromName,
    'publicKey': publicKey,
  };

  factory ChirpRequestPacket.fromJson(Map<String, dynamic> json) =>
      ChirpRequestPacket(
        fromId: json['fromId'],
        fromName: json['fromName'],
        publicKey: json['publicKey'],
      );
}

class ChirpAcceptPacket extends ChirpPacket {
  final String publicKey;

  ChirpAcceptPacket({
    required super.fromId,
    required super.fromName,
    required this.publicKey,
  }) : super(action: .accept);

  @override
  Map<String, dynamic> toJson() => {
    'action': action.name,
    'fromId': fromId,
    'fromName': fromName,
    'publicKey': publicKey,
  };

  factory ChirpAcceptPacket.fromJson(Map<String, dynamic> json) =>
      ChirpAcceptPacket(
        fromId: json['fromId'],
        fromName: json['fromName'],
        publicKey: json['publicKey'],
      );
}

class ChirpMessagePacket extends ChirpPacket {
  final ChirpEnvelope envelope;

  ChirpMessagePacket({
    required super.fromId,
    required super.fromName,
    required this.envelope,
  }) : super(action: .message);

  @override
  Map<String, dynamic> toJson() => {
    'action': action.name,
    'fromId': fromId,
    'fromName': fromName,
    'envelope': envelope.toJson(),
  };

  factory ChirpMessagePacket.fromJson(Map<String, dynamic> json) =>
      ChirpMessagePacket(
        fromId: json['fromId'],
        fromName: json['fromName'],
        envelope: ChirpEnvelope.fromJson(json['envelope']),
      );
}

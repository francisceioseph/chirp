import 'package:flutter/material.dart';

enum TielStatus { discovered, pending, connected, away, blocked, error }

enum ConversationType { individual, group }

abstract class Conversation {
  String get id;
  String get name;
  String get avatar;
  ConversationType get type;

  String get statusText;
  Color getStatusColor(ColorScheme colorScheme);
}

class Tiel implements Conversation {
  @override
  final String id;

  @override
  final String name;

  String? publicKey;

  @override
  String get avatar => "https://api.dicebear.com/7.x/adventurer/png?seed=$name";

  @override
  ConversationType get type => .individual;

  bool get isSecure => publicKey != null && status == .connected;

  final String address;
  final DateTime lastSeen;
  final TielStatus status;

  @override
  String get statusText => switch (status) {
    TielStatus.discovered => "Pousou por perto",
    TielStatus.pending => "Enviando pio...",
    TielStatus.connected => "Voando juntos",
    TielStatus.away => "Soneca...",
    TielStatus.blocked => "Fora do bando",
    TielStatus.error => "Asas tropeçaram!",
  };

  @override
  Color getStatusColor(ColorScheme colorScheme) => switch (status) {
    TielStatus.discovered => Colors.tealAccent,
    TielStatus.pending => Colors.orangeAccent,
    TielStatus.connected => colorScheme.primary,
    TielStatus.away => Colors.blueGrey.shade300,
    TielStatus.blocked => Colors.redAccent,
    TielStatus.error => colorScheme.error,
  };

  Tiel({
    required this.id,
    required this.address,
    required this.lastSeen,
    required this.name,
    this.publicKey,
    this.status = .discovered,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tiel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tiel(id: $id, ip: $address)';

  Tiel copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? lastSeen,
    TielStatus? status,
    String? publicKey,
  }) {
    return Tiel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      publicKey: publicKey ?? this.publicKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'publicKey': publicKey,
    'address': address,
    'lastSeen': lastSeen.toIso8601String(),
    'status': status.name,
  };

  factory Tiel.fromJson(Map<String, dynamic> json) => Tiel(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    lastSeen: DateTime.parse(json['lastSeen']),
    publicKey: json['publicKey'],
    status: TielStatus.values.byName(
      json['status'] ?? TielStatus.discovered.name,
    ),
  );
}

class Flock implements Conversation {
  @override
  final String id;

  @override
  final String name;

  @override
  String get avatar =>
      "https://api.dicebear.com/7.x/identicon/png?seed=$id&backgroundColor=ffdf00";

  @override
  ConversationType get type => .group;

  @override
  String get statusText => "${tielIds.length} tiels no bando";

  @override
  Color getStatusColor(ColorScheme colorScheme) => colorScheme.secondary;

  final List<String> tielIds;

  Flock({required this.id, required this.name, required this.tielIds});
}

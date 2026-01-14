enum TielStatus { online, connected, away, disconnected, error }

enum ConversationType { individual, group }

abstract class Conversation {
  String get id;
  String get name;
  String get avatar;
  ConversationType get type;
}

class Tiel implements Conversation {
  @override
  final String id;

  @override
  final String name;

  @override
  String get avatar => "https://api.dicebear.com/7.x/adventurer/png?seed=$name";

  @override
  ConversationType get type => .individual;

  final String address;
  final DateTime lastSeen;
  final TielStatus status;

  Tiel({
    required this.id,
    required this.address,
    required this.lastSeen,
    required this.name,
    this.status = .online,
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
  }) {
    return Tiel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
    );
  }
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

  final List<String> tielIds;

  Flock({required this.id, required this.name, required this.tielIds});
}

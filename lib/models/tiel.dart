enum TielStatus { searching, connected, disconnected, error }

class Tiel {
  final String id;
  final String name;
  final String address;
  final DateTime lastSeen;

  final String? avatar;
  final TielStatus status;

  Tiel({
    required this.id,
    required this.address,
    required this.lastSeen,
    required this.name,
    this.status = TielStatus.searching,
    this.avatar,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tiel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tiel(id: $id, ip: $address)';
}

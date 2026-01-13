class Tiel {
  final String id;
  final String address;
  final DateTime lastSeen;

  final String? name;
  final String? avatar;

  Tiel({
    required this.id,
    required this.address,
    required this.lastSeen,
    this.avatar,
    this.name,
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

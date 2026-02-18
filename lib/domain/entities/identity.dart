class Identity {
  final String id;
  final String name;
  final String? email;
  final String publicKey;
  final String? privateKey;

  Identity({
    required this.id,
    required this.name,
    required this.publicKey,
    this.email,
    this.privateKey,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'publicKey': publicKey,
    'privateKey': privateKey,
  };

  factory Identity.fromJson(Map<String, dynamic> json) => Identity(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    publicKey: json['publicKey'],
    privateKey: json['privateKey'],
  );
}

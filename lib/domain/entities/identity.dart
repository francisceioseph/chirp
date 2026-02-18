class Identity {
  final String id;
  final String name;
  final String nickname;
  final String? email;
  final String publicKey;
  final String? privateKey;

  Identity({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.nickname,
    this.email,
    this.privateKey,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nickname': nickname,
    'email': email,
    'publicKey': publicKey,
    'privateKey': privateKey,
  };

  Identity copyWith({
    String? id,
    String? name,
    String? nickname,
    String? email,
    String? publicKey,
    String? privateKey,
  }) {
    return Identity(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
    );
  }

  factory Identity.fromJson(Map<String, dynamic> json) => Identity(
    id: json['id'],
    name: json['name'],
    nickname: json['nickname'],
    email: json['email'],
    publicKey: json['publicKey'],
    privateKey: json['privateKey'],
  );
}

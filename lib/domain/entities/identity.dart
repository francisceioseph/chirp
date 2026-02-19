class Identity {
  final String id;
  final String name;
  final String publicKey;
  final String? privateKey;

  Identity({
    required this.id,
    required this.name,
    required this.publicKey,
    this.privateKey,
  });
}

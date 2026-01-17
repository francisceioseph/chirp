class ChirpFileMetadata {
  final String id;
  final String name;
  final int size;
  final String checksum;
  final String? mimeType;

  ChirpFileMetadata({
    required this.id,
    required this.name,
    required this.size,
    required this.checksum,
    this.mimeType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'checksum': checksum,
    'mimeType': mimeType,
  };

  factory ChirpFileMetadata.fromJson(Map<String, dynamic> json) =>
      ChirpFileMetadata(
        id: json['id'],
        checksum: json['checksum'],
        mimeType: json['mimeType'],
        name: json['name'],
        size: json['size'],
      );
}

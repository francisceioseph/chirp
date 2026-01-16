class ChirpMessage {
  final String id;
  final String senderId;
  final String author;
  final String body;
  final DateTime dateCreated;
  final bool isFromMe;

  ChirpMessage({
    required this.id,
    required this.senderId,
    required this.author,
    required this.body,
    required this.dateCreated,
    this.isFromMe = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'author': author,
    'body': body,
    'dateCreated': dateCreated.toIso8601String(),
  };

  ChirpMessage copyWith({
    String? id,
    String? senderId,
    String? author,
    String? body,
    DateTime? dateCreated,
    bool? isFromMe,
  }) => ChirpMessage(
    id: id ?? this.id,
    senderId: senderId ?? this.senderId,
    author: author ?? this.author,
    body: body ?? this.body,
    dateCreated: dateCreated ?? this.dateCreated,
    isFromMe: isFromMe ?? this.isFromMe,
  );

  factory ChirpMessage.fromJson(Map<String, dynamic> json) => ChirpMessage(
    id: json['id'],
    senderId: json['senderId'],
    author: json['author'],
    body: json['body'],
    dateCreated: DateTime.parse(json['dateCreated']),
    isFromMe: json['isFromMe'] ?? false,
  );
}

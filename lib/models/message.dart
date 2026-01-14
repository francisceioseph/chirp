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

  factory ChirpMessage.fromJson(Map<String, dynamic> json) => ChirpMessage(
    id: json['id'],
    senderId: json['senderId'],
    author: json['author'],
    body: json['body'],
    dateCreated: DateTime.parse(json['dateCreated']),
  );
}

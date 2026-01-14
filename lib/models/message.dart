class ChirpMessage {
  final String id;
  final String senderId;
  final String body;
  final DateTime dateCreated;
  final bool isFromMe;

  ChirpMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.dateCreated,
    this.isFromMe = false,
  });
}

enum ChirpAction { request, accept, decline, message }

class ChirpEnvelope {
  final String payload;
  final String key;
  final String iv;

  ChirpEnvelope({required this.payload, required this.key, required this.iv});

  Map<String, dynamic> toJson() => {'payload': payload, 'key': key, 'iv': iv};

  factory ChirpEnvelope.fromJson(Map<String, dynamic> json) =>
      ChirpEnvelope(payload: json['payload'], key: json['key'], iv: json['iv']);
}

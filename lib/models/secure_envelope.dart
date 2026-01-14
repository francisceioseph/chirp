class SecureEnvelope {
  final String payload;
  final String key;
  final String iv;

  SecureEnvelope({required this.payload, required this.key, required this.iv});

  Map<String, dynamic> toJson() => {'payload': payload, 'key': key, 'iv': iv};

  factory SecureEnvelope.fromJson(Map<String, dynamic> json) => SecureEnvelope(
    payload: json['payload'],
    key: json['key'],
    iv: json['iv'],
  );
}

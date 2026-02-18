class ChirpFileConnectionDetails {
  final String fileId;
  final int port;
  final String? token;

  ChirpFileConnectionDetails({
    required this.fileId,
    required this.port,
    this.token,
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'port': port,
    'token': token,
  };

  factory ChirpFileConnectionDetails.fromJson(Map<String, dynamic> json) =>
      ChirpFileConnectionDetails(
        fileId: json['fileId'],
        port: json['port'],
        token: json['token'],
      );
}

class ChirpFileMetadata {
  final String fileId;
  final String fileName;
  final int fileSize;
  final String checksum;

  ChirpFileMetadata({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'fileName': fileName,
    'fileSize': fileSize,
    'checksum': checksum,
  };
}

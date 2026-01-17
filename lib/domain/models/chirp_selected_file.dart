class ChirpSelectedFile {
  final String path;
  final String name;
  final int size;
  final String? extension;

  ChirpSelectedFile({
    required this.path,
    required this.name,
    required this.size,
    this.extension,
  });
}

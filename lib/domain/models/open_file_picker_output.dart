import 'package:chirp/domain/models/chirp_file_metadata.dart';
import 'package:chirp/domain/models/chirp_selected_file.dart';

class OpenFilePickerOutput {
  final ChirpSelectedFile? file;
  final ChirpFileMetadata? metadata;

  OpenFilePickerOutput({this.file, this.metadata});

  bool get isEmpty => file == null || metadata == null;

  bool get isNotEmpty => file != null && metadata != null;
}

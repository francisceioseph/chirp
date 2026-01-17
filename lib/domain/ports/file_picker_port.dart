import 'package:chirp/domain/models/chirp_selected_file.dart';

abstract class FilePickerPort {
  Future<ChirpSelectedFile?> pickFile();
}

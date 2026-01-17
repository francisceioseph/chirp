import 'package:chirp/domain/models/chirp_selected_file.dart';
import 'package:chirp/domain/ports/file_picker_port.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerAdapter implements FilePickerPort {
  @override
  Future<ChirpSelectedFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;

      if (file.path == null) {
        return null;
      }

      return ChirpSelectedFile(
        path: file.path!,
        name: file.name,
        size: file.size,
        extension: file.extension,
      );
    } catch (e) {
      log.e("Erro ao selecionar arquivo: $e");
      return null;
    }
  }
}

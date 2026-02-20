import 'package:chirp/domain/models/chirp_file_metadata.dart';
import 'package:chirp/domain/models/chirp_selected_file.dart';
import 'package:chirp/domain/models/open_file_picker_output.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OpenFilePickerOutput - Validação de Estado', () {
    final empty = OpenFilePickerOutput();
    expect(empty.isEmpty, true);
    expect(empty.isNotEmpty, false);

    final full = OpenFilePickerOutput(
      file: ChirpSelectedFile(path: '/', name: 'n', size: 10),
      metadata: ChirpFileMetadata(id: '1', name: 'n', size: 10, checksum: 'x'),
    );

    expect(full.isNotEmpty, true);
  });
}

import 'dart:io';

import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/models/chirp_file_metadata.dart';
import 'package:chirp/domain/models/open_file_picker_output.dart';
import 'package:chirp/domain/ports/file_picker_port.dart';
import 'package:chirp/infrastructure/repositories/tiel_nest_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class OpenFilePickerUseCase {
  final _uuid = Uuid();

  final FilePickerPort _filePicker;
  final TielNestRepository _tielRepo;

  OpenFilePickerUseCase({
    required FilePickerPort filePicker,
    required TielNestRepository tielRepo,
  }) : _filePicker = filePicker,
       _tielRepo = tielRepo;

  Future<OpenFilePickerOutput> execute(String targetId) async {
    final tiel = _tielRepo.cached[targetId];

    if (_canOfferFile(tiel) == false) {
      return OpenFilePickerOutput();
    }

    final file = await _filePicker.pickFile();

    if (file == null) {
      return OpenFilePickerOutput();
    }

    final checksum = await _calculateChecksum(file.path);

    final metadata = ChirpFileMetadata(
      id: _uuid.v4(),
      name: file.name,
      size: file.size,
      checksum: checksum,
      mimeType: file.extension,
    );

    return OpenFilePickerOutput(file: file, metadata: metadata);
  }

  Future<String> _calculateChecksum(String path) async {
    final file = File(path);
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;

    return hash.toString();
  }

  bool _canOfferFile(Tiel? tiel) =>
      tiel != null &&
      tiel.publicKey != null &&
      tiel.status == TielStatus.connected;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/models/chirp_file_metadata.dart'; // Ajuste conforme seu path

void main() {
  group('ChirpFileMetadata - Model Test', () {
    test('Deve instanciar corretamente com metadados completos', () {
      final metadata = ChirpFileMetadata(
        id: 'uuid-123',
        name: 'foto_do_bando.png',
        size: 1024 * 500, // 500 KB
        checksum: 'sha256-abc-123',
        mimeType: 'image/png',
      );

      expect(metadata.id, 'uuid-123');
      expect(metadata.name, 'foto_do_bando.png');
      expect(metadata.size, 512000);
      expect(metadata.checksum, 'sha256-abc-123');
      expect(metadata.mimeType, 'image/png');
    });

    test('Deve converter para JSON e manter a integridade dos tipos', () {
      final metadata = ChirpFileMetadata(
        id: 'file-456',
        name: 'documento.pdf',
        size: 2048,
        checksum: 'hash-xyz',
        mimeType: 'application/pdf',
      );

      final json = metadata.toJson();

      expect(json['size'], isA<int>());
      expect(json['id'], 'file-456');
      expect(json['mimeType'], 'application/pdf');
    });

    test('Deve lidar corretamente com mimeType nulo (Campo Opcional)', () {
      final json = {
        'id': 'file-789',
        'name': 'arquivo_sem_extensao',
        'size': 100,
        'checksum': 'hash-000',
        'mimeType': null,
      };

      final metadata = ChirpFileMetadata.fromJson(json);

      expect(metadata.mimeType, isNull);
      expect(metadata.name, 'arquivo_sem_extensao');
    });

    test('Roundtrip: Objeto -> JSON -> Objeto', () {
      final original = ChirpFileMetadata(
        id: 'unique-id',
        name: 'video.mp4',
        size: 9999999,
        checksum: 'cksum-val',
        mimeType: 'video/mp4',
      );

      final result = ChirpFileMetadata.fromJson(original.toJson());

      expect(result.id, original.id);
      expect(result.name, original.name);
      expect(result.size, original.size);
      expect(result.checksum, original.checksum);
      expect(result.mimeType, original.mimeType);
    });
  });
}

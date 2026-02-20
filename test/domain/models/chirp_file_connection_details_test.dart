import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/models/chirp_file_connection_details.dart';

void main() {
  group('ChirpFileConnectionDetails - Model Test', () {
    test('Deve criar uma instância com todos os campos corretamente', () {
      final details = ChirpFileConnectionDetails(
        fileId: 'file_001',
        port: 8080,
        token: 'secret_token_123',
      );

      expect(details.fileId, 'file_001');
      expect(details.port, 8080);
      expect(details.token, 'secret_token_123');
    });

    test('Deve converter para JSON corretamente (Serialization)', () {
      final details = ChirpFileConnectionDetails(
        fileId: 'file_abc',
        port: 9000,
        token: 'token_xyz',
      );

      final json = details.toJson();

      expect(json, {'fileId': 'file_abc', 'port': 9000, 'token': 'token_xyz'});
    });

    test('Deve criar uma instância a partir de um JSON (Deserialization)', () {
      final Map<String, dynamic> json = {
        'fileId': 'file_789',
        'port': 4545,
        'token': null,
      };

      final details = ChirpFileConnectionDetails.fromJson(json);

      expect(details.fileId, 'file_789');
      expect(details.port, 4545);
      expect(details.token, isNull);
    });

    test('Roundtrip: De objeto para JSON e de volta para objeto', () {
      final original = ChirpFileConnectionDetails(
        fileId: 'uuid_123',
        port: 3000,
        token: 'auth_key',
      );

      final json = original.toJson();
      final cloned = ChirpFileConnectionDetails.fromJson(json);

      expect(cloned.fileId, original.fileId);
      expect(cloned.port, original.port);
      expect(cloned.token, original.token);
    });
  });
}

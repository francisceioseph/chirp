import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/models/chirp_envelope.dart'; // Ajuste o path conforme seu projeto

void main() {
  group('ChirpEnvelope - Model Test', () {
    test('Deve instanciar corretamente com dados de criptografia', () {
      const payload = 'Base64EncodedData...';
      const key = 'EncryptedSymmetricKey...';
      const iv = 'InitializationVector...';

      final envelope = ChirpEnvelope(payload: payload, key: key, iv: iv);

      expect(envelope.payload, payload);
      expect(envelope.key, key);
      expect(envelope.iv, iv);
    });

    test('Deve realizar a conversão JSON (Roundtrip) sem perda de dados', () {
      final original = ChirpEnvelope(
        payload: 'content_xyz',
        key: 'key_123',
        iv: 'iv_456',
      );

      final json = original.toJson();
      final fromJson = ChirpEnvelope.fromJson(json);

      expect(fromJson.payload, original.payload);
      expect(fromJson.key, original.key);
      expect(fromJson.iv, original.iv);
    });

    test(
      'Deve lançar erro (ou falhar) se campos obrigatórios estiverem ausentes no JSON',
      () {
        // Teste de resiliência: O que acontece se o JSON vier malformado da rede?
        final Map<String, dynamic> incompleteJson = {
          'payload': 'some_data',
          // 'key' e 'iv' faltando
        };

        expect(
          () => ChirpEnvelope.fromJson(incompleteJson),
          throwsA(isA<TypeError>()),
          reason:
              'Deveria quebrar pois key e iv não podem ser nulos no construtor',
        );
      },
    );
  });
}

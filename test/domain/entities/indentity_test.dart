import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/entities/identity.dart';

void main() {
  group('Identity - Entity Test', () {
    test('Deve instanciar corretamente com todos os campos', () {
      final identity = Identity(
        id: '0xABC',
        name: 'Carlos Pássaro',
        nickname: 'carlinhos',
        publicKey: 'pub_123',
        privateKey: 'priv_456',
        email: 'carlos@chirp.com',
      );

      expect(identity.id, '0xABC');
      expect(identity.privateKey, 'priv_456');
    });

    test(
      'Roundtrip JSON: Deve garantir que chaves sensíveis não se percam',
      () {
        final original = Identity(
          id: 'id_original',
          name: 'User',
          nickname: 'nick',
          publicKey: 'key_p_1',
          privateKey: 'key_s_2',
        );

        final json = original.toJson();
        final fromJson = Identity.fromJson(json);

        expect(fromJson.publicKey, original.publicKey);
        expect(fromJson.privateKey, original.privateKey);
        expect(fromJson.id, original.id);
      },
    );

    test(
      'copyWith: Deve permitir atualizar apenas um campo mantendo os outros',
      () {
        final identity = Identity(
          id: '1',
          name: 'Velho Nome',
          nickname: 'old',
          publicKey: 'pub',
        );

        final updated = identity.copyWith(name: 'Novo Nome', nickname: 'new');

        expect(updated.name, 'Novo Nome');
        expect(updated.nickname, 'new');
        expect(updated.id, '1'); // Mantido
        expect(updated.publicKey, 'pub'); // Mantido
      },
    );

    test('Deve aceitar campos nulos (email e privateKey)', () {
      final identity = Identity(
        id: '2',
        name: 'Anon',
        nickname: 'anon',
        publicKey: 'pub_only',
        email: null,
        privateKey: null,
      );

      expect(identity.email, isNull);
      expect(identity.privateKey, isNull);

      final json = identity.toJson();
      expect(json['email'], isNull);
    });
  });
}

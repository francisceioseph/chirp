import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/entities/chirp_message.dart';

void main() {
  group('ChirpMessage - Entity Test', () {
    test('Deve instanciar corretamente com todos os campos básicos', () {
      final date = DateTime(2026, 02, 18, 10, 30);
      final message = ChirpMessage(
        id: 'msg_001',
        senderId: 'user_1',
        author: 'Gemini',
        body: 'Olá, bando!',
        dateCreated: date,
        isFromMe: true,
        conversationId: "conv123",
      );

      expect(message.id, 'msg_001');
      expect(message.dateCreated, date);
      expect(message.isFromMe, true);
    });

    test('Roundtrip JSON: Deve lidar corretamente com a data em ISO8601', () {
      final original = ChirpMessage(
        id: 'msg_999',
        senderId: 'user_x',
        author: 'Tester',
        body: 'Teste de rede',
        dateCreated: DateTime.parse("2026-02-18T11:00:00.000Z"),
        conversationId: "conv123",
      );

      final json = original.toJson();
      final fromJson = ChirpMessage.fromJson(json);

      expect(fromJson.id, original.id);
      expect(fromJson.body, original.body);
      expect(fromJson.dateCreated.isAtSameMomentAs(original.dateCreated), true);
    });

    test('isFromMe: Deve ser falso por padrão se não vier no JSON', () {
      final json = {
        'id': 'msg_remote',
        'senderId': 'other_bird',
        'author': 'Friend',
        'body': 'Oi!',
        'dateCreated': DateTime.now().toIso8601String(),
      };

      final message = ChirpMessage.fromJson(json);
      expect(message.isFromMe, false);
    });

    test(
      'copyWith: Deve permitir trocar o autor sem alterar a data ou o corpo',
      () {
        final original = ChirpMessage(
          id: '1',
          conversationId: "123",
          senderId: 'A',
          author: 'Antigo',
          body: 'Texto',
          dateCreated: DateTime(2026),
        );

        final updated = original.copyWith(author: 'Novo');

        expect(updated.author, 'Novo');
        expect(updated.body, 'Texto'); // Mantido
        expect(updated.id, '1'); // Mantido
      },
    );
  });
}

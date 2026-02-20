import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/models/messages_nest.dart';
import 'package:chirp/domain/entities/message.dart';

void main() {
  group('MessagesNest - Gestão de Histórico', () {
    late MessagesNest nest;

    setUp(() => nest = MessagesNest());

    test('Deve adicionar e ordenar mensagens por data', () {
      final m1 = ChirpMessage(
        id: '1',
        senderId: 'a',
        author: 'Tiel A',
        body: 'Tarde',
        dateCreated: DateTime(2024, 1, 1, 12),
      );

      final m2 = ChirpMessage(
        id: '2',
        senderId: 'a',
        author: 'Tiel A',
        body: 'Cedo',
        dateCreated: DateTime(2024, 1, 1, 10),
      );

      nest.add('chat_1', m1);
      nest.add('chat_1', m2);

      final result = nest.forChat('chat_1');
      expect(result.first.body, 'Cedo');
      expect(result.length, 2);
    });

    test('Não deve permitir mensagens com ID duplicado no mesmo chat', () {
      final m1 = ChirpMessage(
        id: 'rep_1',
        senderId: 'b',
        author: "tiel b",
        body: 'Oi',
        dateCreated: DateTime.now(),
      );

      final m2 = ChirpMessage(
        id: 'rep_1',
        senderId: 'b',
        author: "tiel b",
        body: 'Oi de novo',
        dateCreated: DateTime.now(),
      );

      nest.add('chat_1', m1);
      nest.add('chat_1', m2);

      expect(nest.forChat('chat_1').length, 1);
    });
  });
}

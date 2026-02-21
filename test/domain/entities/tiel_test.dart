import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/entities/tiel.dart';

void main() {
  const colorScheme = ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.yellow,
    error: Colors.red,
  );

  group('Tiel - Entity Test', () {
    test(
      'isSecure deve ser verdadeiro apenas com chave pública e status conectado',
      () {
        final tiel = Tiel(
          id: '1',
          name: 'Pássaro',
          address: '127.0.0.1',
          lastSeen: DateTime.now(),
        );

        expect(tiel.isSecure, false); // Sem chave e sem status conectado

        final secureTiel = tiel.copyWith(
          publicKey: 'pub_key',
          status: TielStatus.connected,
        );

        expect(secureTiel.isSecure, true);
      },
    );

    test('Deve retornar o statusText e a cor correta para cada status', () {
      final tiel = Tiel(
        id: '1',
        name: 'Test',
        address: '0.0.0.0',
        lastSeen: DateTime.now(),
        status: TielStatus.away,
      );

      expect(tiel.statusText, "Soneca...");
      expect(tiel.getStatusColor(colorScheme), Colors.blueGrey.shade300);

      final errorTiel = tiel.copyWith(status: TielStatus.error);
      expect(errorTiel.getStatusColor(colorScheme), colorScheme.error);
    });

    test(
      'Roundtrip JSON: Deve serializar e deserializar mantendo o status',
      () {
        final original = Tiel(
          id: 'id_99',
          name: 'Arara',
          address: '192.168.1.1',
          lastSeen: DateTime.parse("2026-02-18T10:00:00.000"),
          status: TielStatus.blocked,
        );

        final json = original.toJson();
        final fromJson = Tiel.fromJson(json);

        expect(fromJson.status, TielStatus.blocked);
        expect(fromJson.address, '192.168.1.1');
        expect(fromJson.lastSeen.isAtSameMomentAs(original.lastSeen), true);
      },
    );
  });
}

import 'package:chirp/domain/models/chirp_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/entities/tiel.dart';

void main() {
  group('ConversationNest - Coleção Genérica', () {
    test('Deve realizar Upsert corretamente (Criar e Atualizar)', () {
      final nest = ChirpCache<Tiel>();
      const tielId = '0x123';

      // 1. Create
      nest.upsert(
        tielId,
        create: () => Tiel(
          id: tielId,
          address: '198.0.0.1',
          lastSeen: DateTime.now(),
          name: 'Original',
          status: TielStatus.discovered,
        ),
        update: (existing) => existing,
      );
      expect(nest[tielId]?.name, 'Original');

      // 2. Update
      nest.upsert(
        tielId,
        create: () => Tiel(
          id: tielId,
          name: 'Novo',
          address: '198.0.0.2',
          lastSeen: DateTime.now(),
          status: TielStatus.discovered,
        ),
        update: (existing) => existing.copyWith(name: 'Atualizado'),
      );

      expect(nest[tielId]?.name, 'Atualizado');
      expect(nest.all.length, 1);
    });
  });
}

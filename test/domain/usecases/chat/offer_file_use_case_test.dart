import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:crypton/crypton.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:chirp/domain/models/chirp_file_metadata.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/usecases/chat/offer_file_use_case.dart';
import 'package:chirp/infrastructure/services/flock_manager.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';

class MockFlockManager extends Mock implements FlockManager {}

class MockIdentityService extends Mock implements IdentityService {}

void main() {
  late OfferFileUseCase useCase;
  late MockFlockManager flockManager;
  late MockIdentityService identityService;
  late String validPublicKey;

  setUpAll(() {
    final keyPair = RSAKeypair.fromRandom();
    validPublicKey = keyPair.publicKey.toString();

    registerFallbackValue(
      ChirpIdentityPacket(fromId: '0', fromName: 'fallback'),
    );
  });

  setUp(() {
    flockManager = MockFlockManager();
    identityService = MockIdentityService();
    useCase = OfferFileUseCase(
      flockManager: flockManager,
      identityService: identityService,
    );
  });

  test(
    'Deve orquestrar o envio de uma oferta de arquivo corretamente',
    () async {
      // --- ARRANGE ---
      final target = Tiel(
        id: 'target_bird',
        name: 'Alvo',
        address: '10.0.0.1',
        lastSeen: DateTime.now(),
        publicKey: validPublicKey,
        status: TielStatus.connected,
      );

      final metadata = ChirpFileMetadata(
        id: 'file_abc',
        name: 'plano_de_voo.pdf',
        size: 1024,
        checksum: 'sha256-xyz',
      );

      final myIdentity = Identity(
        id: 'meu_id_001',
        name: 'Pássaro Mestre',
        nickname: 'master',
        publicKey: 'minha_pub',
      );

      // Stubbing
      when(
        () => identityService.loadOrCreateIdentity(),
      ).thenAnswer((_) async => myIdentity);

      when(() => flockManager.sendPacket(any(), any())).thenReturn(null);

      await useCase.execute(target, metadata);

      verify(() => identityService.loadOrCreateIdentity()).called(1);

      final captured =
          verify(
                () => flockManager.sendPacket(
                  'target_bird',
                  captureAny(that: isA<ChirpFileOfferPacket>()),
                ),
              ).captured.single
              as ChirpFileOfferPacket;

      expect(captured.fromId, myIdentity.id);
      expect(captured.fromName, myIdentity.name);
      expect(captured.action, ChirpPacketAction.fileOffer);
      expect(captured.envelope.payload, isNotEmpty);
    },
  );
}

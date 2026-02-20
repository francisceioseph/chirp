import 'package:flutter_test/flutter_test.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/domain/models/chirp_envelope.dart';

void main() {
  group('ChirpPacket - Polimorfismo e Serialização', () {
    test('Deve criar um ChirpIdentityPacket a partir do JSON', () {
      final json = {
        'action': 'identity',
        'fromId': 'bird_1',
        'fromName': 'Pica-pau',
      };

      final packet = ChirpPacket.fromJson(json);

      expect(packet, isA<ChirpIdentityPacket>());
      expect(packet.fromId, 'bird_1');
      expect(packet.action, ChirpPacketAction.identity);
    });

    test('Deve criar um ChirpMessagePacket incluindo o Envelope', () {
      final json = {
        'action': 'message',
        'fromId': 'bird_2',
        'fromName': 'Bem-te-vi',
        'envelope': {
          'payload': 'msg_encriptada',
          'key': 'chave_aes',
          'iv': 'vetor_inicial',
        },
      };

      final packet = ChirpPacket.fromJson(json);

      expect(packet, isA<ChirpMessagePacket>());
      final messagePacket = packet as ChirpMessagePacket;
      expect(messagePacket.envelope.payload, 'msg_encriptada');
    });

    test('Deve lançar Exception para ação desconhecida', () {
      final json = {'action': 'invalid_action', 'fromId': 'x', 'fromName': 'y'};

      expect(() => ChirpPacket.fromJson(json), throwsException);
    });

    test('Roundtrip: ChirpRequestPacket deve manter a chave pública', () {
      final original = ChirpRequestPacket(
        fromId: 'user_a',
        fromName: 'Alice',
        publicKey: 'pub_key_123',
      );

      final json = original.toJson();
      final decoded = ChirpPacket.fromJson(json) as ChirpRequestPacket;

      expect(decoded.publicKey, original.publicKey);
      expect(decoded.fromName, 'Alice');
    });

    test('Verificação de FileOfferPacket (Ação Composta)', () {
      final original = ChirpFileOfferPacket(
        fromId: 'sender',
        fromName: 'Enviador',
        envelope: ChirpEnvelope(payload: 'p', key: 'k', iv: 'i'),
      );

      final json = original.toJson();
      expect(json['action'], 'fileOffer');

      final decoded = ChirpPacket.fromJson(json);
      expect(decoded, isA<ChirpFileOfferPacket>());
    });
  });
}

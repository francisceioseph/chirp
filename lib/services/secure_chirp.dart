import 'package:chirp/models/secure_envelope.dart';
import 'package:chirp/models/secure_keys.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypton/crypton.dart';

class SecureChirp {
  static SecureKeys makeKeys() {
    final keyPair = RSAKeypair.fromRandom();
    final pubKey = keyPair.publicKey.toString();
    final privKey = keyPair.privateKey.toString();

    return SecureKeys(privKey: privKey, pubKey: pubKey);
  }

  static SecureEnvelope encrypt(String pubKey, String data) {
    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(aesKey));

    final payload = encrypter.encrypt(data, iv: iv);

    final rsaPubKey = RSAPublicKey.fromString(pubKey);
    final encKey = rsaPubKey.encrypt(aesKey.base64);

    return SecureEnvelope(iv: iv.base64, payload: payload.base64, key: encKey);
  }

  static String decrypt(String privKey, SecureEnvelope envelope) {
    final rsaPrivKey = RSAPrivateKey.fromString(privKey);
    final aesKeyBase64 = rsaPrivKey.decrypt(envelope.key);

    final aesKey = enc.Key.fromBase64(aesKeyBase64);
    final iv = enc.IV.fromBase64(envelope.iv);
    final encrypter = enc.Encrypter(enc.AES(aesKey));

    return encrypter.decrypt64(envelope.payload, iv: iv);
  }
}

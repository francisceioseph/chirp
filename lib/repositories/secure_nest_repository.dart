import 'dart:convert';

import 'package:chirp/models/message.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

abstract class SecureNestPort {
  Future<void> init();
  Future<void> saveMessage(ChirpMessage message);
  Future<List<ChirpMessage>> getMessages(String conversationId);
  Future<void> deleteAll();
}

class SecureNestHiveAdapter implements SecureNestPort {
  Box<Map<String, dynamic>>? _vault;

  static const _storage = FlutterSecureStorage();
  static const _keyAlias = "secure_nest_master_key";

  @override
  Future<void> init() async {
    final encKey = await _getOrGenerateKey();

    _vault = await Hive.openBox<Map<String, dynamic>>(
      'messages_vault',
      encryptionCipher: HiveAesCipher(encKey),
    );
  }

  @override
  Future<void> saveMessage(ChirpMessage message) async {
    final vault = await _getVault();
    await vault.put(message.id, message.toJson());
  }

  @override
  Future<List<ChirpMessage>> getMessages(String conversationId) async {
    final vault = await _getVault();

    return vault.values
        .map((data) => ChirpMessage.fromJson(data))
        .where((m) => m.senderId == conversationId)
        .toList();
  }

  @override
  Future<void> deleteAll() async {
    final vault = await _getVault();
    await vault.clear();
  }

  Future<Box<Map<String, dynamic>>> _getVault() async {
    if (_vault == null) {
      await init();
    }

    return _vault!;
  }

  Future<List<int>> _getOrGenerateKey() async {
    final key = await _storage.read(key: _keyAlias);

    if (key == null) {
      final newKey = Hive.generateSecureKey();
      await _storage.write(key: _keyAlias, value: base64UrlEncode(newKey));

      return newKey;
    }

    return base64Url.decode(key);
  }
}

import 'dart:convert';

import 'package:chirp/domain/ports/secure_nest_port.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureNestHiveAdapter implements SecureNestPort {
  final String _storageSuffix;

  final Map<String, Box<Map>> _vault = {};
  List<int>? _cacheKey;

  static const _storage = FlutterSecureStorage();
  static const _keyAlias = "secure_nest_master_key";

  SecureNestHiveAdapter(this._storageSuffix);

  @override
  Future<void> init() async {
    _cacheKey = await _getOrGenerateKey();
  }

  @override
  Future<void> save(
    String boxName,
    String id,
    Map<String, dynamic> data,
  ) async {
    final box = await _getBox(boxName);
    await box.put(id, data);
  }

  @override
  Future<Map<String, dynamic>?> get(String boxName, String id) async {
    final box = await _getBox(boxName);
    final map = box.get(id) ?? {};

    return Map<String, dynamic>.from(map);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String boxName) async {
    final box = await _getBox(boxName);

    return box.values.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  @override
  Future<void> delete(String boxName, String id) async {
    final box = await _getBox(boxName);
    await box.delete(id);
  }

  @override
  Future<void> deleteAll(String boxName) async {
    final box = await _getBox(boxName);
    await box.clear();
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

  Future<Box<Map>> _getBox(String boxName) async {
    final scopedBoxName = "${boxName}_$_storageSuffix";

    if (_vault.containsKey(scopedBoxName)) {
      return _vault[scopedBoxName]!;
    }

    await init();

    final box = await Hive.openBox<Map>(
      scopedBoxName,
      encryptionCipher: HiveAesCipher(_cacheKey!),
    );

    _vault[scopedBoxName] = box;

    return box;
  }

  @override
  Future<void> close(String boxName) async {
    final scopedBoxName = "${boxName}_$_storageSuffix";

    if (_vault.containsKey(scopedBoxName)) {
      final box = _vault[scopedBoxName]!;
      await box.close();

      _vault.remove(scopedBoxName);
    }
  }
}

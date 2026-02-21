import 'package:chirp/domain/ports/secure_nest_port.dart';

abstract class ISecureNest {
  Future<void> setup();

  Future<void> save(String boxName, String id, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> get(String boxName, String id);
  Future<List<Map<String, dynamic>>> getAll(String boxName);
  Future<void> delete(String boxName, String id);
  Future<void> deleteAll(String boxName);
}

class SecureNestService implements ISecureNest {
  final SecureNestPort _port;

  SecureNestService(this._port);

  @override
  Future<void> setup() async {
    await _port.init();
  }

  @override
  Future<void> save(
    String boxName,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _port.save(boxName, id, data);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String boxName) async {
    return await _port.getAll(boxName);
  }

  @override
  Future<void> delete(String boxName, String id) async {
    await _port.delete(boxName, id);
  }

  @override
  Future<void> deleteAll(String boxName) async {
    await _port.deleteAll(boxName);
  }

  @override
  Future<Map<String, dynamic>?> get(String boxName, String id) {
    return _port.get(boxName, id);
  }
}

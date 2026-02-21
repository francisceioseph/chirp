abstract class SecureNestPort {
  Future<void> init();

  Future<void> save(String boxName, String id, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> get(String boxName, String id);
  Future<List<Map<String, dynamic>>> getAll(String boxName);
  Future<void> delete(String boxName, String id);
  Future<void> deleteAll(String boxName);
  Future<void> close(String boxName);
}

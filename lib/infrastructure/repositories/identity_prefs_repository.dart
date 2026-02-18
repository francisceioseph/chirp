import 'dart:convert';
import 'package:chirp/domain/entities/identity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdentityPrefsRepository {
  static const String _storageKey = "chirp_identity_v1";

  Future<Identity?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final String? identityJson = prefs.getString(_storageKey);

    if (identityJson == null) return null;

    try {
      final Map<String, dynamic> map = jsonDecode(identityJson);
      return Identity.fromJson(map);
    } catch (e) {
      await clear();
      return null;
    }
  }

  Future<void> save(Identity identity) async {
    final prefs = await SharedPreferences.getInstance();
    final String identityJson = jsonEncode(identity.toJson());
    await prefs.setString(_storageKey, identityJson);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_storageKey);
  }
}

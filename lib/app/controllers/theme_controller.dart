import 'package:chirp/app/themes/chirp_theme_catalog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _storageKey = 'selected_theme_id';
  final SharedPreferences _prefs;

  String _currentThemeId;

  ThemeController({required SharedPreferences prefs})
    : _prefs = prefs,
      _currentThemeId =
          prefs.getString(_storageKey) ?? ChirpThemeCatalog.defaultTheme.id;

  String get currentThemeId => _currentThemeId;

  ThemeData get lightTheme => ChirpThemeCatalog.findById(_currentThemeId).light;
  ThemeData get darkTheme => ChirpThemeCatalog.findById(_currentThemeId).dark;

  Future<void> setTheme(String id) async {
    if (_currentThemeId == id) return;

    _currentThemeId = id;
    notifyListeners();

    await _prefs.setString(_storageKey, id);
  }
}

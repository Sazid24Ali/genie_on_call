import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  // store as language key (e.g., 'en', 'hi', 'te', 'en-T', 'en-H')
  String _languageKey = 'en';

  bool get isDarkMode => _isDarkMode;
  String get languageKey => _languageKey;

  /// Locale for MaterialApp
  Locale get locale {
    // allow separators '-' or '_', e.g. 'en-T' or 'en_T'
    final parts = _languageKey.split(RegExp('[-_]'));
    final language = parts.isNotEmpty ? parts[0] : 'en';
    if (parts.length > 1 && parts[1].isNotEmpty) {
      final country = parts[1];
      return Locale(language, country);
    }
    return Locale(language);
  }

  ThemeProvider() {
    _loadPreferences();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _savePreferences();
    notifyListeners();
  }

  /// newLanguage should be a language key like 'en', 'hi', 'te', 'en-T', 'en-H'
  void setLanguage(String newLanguage) {
    _languageKey = newLanguage;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _languageKey = prefs.getString('languageKey') ?? 'en';
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setString('languageKey', _languageKey);
  }
}

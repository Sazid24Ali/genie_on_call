import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genie_on_call/utils/locale_utils.dart';
import 'package:genie_on_call/services/translation_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final tag = prefs.getString('selected_locale');
    if (tag != null && tag.isNotEmpty) {
      try {
        _locale = tagToLocale(tag);
        notifyListeners();
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', localeToTag(newLocale));
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genie_on_call/utils/locale_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

/// A simple translation service that loads translations directly from assets/translations/{locale}.json
class TranslationService {
  final Map<String, Map<String, String>> _cache = {};
  late SharedPreferences _prefs;
  final GoogleTranslator _translator = GoogleTranslator();

  TranslationService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Load translation directly from assets, with in-memory caching per locale.
  Future<String?> getTranslation(String key, Locale locale) async {
    final tag = localeToTag(locale);
    if (!_cache.containsKey(tag)) {
      await _loadFromAssets(tag);
    }
    if (_cache[tag]!.containsKey(key) && _cache[tag]![key]!.isNotEmpty) {
      return _cache[tag]![key];
    }

    // Check local storage for dynamic translations
    final localKey = '${tag}_$key';
    final localTranslation = _prefs.getString(localKey);
    if (localTranslation != null && localTranslation.isNotEmpty) {
      _cache[tag]![key] = localTranslation;
      return localTranslation;
    }

    // If not found and not English, try to translate from English
    if (tag != 'en') {
      // First, get the English version if available
      if (!_cache.containsKey('en')) {
        await _loadFromAssets('en');
      }
      final englishText =
          _cache['en']![key] ?? key; // Assume key is English if not found

      try {
        final translation = await _translateText(englishText, tag);
        if (translation != null && translation.isNotEmpty) {
          // Store in local storage
          await _prefs.setString(localKey, translation);
          _cache[tag]![key] = translation;
          return translation;
        }
      } catch (e) {
        print('Translation error for $key to $tag: $e');
      }
    }

    return key; // Fallback to key
  }

  Future<void> _loadFromAssets(String tag) async {
    try {
      final assetPath = 'assets/translations/${tag}.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> translations = json.decode(jsonString);
      _cache[tag] = translations.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      );
    } catch (e) {
      _cache[tag] = {};
    }
  }

  Future<String?> _translateText(String text, String targetLang) async {
    try {
      final lang = _mapTagToLang(targetLang);
      final translation = await _translator.translate(text, to: lang);
      return translation.text;
    } catch (e) {
      return null;
    }
  }

  String _mapTagToLang(String tag) {
    switch (tag) {
      case 'hi':
        return 'hi';
      case 'te':
        return 'te';
      case 'hi-Latn':
        return 'hi'; // For Henglish, translate to Hindi, but since it's Latin, perhaps keep as is or transliterate later
      case 'te-Latn':
        return 'te';
      default:
        return 'en';
    }
  }
}

import 'package:flutter/material.dart';

String localeToTag(Locale locale) {
  final script = locale.scriptCode;
  if (script != null && script.isNotEmpty)
    return '${locale.languageCode}-$script';
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty)
    return '${locale.languageCode}-${locale.countryCode}';
  return locale.languageCode;
}

Locale tagToLocale(String tag) {
  final parts = tag.split('-');
  if (parts.length == 2) {
    // treat second as script if it's Latn or common script codes, else as country
    final second = parts[1];
    if (second.length == 4) {
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: second);
    }
    return Locale(parts[0], parts[1]);
  }
  return Locale(tag);
}

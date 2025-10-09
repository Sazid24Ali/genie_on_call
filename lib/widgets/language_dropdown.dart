import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:genie_on_call/utils/locale_utils.dart';
import 'package:genie_on_call/widgets/translated_text.dart';
import 'package:genie_on_call/services/translation_service.dart';

typedef OnLocaleChanged = Future<void> Function(Locale newLocale);

class LanguageDropdown extends StatefulWidget {
  final Locale currentLocale;
  final List<Locale> supportedLocales;
  final OnLocaleChanged onLocaleChanged;

  const LanguageDropdown({
    Key? key,
    required this.currentLocale,
    required this.supportedLocales,
    required this.onLocaleChanged,
  }) : super(key: key);

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  Locale? _selected;

  @override
  void initState() {
    if (widget.supportedLocales.contains(widget.currentLocale)) {
      _selected = widget.currentLocale;
    } else {
      _selected = widget.supportedLocales.first;
    }
    super.initState();
  }

  String _displayName(Locale locale) {
    if (locale.languageCode == 'en' &&
        (locale.scriptCode == null || locale.scriptCode!.isEmpty))
      return 'English';
    if (locale.languageCode == 'hi' &&
        (locale.scriptCode == null || locale.scriptCode!.isEmpty))
      return 'हिन्दी';
    if (locale.languageCode == 'te' &&
        (locale.scriptCode == null || locale.scriptCode!.isEmpty))
      return 'తెలుగు';
    if (locale.languageCode == 'hi' && locale.scriptCode == 'Latn')
      return 'Henglish (हिंग्लिश)';
    if (locale.languageCode == 'te' && locale.scriptCode == 'Latn')
      return 'Tenglish (టెంగ్లిష్)';
    return localeToTag(locale);
  }

  Future<void> _onChanged(Locale? newLoc) async {
    if (newLoc == null) return;
    if (newLoc == _selected) return;

    final translationService = Provider.of<TranslationService>(context, listen: false);
    final locale = widget.currentLocale;
    final titleText = await translationService.getTranslation('change_language', locale) ?? 'Change language';
    final changeToText = await translationService.getTranslation('change_language_to', locale) ?? 'Change app language to';
    final cancelText = await translationService.getTranslation('cancel', locale) ?? 'Cancel';
    final confirmText = await translationService.getTranslation('confirm', locale) ?? 'Confirm';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titleText),
        content: Text('$changeToText ${_displayName(newLoc)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _selected = newLoc;
      });
      // persist selection
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_locale', localeToTag(newLoc));
      await widget.onLocaleChanged(newLoc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: _selected,
      icon: const Icon(Icons.language),
      underline: const SizedBox.shrink(),
      items: widget.supportedLocales.map((loc) {
        return DropdownMenuItem(value: loc, child: Text(_displayName(loc)));
      }).toList(),
      onChanged: _onChanged,
    );
  }
}

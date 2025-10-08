import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentLanguage = themeProvider.languageKey;
    final loc = AppLocalizations.of(context);

    return DropdownButton<String>(
      value: currentLanguage,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(value: 'en', child: Text(loc.english)),
        DropdownMenuItem(value: 'hi', child: Text(loc.hindi)),
        DropdownMenuItem(value: 'te', child: Text(loc.telugu)),
        DropdownMenuItem(value: 'en-H', child: Text(loc.hinglish)),
        DropdownMenuItem(value: 'en-T', child: Text(loc.tenglish)),
      ],
      onChanged: (String? newValue) {
        if (newValue != null) {
          themeProvider.setLanguage(newValue);
        }
      },
    );
  }
}

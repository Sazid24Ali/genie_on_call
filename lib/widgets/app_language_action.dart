import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genie_on_call/providers/locale_provider.dart';
import 'package:genie_on_call/widgets/language_dropdown.dart';

class AppLanguageAction extends StatelessWidget {
  const AppLanguageAction({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final current = localeProvider.locale;
    final supported = const [
      Locale('en'),
      Locale('hi'),
      Locale('te'),
      Locale.fromSubtags(languageCode: 'hi', scriptCode: 'Latn'),
      Locale.fromSubtags(languageCode: 'te', scriptCode: 'Latn'),
    ];

    return LanguageDropdown(
      currentLocale: current,
      supportedLocales: supported,
      onLocaleChanged: (loc) async {
        await localeProvider.setLocale(loc);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Language changed to ${loc.languageCode}')),
          );
        }
      },
    );
  }
}

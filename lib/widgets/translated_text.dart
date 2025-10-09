import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genie_on_call/providers/locale_provider.dart';
import 'package:genie_on_call/services/translation_service.dart';

class TranslatedText extends StatefulWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.translationKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  _TranslatedTextState createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  late Future<String?> _translationFuture;
  late Locale _currentLocale;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeProvider = Provider.of<LocaleProvider>(context);
    if (!_initialized || _currentLocale != localeProvider.locale) {
      _currentLocale = localeProvider.locale;
      _loadTranslation();
      _initialized = true;
    }
  }

  void _loadTranslation() {
    final translationService = Provider.of<TranslationService>(
      context,
      listen: false,
    );
    _translationFuture = translationService.getTranslation(
      widget.translationKey,
      _currentLocale,
    );
  }

  @override
  void didUpdateWidget(covariant TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    if (_currentLocale != localeProvider.locale ||
        oldWidget.translationKey != widget.translationKey) {
      _currentLocale = localeProvider.locale;
      _loadTranslation();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to trigger rebuild
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    return FutureBuilder<String?>(
      future: _translationFuture,
      builder: (context, snapshot) {
        final text = snapshot.data ?? widget.translationKey;
        return Text(
          text,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}

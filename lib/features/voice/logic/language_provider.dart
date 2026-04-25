import 'package:flutter/material.dart';
import 'package:loan_lens/core/constants/language_constants.dart';
import 'package:loan_lens/core/services/hive_service.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  LanguageModel _selectedLanguage = LanguageConstants.supportedLanguages.first; // Default to Hindi

  LanguageModel get selectedLanguage => _selectedLanguage;

  LanguageProvider() {
    _loadFromHive();
  }

  void _loadFromHive() {
    final locale = HiveService.getSetting(_languageKey, defaultValue: 'hi_IN');
    _selectedLanguage = LanguageConstants.supportedLanguages.firstWhere(
      (lang) => lang.locale == locale,
      orElse: () => LanguageConstants.supportedLanguages.first,
    );
    notifyListeners();
  }

  Future<void> setLanguage(LanguageModel language) async {
    _selectedLanguage = language;
    await HiveService.saveSetting(_languageKey, language.locale);
    notifyListeners();
  }
}

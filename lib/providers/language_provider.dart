import 'package:flutter/material.dart';
import '../services/translation_service.dart';

/// Provider / ChangeNotifier that exposes the selected language to the UI.
class LanguageProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();

  String get currentLanguageCode => _translationService.currentLangCode;

  Future<void> initialise() async {
    await _translationService.init();
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    await _translationService.changeLanguage(code);
    notifyListeners();
  }

  Future<String> translate(String text) {
    return _translationService.translate(text);
  }
}

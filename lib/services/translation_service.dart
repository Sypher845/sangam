import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

/// Singleton service that handles language selection and text translation
/// across the application.
class TranslationService {
  TranslationService._internal();
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;

  // Google free translator (unofficial – for small / educational apps)
  final GoogleTranslator _translator = GoogleTranslator();

  // Cache <languageCode, <originalText, translatedText>>
  final Map<String, Map<String, String>> _cache = {};

  String _currentLangCode = 'en';

  // Key used in SharedPreferences
  static const _prefsKey = 'selected_language_code';

  /// Supported Indian language codes.
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिन्दी',
    'te': 'తెలుగు',
    'ta': 'தமிழ்',
    'kn': 'ಕನ್ನಡ',
    'pa': 'ਪੰਜਾਬੀ',
  };

  String get currentLangCode => _currentLangCode;

  /// Initialise service – must be called before the first translation.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLangCode = prefs.getString(_prefsKey) ?? 'en';
  }

  /// Change app language and persist selection.
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == _currentLangCode) return;
    _currentLangCode = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, languageCode);
  }

  /// Translate [text] from English into the currently selected language.
  /// If English is selected, returns [text] immediately.
  Future<String> translate(String text) async {
    if (_currentLangCode == 'en') return text;

    // Use cache first
    final langCache = _cache[_currentLangCode] ?? <String, String>{};
    if (langCache.containsKey(text)) {
      return langCache[text]!;
    }

    try {
      final result = await _translator.translate(text, from: 'en', to: _currentLangCode);
      langCache[text] = result.text;
      _cache[_currentLangCode] = langCache;
      return result.text;
    } catch (_) {
      // If translation fails, fallback to original
      return text;
    }
  }
}

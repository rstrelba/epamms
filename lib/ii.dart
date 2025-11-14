import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Централизованный список поддерживаемых языков
class SupportedLanguages {
  static const List<Map<String, String>> languages = [
    {
      'code': 'EN',
      'name': 'English',
      'nativeName': 'English',
    },
    {
      'code': 'UK',
      'name': 'Ukrainian',
      'nativeName': 'Українська',
    },
    {
      'code': 'DE',
      'name': 'German',
      'nativeName': 'Deutsch',
    },
    {
      'code': 'ES',
      'name': 'Spanish',
      'nativeName': 'Español',
    },
    {
      'code': 'FR',
      'name': 'French',
      'nativeName': 'Français',
    },
    {
      'code': 'IT',
      'name': 'Italian',
      'nativeName': 'Italiano',
    },
    {
      'code': 'PL',
      'name': 'Polish',
      'nativeName': 'Polski',
    },
    {
      'code': 'PT',
      'name': 'Portuguese',
      'nativeName': 'Português',
    },
    {
      'code': 'TR',
      'name': 'Turkish',
      'nativeName': 'Türkçe',
    },
  ];

  static List<String> get codes =>
      languages.map((lang) => lang['code']!).toList();
  static List<String> get names =>
      languages.map((lang) => lang['name']!).toList();
  static List<String> get nativeNames =>
      languages.map((lang) => lang['nativeName']!).toList();

  static String getNameByCode(String code) {
    final lang = languages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => languages.first,
    );
    return lang['name']!;
  }

  static String getNativeNameByCode(String code) {
    final lang = languages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => languages.first,
    );
    return lang['nativeName']!;
  }
}

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // now only translations for the current language are stored
  // key - hash of English phrase, value - translation
  HashMap<String, String> _translations = HashMap<String, String>();
  String _currentLanguage = 'EN';
  bool _isInitialized = false;

  // list of available languages is taken from SupportedLanguages
  List<String> get availableLanguages => SupportedLanguages.codes;

  static TranslationService get instance => _instance;

  Future<void> init() async {
    if (_isInitialized) return;

    await _loadCurrentLanguage();
    await _loadTranslations();

    _isInitialized = true;
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('app_language') ?? 'EN';
    } catch (e) {
      debugPrint('Error loading language: $e');
      _currentLanguage = 'EN';
    }
  }

  Future<void> _loadTranslations() async {
    try {
      final csvContent = await rootBundle.loadString('assets/intl.csv');

      // parse CSV only for translations
      _parseCSV(csvContent);
    } catch (e) {
      debugPrint('Error loading translations from assets: $e');
      // try alternative path for compatibility
      try {
        final csvContent = await rootBundle.loadString('intl.csv');
        _parseCSV(csvContent);
      } catch (e2) {
        debugPrint('Failed to load translations from any path: $e2');
      }
    }
  }

  void _parseCSV(String csvContent) {
    final lines = csvContent.split('\n');

    if (lines.isEmpty) {
      return;
    }

    // parse header
    final header = _parseCSVLine(lines[0]);

    // for English language translations are not needed
    if (_currentLanguage == 'EN') {
      return;
    }

    if (header.length < 3) {
      debugPrint(
        'CSV parsing: invalid header, expected 3 columns, got ${header.length}',
      );
      return;
    }

    // determine index of the desired language
    int languageIndex = -1;
    for (int i = 0; i < header.length; i++) {
      if (header[i] == _currentLanguage) {
        languageIndex = i;
        break;
      }
    }

    if (languageIndex == -1) {
      debugPrint('Language $_currentLanguage not found in CSV header');
      return;
    }

    // clean up translations first
    _translations.clear();
    int parsedCount = 0;

    // parse data lines
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) {
        continue;
      }

      final values = _parseCSVLine(lines[i]);
      if (values.length > languageIndex && values.length > 0) {
        final englishText = values[0]; // english first
        final translation = values[languageIndex];
        if (englishText.isNotEmpty && translation.isNotEmpty) {
          // create hash of english phrase
          final hash = _generateKey(englishText);
          _translations[hash] = translation;
          parsedCount++;
        }
      }
    }

    debugPrint(
      'CSV parsing completed: loaded $parsedCount translations for $_currentLanguage',
    );
  }

  List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String current = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          current += '"';
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Field separator
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }

    result.add(current); // Add last field
    return result;
  }

  // Генерируем оптимальный ключ для английской фразы
  String _generateKey(String text) {
    // for short strings use the text itself as a key
    if (text.length <= 32) {
      return 'short:$text';
    }

    // for long strings use hash
    final bytes = utf8.encode(text);
    final digest = sha1.convert(bytes);
    return 'hash:${digest.toString()}';
  }

  String translate(String text) {
    if (!_isInitialized) {
      return text; // Return original if not initialized
    }

    if (_currentLanguage == 'EN') {
      return text; // Return original for English
    }

    // generate hash for translation search
    final hash = _generateKey(text);
    final translation = _translations[hash];

    if (translation != null && translation.isNotEmpty) {
      return translation;
    }

    return text; // Return original if translation not found
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return; // language has not changed

    _currentLanguage = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', language);

      // reload translations for the new language
      await _loadTranslations();
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  String get currentLanguage => _currentLanguage;

  // method for getting statistics
  int get translationsCount => _translations.length;
}

// extension for internationalization of strings
extension StringInternationalization on String {
  String ii() {
    return TranslationService.instance.translate(this);
  }
}

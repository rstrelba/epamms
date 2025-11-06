import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // Теперь храним только переводы для текущего языка
  // Ключ - хэш английской фразы, значение - перевод
  HashMap<String, String> _translations = HashMap<String, String>();
  String _currentLanguage = 'EN';
  bool _isInitialized = false;

  // Список доступных языков из CSV заголовка
  List<String> _availableLanguages = [];

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

      // Всегда парсим CSV для получения списка языков
      _parseCSV(csvContent);
    } catch (e) {
      debugPrint('Error loading translations from assets: $e');
      // Попробуем альтернативный путь для совместимости
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
      _availableLanguages = ['EN', 'UA', 'GE', 'ES', 'FR'];
      return;
    }

    // Парсим заголовок
    final header = _parseCSVLine(lines[0]);

    // Сохраняем доступные языки
    _availableLanguages = header.map((lang) {
      String cleanLang = lang.trim().toUpperCase();
      return cleanLang;
    }).toList();

    // Для английского языка переводы не нужны
    if (_currentLanguage == 'EN') {
      return;
    }

    if (header.length < 3) {
      debugPrint(
        'CSV parsing: invalid header, expected 3 columns, got ${header.length}',
      );
      return;
    }

    // Определяем индекс нужного языка
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

    // Очищаем переводы
    _translations.clear();
    int parsedCount = 0;
    int skippedCount = 0;

    // Парсим строки данных
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) {
        skippedCount++;
        continue;
      }

      final values = _parseCSVLine(lines[i]);
      if (values.length > languageIndex && values.length > 0) {
        final englishText =
            values[0]; // Английский текст всегда в первой колонке
        final translation = values[languageIndex]; // Перевод в нужной колонке

        if (englishText.isNotEmpty && translation.isNotEmpty) {
          // Создаем хэш английской фразы
          final hash = _generateKey(englishText);
          _translations[hash] = translation;
          parsedCount++;
        } else {
          skippedCount++;
        }
      } else {
        skippedCount++;
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
    // Для коротких строк используем сам текст как ключ
    // SHA256 хэш всегда 64 символа, поэтому если текст короче - используем его
    if (text.length <= 32) {
      // Добавляем префикс чтобы избежать коллизий с длинными текстами
      return 'short:$text';
    }

    // Для длинных строк используем хэш
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return 'hash:${digest.toString()}';
  }

  String translate(String text) {
    if (!_isInitialized) {
      return text; // Return original if not initialized
    }

    if (_currentLanguage == 'EN') {
      return text; // Return original for English
    }

    // Генерируем хэш для поиска перевода
    final hash = _generateKey(text);
    final translation = _translations[hash];

    if (translation != null && translation.isNotEmpty) {
      return translation;
    }

    return text; // Return original if translation not found
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return; // Язык не изменился

    _currentLanguage = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', language);

      // Перезагружаем переводы для нового языка
      await _loadTranslations();
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  String get currentLanguage => _currentLanguage;

  // Метод для получения статистики
  int get translationsCount => _translations.length;

  // Геттер для доступных языков
  List<String> get availableLanguages => List<String>.from(_availableLanguages);
}

// Extension для интернационализации строк
extension StringInternationalization on String {
  String ii() {
    return TranslationService.instance.translate(this);
  }
}

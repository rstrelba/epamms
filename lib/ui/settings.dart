import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:epamms/state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ii.dart';

class SettingsUI extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SettingsState();
}

class _SettingsState extends State<SettingsUI> {
  String _selectedLanguage = 'EN';
  List<String> _availableLanguages = [];

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'settings');
    _loadLanguage();
    _initializeLanguages();
  }

  Future<void> _initializeLanguages() async {
    // TranslationService initialized
    await TranslationService.instance.init();
    _loadAvailableLanguages();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadAvailableLanguages() {
    final languages = TranslationService.instance.availableLanguages;

    setState(() {
      // If the service hasn't loaded languages, use fallback
      if (languages.isEmpty) {
        _availableLanguages = ['EN', 'UA', 'GE', 'ES', 'FR'];
      } else {
        // Fix possible parsing problems
        _availableLanguages = languages.map((lang) {
          String cleanLang = lang.trim();
          return cleanLang;
        }).toList();
      }
    });
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('lang') ?? 'EN';
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', language);

    // Update language in translation service
    await TranslationService.instance.setLanguage(language);

    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings".ii()), centerTitle: true),
      body: _buildTextFields(context),
    );
  }

  Widget _buildTextFields(context) {
    var state = Provider.of<AppState>(context);
    //if (!_isLoaded) return Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme'.ii(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            RadioListTile<ThemeMode>(
              title: Text('Light theme'.ii()),
              groupValue: state.themeMode,
              onChanged: (value) {
                state.setTheme(ThemeMode.light);
              },
              value: ThemeMode.light,
            ),
            RadioListTile(
              title: Text('Dark theme'.ii()),
              groupValue: state.themeMode,
              onChanged: (value) {
                state.setTheme(ThemeMode.dark);
              },
              value: ThemeMode.dark,
            ),
            RadioListTile(
              title: Text('System theme'.ii()),
              groupValue: state.themeMode,
              onChanged: (value) {
                state.setTheme(ThemeMode.system);
              },
              value: ThemeMode.system,
            ),
            const Divider(),
            Text(
              'Language'.ii(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            // Dropdown for language selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _availableLanguages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButton<String>(
                      value: _availableLanguages.contains(_selectedLanguage)
                          ? _selectedLanguage
                          : _availableLanguages.first,
                      isExpanded: true,
                      underline:
                          const SizedBox(), // убираем стандартное подчеркивание
                      items: _availableLanguages.map((String language) {
                        final displayName = _getLanguageName(language);
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != _selectedLanguage) {
                          _saveLanguage(newValue);
                        }
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Метод для получения человеко-читаемого названия языка
  String _getLanguageName(String languageCode) {
    // Принудительная очистка и нормализация
    String cleanCode = languageCode.trim().toUpperCase();

    switch (cleanCode) {
      case 'EN':
        return 'English';
      case 'UA':
        return 'Українська';
      case 'GE':
        return 'Deutsch';
      case 'ES':
        return 'Español';
      case 'FR':
        return 'Français';
      default:
        return languageCode; // return original code
    }
  }

  Future<void> saveTheme(int theme) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("theme", theme);
  }
}

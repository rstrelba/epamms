import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mysterioussanta/state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import '../ii.dart';

class SettingsUI extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SettingsState();
}

class _SettingsState extends State<SettingsUI> {
  String _selectedLanguage = 'EN';
  List<String> _availableLanguages = [];
  AuthorizationStatus _notificationStatus = AuthorizationStatus.notDetermined;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _initializeLanguages();
    _checkNotificationPermissions();
  }

  Future<void> _initializeLanguages() async {
    // Убеждаемся, что TranslationService инициализирован
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
      // Если сервис еще не загрузил языки, используем fallback
      if (languages.isEmpty) {
        _availableLanguages = ['EN', 'UA', 'GE', 'ES', 'FR'];
      } else {
        // Исправляем возможные проблемы с парсингом
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
      _selectedLanguage = prefs.getString('app_language') ?? 'EN';
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language);

    // Update language in translation service
    await TranslationService.instance.setLanguage(language);

    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<void> _checkNotificationPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.getNotificationSettings();

      setState(() {
        _notificationStatus = settings.authorizationStatus;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      print('Error checking notification permissions: $e');
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestNotificationPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permissions
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      setState(() {
        _notificationStatus = settings.authorizationStatus;
        _isCheckingPermissions = false;
      });

      // Show result to user
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get token and cache it
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          String? token = await messaging.getToken();
          AppState.cachedFcmToken = token;
        } catch (e) {
          print('Error getting token after permission grant: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Push-messages are allowed! 🎉'.ii()),
            backgroundColor: Colors.green,
          ),
        );
        await API.auth();
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Permissions are denied. You can enable them in the system settings.'
                    .ii()),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
      setState(() {
        _isCheckingPermissions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting permissions'.ii()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getNotificationStatusText() {
    switch (_notificationStatus) {
      case AuthorizationStatus.authorized:
        return 'Allowed';
      case AuthorizationStatus.denied:
        return 'Denied';
      case AuthorizationStatus.notDetermined:
        return 'Not determined';
      case AuthorizationStatus.provisional:
        return 'Provisional';
      default:
        return 'Unknown';
    }
  }

  Color _getNotificationStatusColor() {
    switch (_notificationStatus) {
      case AuthorizationStatus.authorized:
        return Colors.green;
      case AuthorizationStatus.denied:
        return Colors.red;
      case AuthorizationStatus.notDetermined:
        return Colors.orange;
      case AuthorizationStatus.provisional:
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
            // Dropdown для выбора языка
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
            const Divider(),

            // Секция Push-уведомлений
            Text(
              'Push messages'.ii(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // Карточка с информацией о статусе разрешений
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _notificationStatus == AuthorizationStatus.authorized
                              ? EvaIcons.bellOutline
                              : EvaIcons.bellOffOutline,
                          color: _getNotificationStatusColor(),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Permittion' 's status'.ii(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _isCheckingPermissions
                                  ? Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Проверяем...'.ii(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _getNotificationStatusText().ii(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _getNotificationStatusColor(),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Показываем кнопку только если разрешения не предоставлены
                    if (_notificationStatus !=
                        AuthorizationStatus.authorized) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingPermissions
                              ? null
                              : _requestNotificationPermissions,
                          icon: Icon(
                            _notificationStatus == AuthorizationStatus.denied
                                ? EvaIcons.settingsOutline
                                : EvaIcons.bellOutline,
                          ),
                          label: Text(
                            _notificationStatus == AuthorizationStatus.denied
                                ? 'Open settings'.ii()
                                : 'Allow messages'.ii(),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              EvaIcons.checkmarkCircle2Outline,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Push-messages are enabled'.ii(),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Visibility(
              visible: false,
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Google cloud translate API key".ii(),
                  prefixIcon: const Icon(EvaIcons.lockOutline),
                ),
                obscureText: true,
                onSubmitted: (_) {
                  //AIzaSyC39pJSU9RoqKJRtqXC0vaqg61JQAF_l94
                },
              ),
            ),
            Visibility(
              visible: state.dictId > 0,
              child: ListTile(
                leading: SizedBox(
                  height: 48.0,
                  width: 48.0, // fixed width and height
                  child: Image.asset("images/tg.png"),
                ),
                title: Text(
                  'Attach telegram bot'.ii(),
                  //style: TextStyle(fontSize: 20),
                ),
                onTap: () => _launchTelegramBot(),
              ),
            ),
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
        return languageCode; // возвращаем оригинальный код
    }
  }

  void _launchTelegramBot() async {
    var token = await API.getToken();
    String url = "https://t.me/myvocabappbot?start=" + token;
    print("launchingUrl: $url");
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

Future<void> saveTheme(int theme) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt("theme", theme);
}

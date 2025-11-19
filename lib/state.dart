import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:epamms/ui/room.dart';
import 'package:epamms/ui/roomview.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'ii.dart';

class AppState with ChangeNotifier {
  static String? initialUri = "";
  static String? initialPush = "";
  static String? cachedFcmToken; // Cache FCM token
  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late BuildContext mContext;
  late GoogleSignIn googleSignIn;
  GoogleSignInAccount? _currentUser;
  String _contactText = '';
  String appVersion = '';
  String err = '';
  static int _currentDict = 0;

  int clientId = 0;
  String clientLogin = '';
  int dictId = 0;
  String dictName = "My dictionary";
  var dicts = [];

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  ThemeMode _themeMode = ThemeMode.system;
  String clientName = "";
  bool isExpandedLogin = false;
  ThemeMode get themeMode => _themeMode;

  AppState._();

  static Future<AppState> create({bool firebaseEnabled = true}) async {
    final state = AppState._();
    await state._init(firebaseEnabled: firebaseEnabled);
    return state;
  }

  AppState(BuildContext context) {}

  AppState withContext(BuildContext context) {
    mContext = context;
    return this;
  }

  // Load saved theme
  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String themeString = "system";
    try {
      themeString = prefs.getString('theme') ?? "";
    } catch (e) {}

    ThemeMode theme = ThemeMode.values.firstWhere(
      (e) => e.toString() == themeString,
      orElse: () => ThemeMode.system,
    );
    _themeMode = _mapAppThemeToThemeMode(theme);
    notifyListeners();
  }

  void setTheme(ThemeMode theme) async {
    _themeMode = _mapAppThemeToThemeMode(theme);
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('theme', theme.toString()); // Save to memory
  }

  // Convert `AppTheme` to `ThemeMode`
  ThemeMode _mapAppThemeToThemeMode(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light:
        return ThemeMode.light;
      case ThemeMode.dark:
        return ThemeMode.dark;
      case ThemeMode.system:
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _init({bool firebaseEnabled = true}) async {
    try {
      // version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String platform = GetPlatform.isAndroid
          ? "Android"
          : GetPlatform.isIOS
              ? "iOS"
              : "web";
      appVersion =
          '${packageInfo.version} (build ${packageInfo.buildNumber} on $platform)';
      API.appVersion = appVersion;
    } catch (e) {
      debugPrint('Error getting package info: $e');
      appVersion = '1.0.0 (unknown)';
    }

    if (firebaseEnabled) {
      try {
        if (!GetPlatform.isWeb) await _setupFirebaseMessaging();
      } catch (e) {
        debugPrint('Error setting up Firebase messaging: $e');
      }
    } else {
      debugPrint('Firebase disabled, skipping messaging setup');
    }

    // init app links
    try {
      await initDeepLinks();
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
    }

    // theme
    try {
      await loadTheme(); // load theme
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }

    // auth
    try {
      await tryToAuth();
    } catch (e) {
      debugPrint('Error during authentication: $e');
    }
  }

  Future<void> tryToAuth() async {
    try {
      final res = await API.auth();
      clientId = res['clientId'];
      clientLogin = res['login'];
      debugPrint("AUTH" + res.toString());
    } on Exception catch (e) {
      debugPrint('Error during authentication: $e');
    }
  }

  String getVersion() {
    return 'version $appVersion';
  }

  // Method for updating the language and notifying all listeners
  Future<void> updateLanguage(String language) async {
    await TranslationService.instance.setLanguage(language);
    notifyListeners(); // Notify all widgets about the change
  }

  /*
  Future<int> handleSignIn() async {
    try {
      bool isSigned = await googleSignIn.isSignedIn();
      if (isSigned) googleSignIn.signOut();
      var user = await googleSignIn.signIn();
      debugPrint(user.toString());
      String? email = '';
      if (user?.email == null) return 0;
      email = user?.email;
      var response = await API.loginWith(email.toString(), "google");
      debugPrint(response.body.toString());
      var res = jsonDecode(response.body.toString());
      clientId = res['clientId'];
      if (MyApp.clientId > 0) MyApp.dicts = res['dicts'];
      if (!MyApp.dicts.isEmpty) {
        Map item = MyApp.dicts.firstWhere((item) => item['id'] == MyApp.dictId,
            orElse: () {
          if (MyApp.dicts.length == 0) return {0, ""};
          MyApp.dictId = MyApp.dicts[0]['id'];
          //return MyApp.dicts[0];
        });
        MyApp.dictName = item['name'];
      }

      return res['clientId'];
    } catch (error) {
      debugPrint(error.toString());
      err = error.toString();
    } finally {
      return MyApp.clientId;
    }
  }

   */

  /*
  Future<int> handleSignInFb() async {
    try {
      final facebookLogin = FacebookLogin();
      final FacebookLoginResult result = await facebookLogin.logIn(['email']);
      debugPrint(result.toString());
      return 1;
    } catch (error) {
      debugPrint(error.toString());
      return 0;
    }
  }

   */

  Future _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // iOS - show permission dialog
      // Android 13+ (SDK 33+) - also shows permission dialog
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
          'Firebase messaging permission status: ${settings.authorizationStatus}');

      // IMPORTANT: Get token ONLY if permission is granted
      // This is critical for Android 13+ and Samsung devices
      if (!GetPlatform.isWeb) {
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          // Small delay for stabilization on Samsung devices
          await Future.delayed(const Duration(milliseconds: 500));

          String? token = await messaging.getToken();
          debugPrint('FCM Token: ${token ?? "none"}');

          AppState.cachedFcmToken = token;
        } else {
          debugPrint('Notification permission denied, skipping token request');
          AppState.cachedFcmToken = "no_permission";
        }
      }
    } catch (e) {
      debugPrint('Error requesting Firebase messaging permissions: $e');
      return; // Exit function if we can't get permissions
    }

    try {
      FirebaseMessaging.instance.getInitialMessage().then((message) async {
        if (message != null) {
          debugPrint(
              'FirebaseMessaging.getInitialMessage ${message.data.toString()}');
          initialPush = message.data["url"];
          debugPrint('Saved initialPush: $initialPush');
          // Don't process immediately as UI is not ready yet
          // Processing will be in checkAndHandleInitialPush()
        }
      });
    } catch (e) {
      debugPrint('Error getting initial Firebase message: $e');
    }

    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print("message recieved");
        debugPrint(
            'FirebaseMessaging.onMessage.listen ${message.data.toString()}');
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        if (notification != null && android != null && !kIsWeb) {
          flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  //channel.description,
                ),
              ),
              payload: message.data["url"]);
        }
      });
    } catch (e) {
      debugPrint('Error setting up Firebase message listener: $e');
    }

    try {
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        handleRawMessage(message);
      });
    } catch (e) {
      debugPrint('Error setting up Firebase onMessageOpenedApp listener: $e');
    }

    void onDidReceiveNotificationResponse(
        NotificationResponse notificationResponse) async {
      try {
        final String? payload = notificationResponse.payload;
        if (notificationResponse.payload != null) {
          debugPrint('notification payload: $payload');
          handleMessage(payload);
        }
      } catch (e) {
        debugPrint('Error handling notification response: $e');
      }
    }

    try {
      channel = const AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          importance: Importance.high,
          //sound: RawResourceAndroidNotificationSound('notification_sound'),
          playSound: true);

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      /// Create an Android Notification Channel.
      ///
      /// We use this channel in the `AndroidManifest.xml` file to override the
      /// default FCM channel to enable heads up notifications.
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      var initializationSettingsAndroid =
          const AndroidInitializationSettings('@mipmap/launcher_icon');
      var initializationSettingsIOS = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: initializationSettingsIOS);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

      debugPrint('Local notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }

    try {
      /// Update the iOS foreground notification presentation options to allow
      /// heads up notifications.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Error setting Firebase foreground notification options: $e');
    }
  }

  void handleRawMessage(RemoteMessage message) {
    String url = message.data["url"];
    handleMessage(url);
  }

  void handleMessage(String? url) async {
    if (url == null || url.isEmpty) return;

    var params = url.split("/");
    if (params[0] == "room") {
      //
      try {
        debugPrint("handleMessage params=$url");
        String? id = params[1].toString();

        // Use Navigator instead of Get.to for proper theme passing
        if (Get.context != null) {
          Navigator.of(Get.context!).push(
            MaterialPageRoute(
              builder: (context) => RoomViewUI(roomSecret: id),
            ),
          );
        } else {
          // Fallback to Get.to if context is unavailable
          Get.to(() => RoomViewUI(roomSecret: id), preventDuplicates: false);
        }
      } catch (e) {
        debugPrint('Error in handleMessage: $e');
      }
    }
  }

  // Method to check and handle initialPush after UI is ready
  void checkAndHandleInitialPush() {
    if (initialPush != null && initialPush!.isNotEmpty) {
      debugPrint('Processing initialPush: $initialPush');
      String urlToProcess = initialPush!;
      initialPush = null; // Clear to avoid processing again

      // Small delay to ensure UI is ready
      Future.delayed(Duration(milliseconds: 500), () {
        handleMessage(urlToProcess);
      });
    }
  }

  // Method to check and handle initialUri after UI is ready
  void checkAndHandleInitialUri() {
    if (initialUri != null && initialUri!.isNotEmpty) {
      debugPrint('Processing initialUri: $initialUri');
      String uriToProcess = initialUri!;
      initialUri = null; // Clear to avoid processing again

      // Small delay to ensure UI is ready
      Future.delayed(Duration(milliseconds: 700), () {
        try {
          Uri uri = Uri.parse(uriToProcess);
          openAppLink(uri);
        } catch (e) {
          debugPrint('Error parsing initialUri: $e');
        }
      });
    }
  }

  //https://app-site-association.cdn-apple.com/a/v1/ms.afisha.news
  Future<void> initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      var initUri = await _appLinks.getInitialLink();
      if (initUri != null) {
        debugPrint('initialLink: $initUri');
        initialUri = initUri.toString();

        // Save for processing after UI is ready
        debugPrint('Saved initialUri for later processing: $initialUri');
      }

      // Handle links
      debugPrint('initAppLinks');
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        debugPrint('onAppLink: $uri');
        openAppLink(uri);
      });

      debugPrint('Deep links initialized successfully');
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
    }
  }

  String processDeepLink(String link) {
    RegExp roomRegExp = RegExp(r'/room/(\d+)');
    Match? roomMatch = roomRegExp.firstMatch(link);
    if (roomMatch != null) {
      String roomId = roomMatch.group(1)!;
      return roomId;
    }

    return '';
  }

  String? extractLinkType(String link) {
    if (link.contains('/s/')) return 's';
    if (link.contains('/w/')) return 'w';
    if (link.contains('/room/')) return 'room';
    return null;
  }

  void openAppLink(Uri uri) async {
    final match = RegExp(r'/room/([^/]+)').firstMatch(uri.toString());
    try {
      if (match != null) {
        final roomSecret = match.group(1)!;
        debugPrint('Opening room via app link: $roomSecret');

        await Future.delayed(const Duration(milliseconds: 300));
        if (Get.context != null) {
          Navigator.of(Get.context!).push(
            MaterialPageRoute(
              builder: (context) => RoomViewUI(roomSecret: roomSecret),
            ),
          );
        } else {
          // Fallback on Get.to if context is not available
          Get.to(() => RoomViewUI(roomSecret: roomSecret),
              preventDuplicates: false);
        }
      }
    } on Exception catch (e) {
      debugPrint('openAppLink error: ${e.toString()}');
    }
  }
}

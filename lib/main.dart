import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/utils.dart';
import 'package:myvocab/ui/login.dart';
import 'package:myvocab/state.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'firebase_options.dart';
import 'ui/home.dart';
import 'ii.dart';

@pragma('vm:entry-point')
Future<void> _messageHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('_messageHandler (background) ${message.data.toString()}');
  } catch (e) {
    debugPrint('Background message handler error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;

  try {
    debugPrint('Starting Firebase initialization...');

    // Используем правильную конфигурацию Firebase для всех платформ
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Firebase initialized successfully');
    API.log("Firebase initialized successfully");

    if (!GetPlatform.isWeb) {
      FirebaseMessaging.onBackgroundMessage(_messageHandler);
    }

    firebaseInitialized = true;
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    firebaseInitialized = false;
    API.log('Firebase initialization error: $e');
  }

  try {
    // Init translation service
    await TranslationService.instance.init();
  } catch (e) {
    debugPrint('Translation service initialization error: $e');
  }

  try {
    final appState =
        await AppState.create(firebaseEnabled: firebaseInitialized);
    runApp(
      ChangeNotifierProvider(
        create: (context) => appState.withContext(context),
        lazy: false,
        child: MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('App initialization error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing: $e'),
          ),
        ),
      ),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    debugPrint('initialLink from MyApp: ${AppState.initialUri}');
    return Consumer<AppState>(builder: (BuildContext context, value, child) {
      return GetMaterialApp(
        title: 'Mysterious Santa'.ii(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: state.themeMode,
        // Decides which theme to show, light or dark.
        navigatorKey: navigatorKey,
        home: HomeUI(),
      );
    });
  }
}

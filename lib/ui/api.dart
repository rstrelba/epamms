import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state.dart';

// login
class API {
  static var unescape = HtmlUnescape();
  static const String apiUrl = "https://myvocab.app/";
  static String _atoken = '123';
  static var _headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': 'true',
    'Authorization': 'Bearer $_atoken',
  };
  static var headers = {'Content-Type': 'application/json; charset=utf-8'};
  static String httpErr = "Internet request failed with status ";

  static var _postHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $_atoken',
  };

  static var info = "info";
  static String appVersion = "";

  static String calculateSHA512(String input) {
    var bytes = utf8.encode(input);
    var digest = sha512.convert(bytes);
    return digest.toString();
  }

  static Future<String> getToken({bool isNew = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var key = "token";
    String atoken = "";
    if (!isNew) atoken = prefs.getString(key) ?? "";
    if (atoken.length < 5) {
      atoken = randomAlphaNumeric(64);
      await prefs.setString(key, atoken);
    }
    return atoken;
  }

  static Future<String> getFbToken() async {
    String fbToken = "web";

    try {
      if (!kIsWeb) {
        // ВАЖНО: Используем кэшированный токен из state.dart._setupFirebaseMessaging()
        // Это предотвращает повторные запросы токена, которые вызывают
        // FIS_AUTH_ERROR на Samsung устройствах
        if (AppState.cachedFcmToken != null &&
            AppState.cachedFcmToken!.isNotEmpty) {
          fbToken = AppState.cachedFcmToken!;
          debugPrint("Using cached FCM token");
        } else {
          // Fallback: если токен не закэширован, пробуем получить
          debugPrint("Cached token not found, requesting new one");
          fbToken = await FirebaseMessaging.instance.getToken() ?? "none";
        }
      }
    } catch (e) {
      API.log('Firebase get token error: ' + e.toString());
      fbToken = await _retryGettingToken();
    }

    debugPrint("Firebase token=$fbToken");
    return fbToken;
  }

  static Future<String> _retryGettingToken() async {
    try {
      API.log('Retry getting token');

      // Удаляем старый токен и кэш
      await FirebaseMessaging.instance.deleteToken();
      AppState.cachedFcmToken = null;

      // Задержка для Samsung устройств
      await Future.delayed(const Duration(seconds: 2));

      final token = await FirebaseMessaging.instance.getToken();
      API.log('Firebase get token (with retry): ' + token.toString());

      // Сохраняем новый токен в кэш
      AppState.cachedFcmToken = token;

      return token ?? "none";
    } on Exception catch (e) {
      API.log('Firebase get token error (with retry): ' + e.toString());
      return "none";
    }
  }

  static Future auth() async {
    var url = apiUrl + "auth.php";
    debugPrint("URL= $url");

    Map params = Map();
    params["stoken"] = await getToken();
    params["fbtoken"] = await getFbToken();
    params["version"] = API.appVersion;
    params["device"] = await getDeviceName();
    return http.post(Uri.parse(url), body: params);
  }

  static Future login(String login, String password, String version) async {
    var url = apiUrl + "login.php";
    debugPrint("URL= $url");
    Map params = Map();
    params["login"] = login;
    params["password"] = password;
    params["version"] = version;
    params["stoken"] = await getToken();
    params["fbtoken"] = await getFbToken();
    params["device"] = await getDeviceName();
    return http.post(Uri.parse(url), body: params);
  }

  static Future logout() async {
    await GoogleSignIn.instance.signOut();

    var url = apiUrl + "logout.php";
    debugPrint("URL= $url");
    Map params = Map();
    params["stoken"] = await getToken();
    await getToken(isNew: true);
    return http.post(Uri.parse(url), body: params);
  }

  static Future log(String log) async {
    var url = apiUrl + "log.php";
    debugPrint("URL= $url");
    Map params = Map();
    params["stoken"] = await getToken();
    params["log"] = log + "|" + await getDeviceName() + "|" + appVersion;
    return http.post(Uri.parse(url), body: params);
  }

  static Future loginWith(Map params) async {
    var url = apiUrl + "login-with.php";
    debugPrint("URL= $url");
    String hh = await getToken();
    params["stoken"] = hh;
    //$auth2 = sha1($login . $hh . "MyVocab");
    var login = params['login'];
    var seed = randomAlphaNumeric(64);
    String source = login.toUpperCase() + "MyVocab0_" + seed;
    var seal = calculateSHA512(source);
    params["seed"] = seed;
    params["seal"] = seal;
    params["type"] = params['provider'];
    params["device"] = await getDeviceName();
    String? fbToken = await getFbToken();
    params["fbtoken"] = fbToken;
    return http.post(Uri.parse(url), body: params);
  }

  static Future getLangs() async {
    var url = apiUrl + "get-lang.php";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getVocabs(
      int page, String q, int dictId, String sortMode) async {
    String stoken = await getToken();
    var url = apiUrl +
        "get-vocabs.php?p=$page&stoken=$stoken&dictId=${dictId}&sortMode=$sortMode";
    if (q.length > 0) url += "&q=$q";
    debugPrint("URL=$url");
    //return http.get(Uri.parse(url), headers: _headers);
    return http.get(Uri.parse(url));
  }

  static Future getVocab(int id, int dictId, String word) async {
    String stoken = await getToken();
    String w2 = Uri.encodeComponent(word); // Кодирование параметра w
    var url = apiUrl +
        "get-vocab.php?id=$id&stoken=$stoken&dictId=${dictId}&word=$w2";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getAssoc(int id) async {
    String stoken = await getToken();
    var url = apiUrl + "get-assoc.php?id=$id&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getAssocAI(int id, String word) async {
    String stoken = await getToken();
    var url = apiUrl + "get-assoc-ai.php?id=$id&stoken=$stoken&word=$word";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getDescAI(int id) async {
    String stoken = await getToken();
    var url = apiUrl + "get-desc-ai.php?id=$id&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future checkVocab(String q, int dictId) async {
    String stoken = await getToken();
    var url = apiUrl + "check-vocab.php?stoken=$stoken&dictId=${dictId}";
    if (q.length > 0) url += "&q=$q";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getVocabShare(int id, int dictId) async {
    String stoken = await getToken();
    var url =
        apiUrl + "get-vocab-share.php?id=$id&stoken=$stoken&dictId=${dictId}";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getVocabByShare(String shareUrl) async {
    String stoken = await getToken();
    var url = apiUrl + "get-vocab-by-share.php?shareUrl=${shareUrl}";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getVocabExample(int id) async {
    String stoken = await getToken();
    var url = apiUrl + "get-example.php?id=$id&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getVocabExample2(int id, String w) async {
    String stoken = await getToken();
    String w2 = Uri.encodeComponent(w); // Кодирование параметра w
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var level = prefs.getString("level") ?? "B1";
    var url =
        apiUrl + "get-example2.php?id=$id&w=$w2&level=$level&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getVocabSynonymsAI(int id) async {
    String stoken = await getToken();
    var url = apiUrl + "get-synonyms-ai.php?id=$id&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getVocabAI(int id) async {
    String stoken = await getToken();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var level = prefs.getString("level") ?? "B1";
    var url = apiUrl + "get-word-ai.php?id=$id&level=$level&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getVocabAIByWord(String word, int dictId) async {
    String stoken = await getToken();
    var url = apiUrl +
        "get-vocab-ai-byword.php?word=$word&dictId=$dictId&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getDict(int id) async {
    String stoken = await getToken();
    var url = apiUrl + "get-dict.php?stoken=$stoken&dictId=${id}"; //
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future putVocab(Map word) async {
    var url = apiUrl + "put-vocab.php";
    debugPrint("URL= $url");
    word['stoken'] = await getToken();
    debugPrint("MAP= " + word.toString());
    return http.post(Uri.parse(url), body: json.encode(word), headers: headers);
  }

  static Future putDict(Map dict) async {
    var url = apiUrl + "put-dict.php";
    debugPrint("URL= $url");
    dict['stoken'] = await getToken();
    debugPrint("MAP= " + dict.toString());
    return http.post(Uri.parse(url), body: json.encode(dict), headers: headers);
  }

  static Future delDict(Map dict) async {
    var url = apiUrl + "del-dict.php";
    debugPrint("URL= $url");
    dict['stoken'] = await getToken();
    debugPrint("MAP= " + dict.toString());
    return http.post(Uri.parse(url), body: json.encode(dict), headers: headers);
  }

  static Future renewReminder(int id) async {
    var url = apiUrl + "renew-reminder.php";
    debugPrint("URL= $url");
    Map params = Map();
    params["id"] = id.toString();
    params['stoken'] = await getToken();
    return http.post(Uri.parse(url), body: params);
  }

  //https://pokupki.mobi/lllb/get-ex.php?type=1&vars=5
  static Future getEx(int cType, int dictId) async {
    String stoken = await getToken();
    var url = apiUrl +
        "get-ex.php?type=$cType&vars=5&dictId=${dictId}&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  static Future getSynonyms(int id, String w) async {
    String stoken = await getToken();
    String w2 = Uri.encodeComponent(w); // Кодирование параметра w
    var url = apiUrl + "get-synonyms-by-ai.php?id=$id&w=$w2&stoken=$stoken";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url), headers: _headers);
  }

  ///////////////////////////////////////////

  static setAuthToken2(String token) {
    _atoken = token;
    _headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_atoken',
    };
  }

  static Future saveTranslation2(Map tran) async {
    var url = apiUrl + "save-trans.php";
    debugPrint("URL= $url");
    debugPrint("MAP= " + tran.toString());
    //tran["id"] = tran["id"].toString();
    //tran["vocabId"] = tran["vocabId"].toString();
    return http.post(Uri.parse(url),
        body: json.encode(tran), headers: _postHeaders);
  }

  static Future removeTranslation(Map tran) async {
    var url = apiUrl + "remove-trans.php";
    debugPrint("URL= $url");
    tran["id"] = tran["id"].toString();
    tran["vocabId"] = tran["vocabId"].toString();
    tran["stoken"] = await getToken();
    debugPrint("MAP= " + tran.toString());
    return http.post(Uri.parse(url), body: json.encode(tran), headers: headers);
  }

  static Future removeExample(String id) async {
    var url = apiUrl + "remove-ex.php";
    debugPrint("URL= $url");
    var ex = Map();
    ex["id"] = id;
    ex["stoken"] = await getToken();
    return http.post(Uri.parse(url), body: ex);
  }

  static Future delClient() async {
    var url = apiUrl + "del-client.php";
    debugPrint("URL= $url");
    var user = Map();
    user["stoken"] = await getToken();
    return http.post(Uri.parse(url), body: json.encode(user), headers: headers);
  }

  static Future doForgetPassword(email) async {
    var url = apiUrl + "_do_forget_password.php";
    debugPrint("URL= $url");
    var user = Map();
    user["stoken"] = await getToken();
    user["email"] = email;
    return http.post(Uri.parse(url), body: json.encode(user), headers: headers);
  }

  static Future<String> getDeviceName() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        return '${info.manufacturer} ${info.model} (SDK ${info.version.sdkInt})';
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        return '${info.name} (${info.systemName} ${info.systemVersion})';
      } else if (Platform.isWindows) {
        final info = await deviceInfoPlugin.windowsInfo;
        return 'Windows ${info.computerName}';
      } else if (Platform.isMacOS) {
        final info = await deviceInfoPlugin.macOsInfo;
        return '${info.computerName} (macOS ${info.osRelease})';
      } else if (Platform.isLinux) {
        final info = await deviceInfoPlugin.linuxInfo;
        return 'Linux ${info.name ?? "unknown"}';
      } else {
        return 'Unknown platform';
      }
    } catch (e) {
      return 'Error getting device info: $e';
    }
  }
}

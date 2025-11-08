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

import 'state.dart';

// login
class API {
  static var unescape = HtmlUnescape();
  static const String apiUrl = "https://ms.afisha.news/";
  static var headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Bearer $sToken',
  };
  static String httpErr = "Internet request failed with status ";

  static var info = "info";
  static String appVersion = "";
  static String sToken = "";
  static String fcmToken = "";
  static String lang = "";

  static String calculateSHA512(String input) {
    var bytes = utf8.encode(input);
    var digest = sha512.convert(bytes);
    return digest.toString();
  }

  static Future<String> getLang() async {
    if (lang.length > 0) return lang;
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString('lang') ?? 'EN';
    return lang;
  }

  static Future<String> getToken() async {
    if (sToken.length > 0) return sToken;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var key = "token";
    sToken = prefs.getString(key) ?? "";
    if (sToken.length < 5) {
      sToken = randomAlphaNumeric(64);
      await prefs.setString(key, sToken);
    }
    return sToken;
  }

  static Future<String> getFbToken() async {
    try {
      if (!kIsWeb) {
        if (fcmToken.isNotEmpty) {
          debugPrint("Using cached FCM token");
        } else {
          debugPrint("Cached token not found, requesting new one");
          fcmToken = await FirebaseMessaging.instance.getToken() ?? "none";
        }
      }
    } catch (e) {
      API.log('Firebase get token error: ' + e.toString());
      fcmToken = await _retryGettingToken();
    }

    debugPrint("Firebase token=$fcmToken");
    return fcmToken;
  }

  static Future<String> _retryGettingToken() async {
    try {
      API.log('Retry getting token');
      await FirebaseMessaging.instance.deleteToken();
      fcmToken = "";
      await Future.delayed(const Duration(seconds: 2));
      fcmToken = await FirebaseMessaging.instance.getToken() ?? "none";
      API.log('Firebase get token (with retry): ' + fcmToken.toString());

      return fcmToken;
    } on Exception catch (e) {
      API.log('Firebase get token error (with retry): ' + e.toString());
      return "none";
    }
  }

  static Future auth() async {
    var url = apiUrl + "auth.php";
    debugPrint("URL= $url");

    Map params = Map();
    //params["sToken"] = await getToken();
    params["fcmToken"] = await getFbToken();
    params["lang"] = await getLang();
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: headers);
  }

  static Future login(String login, String password) async {
    var url = apiUrl + "login.php";
    debugPrint("URL= $url");
    Map params = Map();
    params["login"] = login;
    params["password"] = password;
    params["sToken"] = await getToken();
    params["fcmToken"] = await getFbToken();
    params["lang"] = await getLang();
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: headers);
  }

  static Future logout() async {
    await GoogleSignIn.instance.signOut();

    var url = apiUrl + "logout.php";
    debugPrint("URL= $url");
    Map params = Map();
    params["stoken"] = await getToken();
    await getToken();
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

  static Future getRooms(int page, String q, String sortMode) async {
    String stoken = await getToken();
    var url = apiUrl + "get-rooms.php?p=$page&sortMode=$sortMode";
    if (q.length > 0) url += "&q=$q";
    debugPrint("URL=$url");
    Map params = Map();
    params["page"] = page;
    params["sortMode"] = sortMode;
    if (q.length > 0) params["q"] = q;
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: headers);
  }

  static Future getRoom(int roomId) async {
    var url = apiUrl + "get-room.php?roomId=$roomId";
    debugPrint("URL=$url");
    Map params = Map();
    params["roomId"] = roomId;
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: headers);
  }

  static Future getProfile() async {
    var url = apiUrl + "get-profile.php";
    debugPrint("URL=$url");
    Map params = Map();
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: headers);
  }

  static Future getSex() async {
    var url = apiUrl + "get-sex.php";
    debugPrint("URL=$url");
    Map params = Map();
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: headers);
  }

  static Future getDelService() async {
    var url = apiUrl + "get-del-service.php";
    debugPrint("URL=$url");
    Map params = Map();
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: headers);
  }

  static Future putRoom(Map room) async {
    var url = apiUrl + "put-room.php";
    debugPrint("URL= $url");
    return http.post(Uri.parse(url), body: json.encode(room), headers: headers);
  }

  static Future putPhoto(Map photo) async {
    var url = apiUrl + "put-photo.php";
    debugPrint("URL= $url");
    return http.post(Uri.parse(url), body: json.encode(photo), headers: headers);
  }

  /// @todo implement delClient
  static Future delClient() async {
    Map params = Map();
    var url = apiUrl + "put-vocab.php";
    debugPrint("URL= $url");
    params['stoken'] = await getToken();
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: headers);
  }

  static Future getNPArea() async {
    var url = apiUrl + "get-np-area.php";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url));
  }

  static Future getNPCity(String? area) async {
    var url = apiUrl + "get-np-city.php?area=$area";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url));
  }

  static Future getNPWh(String? city) async {
    var url = apiUrl + "get-np-wh.php?city=$city";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url));
  }

  static Future getNPbyRef(String ref) async {
    var url = apiUrl + "get-np-by-ref.php?npWh=$ref";
    debugPrint("URL=$url");
    return http.get(Uri.parse(url));
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

  static Future putProfile(Map profile) async {
    var url = apiUrl + "put-profile.php";
    debugPrint("URL=$url");
    return http.post(Uri.parse(url),
        body: json.encode(profile), headers: headers);
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

// login
class API {
  static var unescape = HtmlUnescape();
  static const String apiUrl = "https://mysterioussanta.afisha.news/";

  static var info = "info";
  static String appVersion = "";
  static String sToken = "";
  static String fcmToken = "";
  static String lang = "";
  static String dbPhotoUrl =
      "https://mysterioussanta.afisha.news/photo.php?id=";

  static String calculateSHA512(String input) {
    var bytes = utf8.encode(input);
    var digest = sha512.convert(bytes);
    return digest.toString();
  }

  static Map<String, String> getHeaders() {
    //return 'Content-Type: application/json; charset=utf-8\nAuthorization: Bearer $sToken';
    Map<String, String> headers = Map();
    headers['Content-Type'] = 'application/json; charset=utf-8';
    headers['Authorization'] = 'Bearer $sToken';
    return headers;
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

  static Future queryBackend(String url, Map params) async {
    final endpoint = apiUrl + url;
    debugPrint("URL= $endpoint");
    final response = await http.post(Uri.parse(endpoint),
        body: json.encode(params), headers: getHeaders());
    if (response.statusCode != 200) {
      throw Exception("Internet request failed with status: " +
          response.statusCode.toString());
    }
    final result = jsonDecode(response.body);
    if (result is Map) if (result.containsKey('err')) {
      final err = result['err'];
      if (err != null && err is String && err.isNotEmpty) {
        throw Exception(err);
      }
    }
    return result;
  }

  static Future auth() async {
    Map params = Map();
    params["fcmToken"] = await getFbToken();
    params["lang"] = await getLang();
    return queryBackend("auth.php", params);
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
    return queryBackend("login.php", params);
  }

  static Future logout() async {
    return queryBackend("logout.php", {});
  }

  static Future log(String log) async {
    return queryBackend("log.php", {
      "stoken": await getToken(),
      "log": log + "|" + await getDeviceName() + "|" + appVersion
    });
  }

  static Future loginWith(Map params) async {
    var url = apiUrl + "login-with-google.php";
    debugPrint("URL= $url");
    String hh = await getToken();
    params["stoken"] = hh;
    params["type"] = params['provider'];
    params["device"] = await getDeviceName();
    params["fcmToken"] = await getFbToken();
    params["lang"] = await getLang();
    return http.post(Uri.parse(url),
        body: json.encode(params), headers: getHeaders());
  }

  static Future loginWithGoogle(Map params) async {
    params["stoken"] = await getToken();
    params["device"] = await getDeviceName();
    params["fcmToken"] = await getFbToken();
    params["lang"] = await getLang();
    return queryBackend("login-with-google.php", params);
  }

  static Future getRooms(int page, String q, String sortMode) async {
    Map params = Map();
    params["page"] = page;
    params["sortMode"] = sortMode;
    if (q.length > 0) params["q"] = q;
    return queryBackend("get-rooms.php", params);
  }

  static Future getRoom(String roomSecret) async {
    return queryBackend("get-room.php", {"roomSecret": roomSecret});
  }

  static Future getProfile(int id) async {
    return queryBackend("get-profile.php", {"id": id});
  }

  static Future getSex() async {
    return queryBackend("get-sex.php", {});
  }

  static Future getDelService() async {
    return queryBackend("get-del-service.php", {});
  }

  static Future getWishlist() async {
    return queryBackend("get-wishlist.php", {});
  }

  static Future putRoom(Map room) async {
    return queryBackend("put-room.php", room);
  }

  static Future delRoom(int roomId) async {
    return queryBackend("del-room.php", {"roomId": roomId});
  }

  static Future putPhoto(Map photo) async {
    return queryBackend("put-photo.php", photo);
  }

  static Future delPhoto() async {
    return queryBackend("del-photo.php", {});
  }

  static Future delWishlist(int id) async {
    return queryBackend("del-wishlist.php", {"id": id});
  }

  static Future getWish(int id) async {
    return queryBackend("get-wish.php", {"id": id});
  }

  static Future getRcpProfile(int id) async {
    return queryBackend("get-rcp-profile.php", {"id": id});
  }

  static Future getWishListAI(Map params) async {
    return queryBackend("get-wish-with-ai.php", params);
  }

  static Future getLanguages() async {
    return queryBackend("lang.json", {});
  }

  static Future delWish(int id) async {
    return queryBackend("del-wish.php", {"id": id});
  }

  static Future doRandomize(int id) async {
    return queryBackend("do-randomize.php", {"roomId": id});
  }

  static Future delFromRoom(int roomId, int userId) async {
    return queryBackend(
        "del-from-room.php", {"roomId": roomId, "userId": userId});
  }

  static Future putWish(Map wish) async {
    return queryBackend("put-wish.php", wish);
  }

  static Future doEnroll(Map params) async {
    return queryBackend("do-enroll.php", params);
  }

  /// @todo implement delClient
  static Future delClient() async {
    return queryBackend("del-client.php", {});
  }

  static Future getNPArea() async {
    return queryBackend("get-np-area.php", {});
  }

  static Future getNPCity(String? area) async {
    return queryBackend("get-np-city.php", {"area": area});
  }

  static Future getNPWh(String? city) async {
    return queryBackend("get-np-wh.php", {"city": city});
  }

  static Future getNPbyRef(String ref) async {
    return queryBackend("get-np-by-ref.php", {"npWh": ref});
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
    return queryBackend("put-profile.php", profile);
  }

  static Future forgetPassword(String email) async {
    return queryBackend("do-forget-pas.php", {"email": email});
  }
}

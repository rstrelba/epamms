import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:epamms/state.dart';
import 'package:epamms/ui/snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../api.dart';
import 'home.dart';
import '../ii.dart';

class LoginUI extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _LoginState();
}

// Used for controlling whether the user is loggin or creating an account
enum FormType { login, register }

class _LoginState extends State<LoginUI> {
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  bool _isLogging = false;
  bool _isLoaded = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocusNode = FocusNode();

  _LoginState() {}

  @override
  void initState() {
    super.initState();
    //
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();

    _loadLogin();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadLogin() async {
    FirebaseAnalytics.instance.logEvent(name: 'login');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailCtrl.text = prefs.getString('login') ?? "";
      _isLoaded = true;
    });
    if (_emailCtrl.text.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      });
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register or login".ii()),
        centerTitle: true,
      ),
      //resizeToAvoidBottomPadding: false,
      body: Stack(
        children: [
          _buildTextFields(context),
        ],
      ),
    );
  }

  Widget _buildTextFields(BuildContext context) {
    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    AppState appState = Provider.of<AppState>(context, listen: false);
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Container(
          margin: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.emailAddress,
                  validator: (email) => email == null ||
                          !EmailValidator.validate(email) ||
                          email.isEmpty
                      ? 'Enter a valid email'.ii()
                      : null,
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                      labelText: 'Email'.ii(),
                      prefixIcon: const Icon(EvaIcons.emailOutline)),
                  onFieldSubmitted: (value) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    });
                  },
                ),
              ),
              Container(
                child: TextFormField(
                  validator: (password) => password == null ||
                          password.length < 3 ||
                          password.isEmpty
                      ? 'Enter a valid password'.ii()
                      : null,
                  controller: _passwordCtrl,
                  decoration: InputDecoration(
                      labelText: "Password".ii(),
                      prefixIcon: const Icon(EvaIcons.lockOutline)),
                  obscureText: true,
                  focusNode: _passwordFocusNode,
                  onFieldSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState!.validate()) {
                      _doLogin(context);
                    } else {
                      showErrSnackBar(
                          context, "Enter a valid email and password".ii());
                    }
                  },
                ),
              ),
              Container(
                height: 10,
              ),
              Center(
                child: Container(
                  width: 200,
                  child: Column(
                    children: [
                      SignInButton(
                        Buttons.Email,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (_formKey.currentState!.validate()) {
                            _doLogin(context);
                          } else {
                            showErrSnackBar(context,
                                "Enter a valid email and password".ii());
                          }
                        },
                      ),
                      Visibility(
                          visible: _isLogging,
                          child: const CircularProgressIndicator()),
                      Container(height: 20),
                      Visibility(
                        visible: GetPlatform.isIOS,
                        child: SignInButton(
                          appState.themeMode == ThemeMode.dark
                              ? Buttons.AppleDark
                              : Buttons.Apple,
                          onPressed: () {
                            _doLoginWithApple();
                          },
                        ),
                      ),
                      Visibility(
                        visible: true, //GetPlatform.isAndroid,
                        child: SignInButton(
                          appState.themeMode == ThemeMode.dark
                              ? Buttons.GoogleDark
                              : Buttons.Google,
                          onPressed: () {
                            _doLoginWithGoogle();
                          },
                        ),
                      ),
                      Visibility(
                        visible: false, //Platform.isAndroid,
                        child: SignInButton(
                          appState.themeMode == ThemeMode.dark
                              ? Buttons.Facebook
                              : Buttons.Facebook,
                          onPressed: () {
                            _doLoginWithFacebook();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(height: 20),
              ElevatedButton(
                child: Text("I forgot my password".ii()),
                onPressed: _doForgetPassword,
              ),
              //Expanded(child: Container()),
              ListTile(
                title: Text(appState.getVersion()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _doForgetPassword() async {
    //
    var email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError("Enter your e-mail!".ii());
      return;
    }

    if (!EmailValidator.validate(email)) {
      _showError("Enter a valid e-mail!".ii());
      return;
    }

    //@todo implement doForgetPassword
    //await API.doForgetPassword(email);
    _showNote("Wait for the e-mail with your password!".ii());
  }

  Future<void> _showError(err) {
    return showDialog<void>(
      //barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'.ii()),
          content: Text(err),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Close'.ii()),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showNote(err) {
    return showDialog<void>(
      //barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Message'.ii()),
          content: Text(err),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Close'.ii()),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _doLogin(BuildContext context) async {
    final _login = _emailCtrl.text.trim();
    try {
      setState(() {
        _isLogging = true;
      });

      final state = Provider.of<AppState>(context, listen: false);
      final res = await API.login(_login, _passwordCtrl.text.trim());
      state.clientId = res['clientId'];
      state.clientLogin = res['login'];
      if (state.clientId > 0) {
        // save new token
        showSnackBar(context, 'Logged in successfully');
        API.sToken = res['stoken'];
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", API.sToken);
        await prefs.setString("login", _login);

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomeUI()));
      } else {
        String err = res['err'].toString();
        err = (err.length > 0) ? err : "Something goes wrong!";
        throw Exception(err);
      }
    } catch (e) {
      showErrSnackBar(context, e.toString());
      API.log('Login error: $e , $_login');
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  void _doLoginWithGoogle() async {
    const List<String> scopes = <String>['email', 'profile', 'openid'];
    GoogleSignInAccount? user;

    try {
      setState(() {
        _isLogging = true;
      });

      const String serverClientId =
          "405952516189-eo8t2ijs6r4p1ag1oeqrjqv6c72jcma5.apps.googleusercontent.com";

      final _googleSignIn = GoogleSignIn.instance;
      await _googleSignIn.initialize(
        serverClientId: serverClientId,
      );

      // try to use lightweight auth
      var _maybeUser = await _googleSignIn.attemptLightweightAuthentication();
      if (_maybeUser != null) {
        user = _maybeUser;
      } else {
        // if lightweight authentication failed, show the login dialog
        user = await _googleSignIn.authenticate(scopeHint: scopes);
      }

      // get ID token for verification on the backend
      final GoogleSignInAuthentication googleAuth = await user.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
            "Failed to get Google ID token. Check the correctness of serverClientId.");
      }

      debugPrint("Google user: ${user.email}");
      debugPrint("ID Token получен: ${idToken.substring(0, 30)}...");

      String? email = user.email;
      var displayName = user.displayName;
      var photoUrl = user.photoUrl;

      if (email == null || email.isEmpty) {
        throw Exception("Failed to get email from Google");
      }

      Map params = Map();
      params['login'] = email;
      params['name'] = displayName ?? '';
      params['photoUrl'] = photoUrl ?? '';
      params['provider'] = "google";
      params['idToken'] = idToken; // ID token
      debugPrint("params=" + params.toString());

      var res = await API.loginWithGoogle(params);
      final state = Provider.of<AppState>(context, listen: false);
      state.clientId = res['clientId'] ?? 0;
      state.clientLogin = res['login'] ?? email;

      if (state.clientId > 0) {
        // save new token
        showSnackBar(context, 'Successfully logged in with Google'.ii());
        API.sToken = res['stoken'] ?? '';
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", API.sToken);
        await prefs.setString("login", email);

        Navigator.pushReplacement(
            context, CupertinoPageRoute(builder: (_) => HomeUI()));
      } else {
        String err = res['err']?.toString() ?? "Что-то пошло не так!";
        throw Exception(err);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Улучшаем сообщения об ошибках для пользователя
        if (errorMessage.contains("network_error") ||
            errorMessage.contains("NetworkError")) {
          errorMessage = "Network error. Check your internet connection.";
        } else if (errorMessage.contains("sign_in_canceled")) {
          errorMessage = "Login canceled";
          return; // Don't show error if user simply canceled the login
        }
        showErrSnackBar(context, errorMessage);
      }
      API.log('Google login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
      }
    }
  }

  //https://facebook.meedu.app/docs/7.x.x/login
  //https://developers.facebook.com/apps/4234554869984211/dashboard/
  void _doLoginWithFacebook() async {
    //
    final LoginResult result = await FacebookAuth.instance.login(permissions: [
      'email'
    ]); // by default we request the email and the public profile
// or FacebookAuth.i.login()
    if (result.status == LoginStatus.success) {
      // you are logged
      // TODO: Implement Facebook login with token
      // final AccessToken accessToken = result.accessToken!;
    } else {
      print(result.status);
      print(result.message);
    }
  }

  void _doLoginWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      UserCredential? userCredential;
      try {
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      } catch (e) {
        debugPrint('Firebase Auth error: $e');
        API.log('Firebase Auth error (Apple): $e');
        showErrSnackBar(context, 'Authentication error: $e');
        return;
      }
      User? user = userCredential.user;
      String? email = user?.email;

      if (email != null) {
        Map params = Map();
        params['login'] = email;
        params['provider'] = "apple";

        var response = await API.loginWith(params);
        if (response.statusCode != 200)
          throw Exception(API.httpErr + response.statusCode.toString());
        debugPrint("resp=" + response.body.toString());
        var res = jsonDecode(response.body.toString());

        // тут могут быть 3 варианта
        // clientId == 0 - это значит что неверно введен логин или пароль
        // сclientId>0 и dict пустой , надо переходить на WelcomeUI
        // clientId>0 и dict не пустой , надо переходить на HomeUI
        final state = Provider.of<AppState>(context, listen: false);
        await state.tryToAuth();
        if (state.clientId > 0) {
          // save new token
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => HomeUI()));
        } else {
          String err = res['err'].toString();
          err = (err.length > 0) ? err : "Something goes wrong!";
          throw Exception(err);
        }
      }
    } catch (e) {
      showErrSnackBar(context, e.toString());
      API.log('Apple login error: $e');
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }
}

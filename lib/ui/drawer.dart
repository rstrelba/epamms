import 'dart:async';

import 'package:epamms/api.dart';
import 'package:epamms/ui/home.dart';
import 'package:epamms/ui/profile.dart';
import 'package:epamms/ui/roomview.dart';
import 'package:epamms/ui/settings.dart';
import 'package:epamms/ui/snack_bar.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ii.dart';
import '../state.dart';
import 'login.dart';
import 'about.dart';
import 'package:provider/provider.dart';

class DrawerUI extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DrawlerState();

  final Function() onUpdate;

  DrawerUI({required this.onUpdate});
}

class _DrawlerState extends State<DrawerUI>
    with SingleTickerProviderStateMixin {
  bool isReady = false;
  String version = '';
  String code = '';

  final List<String> frames = [
    'images/logo-an-1.png',
    'images/logo-an-2.png',
    'images/logo-an-3.png',
  ];

  int frameIndex = 0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    _load();
    _startBlinkingLoop();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _startBlinkingLoop() {
    timer = Timer.periodic(const Duration(seconds: 5), (t) {
      // Blink 3 frames for 100ms each
      for (int i = 0; i < frames.length; i++) {
        Future.delayed(Duration(milliseconds: 100 * i), () {
          if (mounted) {
            setState(() => frameIndex = i);
          }
        });
      }
      // Return to first frame after blinking
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => frameIndex = 0);
        }
      });
    });
  }

  Future _load() async {
    //
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AppState>(context);
    return Drawer(
        child: ListView(
      padding: EdgeInsets.zero,
      //shrinkWrap: true,
      children: [
        AnimatedSwitcher(
          duration: const Duration(seconds: 5),
          child: Container(
              height: 200,
              decoration: BoxDecoration(
                  //border: Border(                  bottom: Divider.createBorderSide(context, color: Colors.white, width: 0.0),                ),
                  boxShadow: const [],
                  //color: Colors.white,
                  image: DecorationImage(
                      image: AssetImage(frames[frameIndex]),
                      fit: BoxFit.fitHeight)),
              child: Container()),
        ),
        state.clientId > 0
            ? ExpansionTile(
                key: GlobalKey(),
                leading: Icon(Icons.lock_open),
                title: Container(
                    //height: 20,
                    child: Text(
                  state.clientLogin.toLowerCase(),
                )),
                initiallyExpanded: state.isExpandedLogin,
                onExpansionChanged: (val) => state.isExpandedLogin = val,
                children: [
                    ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Profile'.ii()),
                      onTap: () {
                        //Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProfileUI(isReadOnly: false, id: 0)));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.logout_outlined),
                      title: Text('Logout'.ii()),
                      onTap: () async {
                        await _logout(context);
                        //Navigator.pop(context);
                        Navigator.pushReplacement(context,
                            CupertinoPageRoute(builder: (_) => HomeUI()));
                      },
                    ),
                  ])
            : ListTile(
                leading: Icon(Icons.person_outline),
                title: Text(
                  'Login'.ii(),
                  style: const TextStyle(fontSize: 20),
                ),
                subtitle: Text(
                  'Login or register to your account'.ii(),
                  style: const TextStyle(fontSize: 10),
                ),
                onTap: () {
                  //Navigator.pop(context);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => LoginUI()));
                },
              ),

        ListTile(
          leading: Icon(Icons.qr_code),
          title: Text(
            'QR code for room'.ii(),
          ),
          onTap: () async {
            final result = await SimpleBarcodeScanner.scanBarcode(context);
            debugPrint(result.toString());
            if (result != null) {
              // parse URL
              Uri uri = Uri.parse(result);
              debugPrint('QR code URI: ${uri.toString()}');
              String? idParam =
                  uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
              debugPrint('Room ID: ${idParam}');
              if (idParam == null) {
                // id not found, do nothing or show error
                showErrSnackBar(context, 'QR code is not valid');
                return;
              }
              //Navigator.pop(context);
              FirebaseAnalytics.instance.logEvent(name: 'drawer_qr_scan');
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RoomViewUI(roomSecret: idParam)));
            }
          },
        ),
        ListTile(
          leading: Icon(EvaIcons.settings2Outline),
          title: Text(
            'Settings'.ii(),
          ),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => SettingsUI()));
          },
        ),
        ListTile(
          leading: Icon(Icons.info_outline),
          title: Text(
            'About'.ii(),
          ),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => AboutUI()));
          },
        ),
        ListTile(
          //leading: Icon(EvaIcons.logOut),
          trailing: Image.asset("images/tg.png"),
          subtitle: Text(
            "Communication and support".ii(),
            style: const TextStyle(fontSize: 10),
          ),
          title: Text('Telegram group'.ii()),
          onTap: () async {
            final url = Uri.parse("tg://resolve?domain=mysterioussanta");
            //final url = Uri.parse("https://t.me/mysterioussanta");

            await launchUrl(
              url,
              //mode: LaunchMode.externalApplication,
            );
          },
        ),

        ListTile(
            title: Text('Delete account ...'.ii()),
            onTap: () async {
              _delAccount(context);
            }),
        //Expanded(child: Container()),
        ListTile(
          title: Text(state.getVersion()),
        ),
        Center(child: Text('Developed for EPAM CAMPUS 2025')),
        Center(child: Image.asset('images/epam.png', width: 200, height: 200)),
        SizedBox(height: 20),
      ],
    ));
  }

  Future<void> _delAccount(BuildContext context) async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      if (state.clientId == 0)
        throw Exception('You are not logged in to delete account');
      if (!await showYesNoDialog(
          context, 'Are you sure you want to delete your account?'.ii())) {
        return;
      }
      await API.delClient();
      showSnackBar(context, 'Account deleted successfully');
      await Future.delayed(const Duration(seconds: 3));
      _logout(context);
    } catch (e) {
      showErrSnackBar(context, e.toString());
    }
  }

  Future<void> _logout(BuildContext context) async {
    showSnackBar(context, 'Logged out successfully');
    final state = Provider.of<AppState>(context, listen: false);
    try {
      await API.logout();
      state.clientId = 0;
      state.clientLogin = '';
      API.sToken = '';
      GoogleSignIn.instance.signOut();
      Navigator.pop(context);
      Navigator.pushReplacement(
          context, CupertinoPageRoute(builder: (_) => HomeUI()));
    } catch (e) {
      showErrSnackBar(context, e.toString());
    }
  }
}

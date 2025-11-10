import 'package:epamms/api.dart';
import 'package:epamms/ui/home.dart';
import 'package:epamms/ui/profile.dart';
import 'package:epamms/ui/settings.dart';
import 'package:epamms/ui/snack_bar.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../ii.dart';
import '../state.dart';
import 'login.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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
        Container(
            height: 200,
            decoration: const BoxDecoration(
                //border: Border(                  bottom: Divider.createBorderSide(context, color: Colors.white, width: 0.0),                ),
                boxShadow: [],
                //color: Colors.white,
                image: DecorationImage(
                    image: AssetImage("images/logo1.png"),
                    fit: BoxFit.fitHeight)),
            child: Container()),
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
                        Navigator.pop(context);
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => ProfileUI()));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.logout_outlined),
                      title: Text('Logout'.ii()),
                      onTap: () async {
                        await _logout(context);
                        Navigator.pop(context);
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
                  Navigator.pop(context);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => LoginUI()));
                },
              ),

        ListTile(
          leading: Icon(EvaIcons.settings2Outline),
          title: Text(
            'Settings'.ii(),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => SettingsUI()));
          },
        ),

        ListTile(
            title: Text('Delete account ...'.ii()),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Warning'.ii()),
                    content: Text(
                        'Are you sure you want to delete your account?'.ii()),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('No'.ii()),
                      ),
                      TextButton(
                        onPressed: () async {
                          var response = await API.delClient();
                          debugPrint(
                              "Delete account: " + response.body.toString());
                          Navigator.pop(context);
                          Navigator.pushReplacement(context,
                              CupertinoPageRoute(builder: (_) => LoginUI()));
                        },
                        child: Text('Yes'.ii()),
                      ),
                    ],
                  );
                },
              );
              //return result;

              //Navigator.pop(context);
            }),
        //Expanded(child: Container()),
        ListTile(
          title: Text(state.getVersion()),
          onTap: () {
            //
          },
        ),
      ],
    ));
  }

  Future<void> _logout(BuildContext context) async {
    showSnackBar(context, 'Logged out successfully');
    final state = Provider.of<AppState>(context, listen: false);
    state.clientId = 0;
    await API.logout();

    Navigator.pop(context);
    Navigator.pushReplacement(
        context, CupertinoPageRoute(builder: (_) => HomeUI()));
  }
}

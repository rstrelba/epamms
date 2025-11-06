import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'api.dart';
import '../ii.dart';
import '../state.dart';
import 'login.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:url_launcher/url_launcher.dart';

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

  Future _saveDict(int _dictId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("dictId", _dictId);
  }
}

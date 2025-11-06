import 'dart:convert';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import 'home.dart';
import '../state.dart';
import '../ii.dart';

class RoomUI extends StatefulWidget {
  final int roomId;
  @override
  State<StatefulWidget> createState() => _RoomState();
  RoomUI({super.key, required this.roomId});
}

class _RoomState extends State<RoomUI> {
  bool _isLoading = true;
  late TextEditingController _nameController;
  late TextEditingController _myLangController;
  late TextEditingController _dictLangController;
  String _myLang = '';
  String _dictLang = '';
  List<dynamic> langs = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _myLangController = TextEditingController();
    _dictLangController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _myLangController.dispose();
    _dictLangController.dispose();
    super.dispose();
  }

  void _load() async {
    var response = await API.getLangs();
    // TODO: обработать response и заполнить langs
    setState(() {
      _isLoading = false;
    });
  }

  void _showErr(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("New room".ii()),
          centerTitle: true,
        ),
        floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'doSave',
                onPressed: () => _doSave(context),
                mini: false,
                elevation: 10,
                //child: Icon(FontAwesomeIcons.cartPlus),
                child: Icon(EvaIcons.checkmark),
              ),
              Container(
                height: 10,
              ),
              Visibility(
                visible: widget.roomId > 0,
                child: FloatingActionButton(
                  heroTag: 'doRemove',
                  onPressed: () => _doRemove(context),
                  mini: true,
                  elevation: 10,
                  child: Icon(EvaIcons.trash2Outline),
                ),
              ),
              Container(
                height: 0,
              )
            ]),
        body: _buildForm(context));
  }

  Widget _buildForm(context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    var state = Provider.of<AppState>(context);

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
                autofocus: true,
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name of dictionary',
                )),
            Container(
              height: 20,
            ),
            Container(
                child: TypeAheadField(
              textFieldConfiguration: TextFieldConfiguration(
                  controller: _myLangController,
                  decoration: InputDecoration(
                      //border: OutlineInputBorder(),
                      labelText: 'My native language')),
              suggestionsCallback: (pattern) async {
                var found = [];
                if (pattern.isEmpty) return found;
                for (var e in langs) {
                  String name = e['name'].toString().toLowerCase();
                  String nativeName = e['nativeName'].toString().toLowerCase();
                  if (name.contains(pattern.toLowerCase()) ||
                      nativeName.contains(pattern.toLowerCase())) {
                    Map m = {};
                    m['code'] = e['code'];
                    m['name'] = name;
                    m['nativeName'] = nativeName;
                    found.add(m);
                  }
                }

                return found;
              },
              itemBuilder: (context, suggestion) {
                var m = suggestion as Map;
                return ListTile(
                    title: Text(m['name']), subtitle: Text(m['nativeName']));
              },
              onSuggestionSelected: (suggestion) {
                var m = suggestion as Map;
                _myLangController.text = m['name'];
                _myLang = m['code'].toString();
              },
            )),
            Container(
              height: 20,
            ),
            Container(
                child: TypeAheadField(
              textFieldConfiguration: TextFieldConfiguration(
                  controller: _dictLangController,
                  autofocus: true,
                  decoration: InputDecoration(
                      //border: OutlineInputBorder(),
                      labelText: 'Dictionary language')),
              suggestionsCallback: (pattern) async {
                var found = [];
                if (pattern.isEmpty) return found;
                for (var e in langs) {
                  String name = e['name'].toString().toLowerCase();
                  String nativeName = e['nativeName'].toString().toLowerCase();
                  if (name.contains(pattern.toLowerCase()) ||
                      nativeName.contains(pattern.toLowerCase())) {
                    Map m = {};
                    m['code'] = e['code'];
                    m['name'] = name;
                    m['nativeName'] = nativeName;
                    found.add(m);
                  }
                }

                return found;
              },
              itemBuilder: (context, suggestion) {
                var m = suggestion as Map;
                return ListTile(
                    title: Text(m['name']), subtitle: Text(m['nativeName']));
              },
              onSuggestionSelected: (suggestion) {
                var m = suggestion as Map;
                _dictLangController.text = m['name'];
                _dictLang = m['code'].toString();
              },
            )),
          ],
        ),
      ),
    );
  }

  Future _doSave(BuildContext context) async {
    //
    var state = Provider.of<AppState>(context, listen: false);

    if (_nameController.text.isEmpty) {
      _showErr("Enter a name of your dictionary!");
      return;
    }
    if (_myLang.isEmpty) {
      _showErr("Choose your native language!");
      return;
    }
    if (_dictLang.isEmpty) {
      _showErr("Choose your dictionary language!");
      return;
    }
    //
    Map dict = {};
    dict['id'] = widget.roomId;
    dict['dictName'] = _nameController.text;
    dict['myLang'] = _myLang;
    dict['dictLang'] = _dictLang;

    try {
      var response = await API.putDict(dict);
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      debugPrint(response.body);
      var res = jsonDecode(response.body);

      if (res['id'] > 0) {
        //state.roomId = res['id'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        //prefs.setInt('dictId', state.roomId); // switch to a new dict

        await state.tryToAuth();
        Navigator.of(context).pop();
      } else {
        var err = "Something goes wrong!";
        if (res['err'].toString().isNotEmpty) err = res['err'].toString();
        throw Exception(err);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: e.toString(),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  Future _doRemove(BuildContext context) async {
    //
    var state = Provider.of<AppState>(context);
    showDialog<void>(
      //barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warning'),
          content: Text("Are you sure to remove this dictionary?"),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Yes'),
              onPressed: () async {
                Map dict = {};
                dict['id'] = widget.roomId;

                var response = await API.delDict(dict);
                debugPrint(response.body);
                var res = jsonDecode(response.body);
              },
            ),
            ElevatedButton(
              child: Text('No'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    ).then((value) => Navigator.pushReplacement(
        context, CupertinoPageRoute(builder: (_) => HomeUI())));
  }
}

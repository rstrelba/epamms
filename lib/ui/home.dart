import 'dart:convert';

import 'package:epamms/api.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../state.dart';
import 'room.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drawer.dart';
import '../ii.dart';

class HomeUI extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeUI> {
  bool _isLoading = true;
  int page = 0;
  var rooms = [];
  ScrollController? scrollCtrl;
  var _sCtrl = TextEditingController();
  String query = "";
  var sFocus = FocusNode();
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  FirebaseAnalytics? _analytics;

  // Безопасный геттер для FirebaseAnalytics
  FirebaseAnalytics? get analytics {
    try {
      _analytics ??= FirebaseAnalytics.instance;
      return _analytics;
    } catch (e) {
      debugPrint('FirebaseAnalytics not available: $e');
      return null;
    }
  }

  GlobalKey buttonKey = GlobalKey(); // Ключ для кнопки
  bool searchVisible = false;
  String sortMode = 'last';

  @override
  void dispose() {
    sFocus.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    scrollCtrl = ScrollController();
    scrollCtrl!.addListener(_scrollListener);
    if (!kIsWeb)
      initFB();
    else
      _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  void initFB() async {
    //
    if (!GetPlatform.isWeb) {
      try {
        await analytics?.logScreenView(screenName: 'home');
      } catch (e) {
        debugPrint('Failed to log screen view: $e');
      }
    }

    await API.log("initFB");
    Future.delayed(Duration.zero, () async {
      //
      try {
        _load();
      } catch (e) {
        await API.log("initFB ex=${e.toString()}");
      }
    });
  }

  Future _load() async {
    setState(() {
      _isLoading = true;
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    sortMode = prefs.getString('sortMode') ?? "last";
    try {
      final response = await API.getRooms(page, query, sortMode);
      if (!mounted) return;
      if (response.statusCode != 200)
        throw Exception(API.httpErr + response.statusCode.toString());
      if (page == 0) rooms.clear();
      debugPrint('response.body=${response.body}');
      if (page == 0) rooms.clear();
      rooms.addAll(jsonDecode(response.body));
    } on Exception catch (e) {
      debugPrint('getRooms error=${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void onUpdate() {
    page = 0;
    _load();
  }

  _scrollListener() {
    if (page == -1) return;
    var curItemPos = scrollCtrl!.position.pixels;
    var maxItemPos = scrollCtrl!.position.maxScrollExtent;

    if (curItemPos >= maxItemPos) {
      page++;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Are you sure?'.ii()),
            content: Text('Do you want to exit the app?'.ii()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'.ii()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  SystemNavigator.pop();
                },
                child: Text('Yes'.ii()),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Mysterious Santa".ii()),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  //
                  setState(() {
                    searchVisible = !searchVisible;
                    if (!searchVisible) {
                      page = 0;
                      query = "";
                      _sCtrl.text = query;
                      _load();
                    } else {
                      sFocus.requestFocus();
                    }
                  });
                },
              ),
            ),
            Builder(
                builder: (context) => PopupMenuButton(
                      //offset: Offset(0.0, 0.0),
                      offset: const Offset(0, 100),
                      icon: const Icon(Icons.sort_outlined),
                      onSelected: ((value) async {
                        String cmd = value.toString();
                        debugPrint(cmd);
                        setState(() {
                          sortMode = value.toString();
                        });

                        debugPrint('sort mode=$sortMode');

                        SharedPreferences pref =
                            await SharedPreferences.getInstance();
                        pref.setString('sortMode', sortMode);
                        page = 0;
                        _load();

                        //_refreshAll();
                      }),
                      itemBuilder: (context) {
                        var list = <PopupMenuEntry<Object>>[];

                        list.add(CheckedPopupMenuItem(
                          checked: sortMode == 'last',
                          value: 'last',
                          child: Text('Last'.ii()),
                        ));
                        list.add(CheckedPopupMenuItem(
                          checked: sortMode == 'first',
                          value: 'first',
                          child: Text('First'.ii()),
                        ));
                        list.add(CheckedPopupMenuItem(
                          checked: sortMode == 'lr',
                          value: 'lr',
                          child: Text('Last Reminded'.ii()),
                        ));

                        return list;
                      },
                    )),
          ],
        ),
        body: _buildHome(context),
        drawer: DrawerUI(onUpdate: onUpdate),
        floatingActionButton: FloatingActionButton(
          heroTag: "new_room",
          onPressed: _newRoom,
          tooltip: 'New room'.ii(),
          key: buttonKey,
          child: const Icon(Icons.add),
          //backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  _newRoom() async {
    var res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => RoomUI(roomId: 0),
      ),
    );
    setState(() {
      //words.insert(0, newVoc);
      page = 0;
      _load();
    });
  }

  Widget _buildHome(BuildContext context) {
    //
    var state = Provider.of<AppState>(context, listen: false);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: () async {
        page = 0;
        _load();
      },
      child: Container(
        margin: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            Visibility(
              visible: searchVisible,
              child: TextField(
                enableInteractiveSelection: true,
                autofocus: false,
                focusNode: sFocus,
                decoration: InputDecoration(
                  labelText: 'Word to search'.ii(),
                  suffixIcon: IconButton(
                    onPressed: (() {
                      page = 0;
                      query = _sCtrl.text;
                      _load();
                    }),
                    icon: const Icon(Icons.search),
                  ),
                ),
                controller: _sCtrl,
                onChanged: (String? q) async {
                  //
                  debugPrint('change=$q');
                  if (q!.length >= 2) {
                    //
                    query = q;
                    _load();
                  }
                },
                onSubmitted: ((q) {
                  page = 0;
                  query = q;
                  _load();
                }),
              ),
            ),
            Expanded(
              child: rooms.length > 0
                  ? Scrollbar(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          return _buildRoom(context, index);
                        },
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(50),
                      child: Text('No rooms found 😔'.ii(),
                          style: const TextStyle(fontSize: 20))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoom(BuildContext context, int index) {
    final state = Provider.of<AppState>(context, listen: false);
    final room = rooms[index];
    final title = room['title'];
    final id = room['id'];
    final createTs = room['ts'];
    final desc = room['desc'];
    final isOwner = room['isOwner'];
    final clientsCount = room['clientsCount'];
    final isParticipant = room['isParticipant'];
    return Card(
      elevation: 5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            key: Key(id.toString()),
            title: Text(title, style: const TextStyle(fontSize: 20)),
            subtitle: Text(createTs.toString()),
            trailing: Column(
              children: [
                Text(clientsCount.toString()),
                isOwner ? Icon(Icons.person) : Container(),
              ],
            ),
            leading:
                Icon(isParticipant ? Icons.handshake_outlined : Icons.close),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => RoomUI(roomId: id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:epamms/api.dart';
import 'package:epamms/ui/roomview.dart';
import 'package:epamms/ui/snack_bar.dart';
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
  bool noMoreData = false;
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
    FirebaseAnalytics.instance.logEvent(name: 'rooms');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    sortMode = prefs.getString('sortMode') ?? "all";
    try {
      final response = await API.getRooms(page, query, sortMode);
      if (!mounted) return;
      if (response.statusCode != 200)
        throw Exception(API.httpErr + response.statusCode.toString());
      if (page == 0) rooms.clear();
      debugPrint('response.body=${response.body}');
      if (page == 0) rooms.clear();
      final res = jsonDecode(response.body);
      rooms.addAll(res);
      if (rooms.length < 100) noMoreData = true;
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
      if (noMoreData) return;
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
                          checked: sortMode == 'all',
                          value: 'all',
                          child: Text('All rooms'.ii()),
                        ));
                        list.add(CheckedPopupMenuItem(
                          checked: sortMode == 'my_rooms',
                          value: 'my_rooms',
                          child: Text('My rooms only'.ii()),
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
          onPressed: () => _newRoom(context),
          tooltip: 'New room'.ii(),
          key: buttonKey,
          child: const Icon(Icons.add),
          //backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  _newRoom(BuildContext context) async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.clientId == 0) {
      showErrSnackBar(context, 'You are not logged in'.ii());
      return;
    }
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
              visible: false,
              child: TextField(
                enableInteractiveSelection: true,
                autofocus: false,
                focusNode: sFocus,
                decoration: InputDecoration(
                  labelText: 'Room to search (not implemented yet)'.ii(),
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
                      child: Center(
                        child: Text('No rooms found 😔'.ii(),
                            style: const TextStyle(fontSize: 20)),
                      )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoom(BuildContext context, int index) {
    //final state = Provider.of<AppState>(context, listen: false);
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
            title: Text(title, style: const TextStyle(fontSize: 18)),
            subtitle: Text(
                createTs.toString() + ' (${clientsCount.toString()} players)'),
            trailing: SizedBox(
              width: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Text(clientsCount.toString()),
                  if (isOwner) Icon(Icons.person, size: 20),
                ],
              ),
            ),
            leading: isParticipant
                ? SizedBox(
                    width: 40,
                    height: 40,
                    child:
                        Image.asset('images/star.png', width: 32, height: 32),
                  )
                : const SizedBox(width: 40),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => RoomViewUI(roomId: id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

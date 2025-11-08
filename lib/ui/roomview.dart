import 'dart:convert';

import 'package:epamms/ui/room.dart';
import 'package:epamms/ui/snack_bar.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import 'home.dart';
import '../state.dart';
import '../ii.dart';

class RoomViewUI extends StatefulWidget {
  final int roomId;
  @override
  State<StatefulWidget> createState() => _RoomViewState();
  RoomViewUI({super.key, required this.roomId});
}

class _RoomViewState extends State<RoomViewUI> {
  bool _isLoading = true;
  int roomId = 0;
  bool isVisible = false;
  String title = '';
  String description = '';
  String exchangeDate = '';
  bool isOwner = false;
  int clientsCount = 0;
  bool isParticipant = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _load() async {
    try {
      final response = await API.getRoom(widget.roomId);
      if (!mounted) return;
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      debugPrint("response.body=" + response.body);
      final res = jsonDecode(response.body);
      roomId = res['roomId'];
      title = res['title'];
      description = res['desc'];
      exchangeDate = res['exchangeDate'];
      isOwner = res['isOwner'];
      clientsCount = res['clientsCount'];
      isParticipant = res['isParticipant'];
    } on Exception catch (e) {
      showErrSnackBar(context, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Game Room".ii()),
          centerTitle: true,
        ),
        floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Visibility(
                visible: !isParticipant,
                child: FloatingActionButton(
                  heroTag: 'doEnroll',
                  onPressed: () => _doEnroll(context),
                  mini: true,
                  elevation: 10,
                  //child: Icon(FontAwesomeIcons.cartPlus),
                  child: Icon(EvaIcons.personAddOutline),
                ),
              ),
              Container(
                height: 10,
              ),
              Visibility(
                visible: isOwner,
                child: FloatingActionButton(
                  heroTag: 'doEdit',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RoomUI(roomId: roomId)));
                  },
                  mini: true,
                  elevation: 10,
                  child: Icon(EvaIcons.edit2Outline),
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
      child: Card(
        elevation: 10,
        margin: const EdgeInsets.all(5.0),
        child: Container(
          margin: const EdgeInsets.all(5.0),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text(description, style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              Text('Exchange date: ${exchangeDate}',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              Text('Clients count: ${clientsCount}',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  void _doEnroll(BuildContext context) {
    //
  }
}

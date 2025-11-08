import 'dart:convert';

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

class RoomUI extends StatefulWidget {
  final int roomId;
  @override
  State<StatefulWidget> createState() => _RoomState();
  RoomUI({super.key, required this.roomId});
}

class _RoomState extends State<RoomUI> {
  bool _isLoading = true;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  List<dynamic> langs = [];
  int roomId = 0;
  bool isVisible = false;
  DateTime? exchangeDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _load() async {
    try {
      final response = await API.getRoom(widget.roomId);
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      if (!mounted) return;

      debugPrint(response.body);
      final res = jsonDecode(response.body);
      roomId = res['roomId'];
      _titleController.text = res['title'] ?? '';
      _descriptionController.text = res['desc'] ?? '';
      isVisible = res['isVisible'] ?? false;
      final exchangeDateStr = res['exchangeDate'];
      if (exchangeDateStr != null &&
          exchangeDateStr is String &&
          exchangeDateStr.isNotEmpty) {
        final parts = exchangeDateStr.split('.');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            exchangeDate = DateTime(year, month, day);
          }
        }
      }
    } on Exception catch (e) {
      showErrSnackBar(context, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Transform.translate(
                  offset: Offset(-12.0, 0),
                  child: Checkbox(
                    value: isVisible,
                    onChanged: (bool? value) {
                      setState(() {
                        isVisible = value ?? false;
                      });
                    },
                  ),
                ),
                Text('Active'.ii())
              ],
            ),
            TextField(
                autofocus: true,
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Room title'.ii(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
                )),
            Container(
              height: 20,
            ),
            TextField(
                controller: _descriptionController,
                maxLines: null,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'Description'.ii(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
                )),
            SizedBox(height: 20),
            Row(
              children: [
                Text('Exchange date'.ii(), style: TextStyle(fontSize: 16)),
                SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: exchangeDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          exchangeDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        exchangeDate == null
                            ? 'Exchange date'.ii()
                            : "${exchangeDate!.day.toString().padLeft(2, '0')}.${exchangeDate!.month.toString().padLeft(2, '0')}.${exchangeDate!.year}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future _doSave(BuildContext context) async {
    //
    setState(() {
      _isLoading = true;
    });

    if (_titleController.text.isEmpty) {
      showErrSnackBar(context, "Enter a name of your room!".ii());
      return;
    }
    //
    Map room = {};
    room['roomId'] = roomId;
    room['title'] = _titleController.text;
    room['description'] = _descriptionController.text;

    // convert exchangeDate to string only with date (YYYY-MM-DD)
    if (exchangeDate != null) {
      String exchangeDateStr =
          "${exchangeDate!.year.toString().padLeft(4, '0')}-${exchangeDate!.month.toString().padLeft(2, '0')}-${exchangeDate!.day.toString().padLeft(2, '0')}";
      room['exchangeDate'] = exchangeDateStr;
    }

    room['isVisible'] = isVisible ? 1 : 0;
    debugPrint("PUT ROOM=" + room.toString());
    try {
      //@todo implement putDict
      final response = await API.putRoom(room);
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      debugPrint(response.body);
      final res = jsonDecode(response.body);
      debugPrint("PUT ROOM=" + res.toString());
      if (!mounted) return;
      showSnackBar(context, "Room saved successfully!".ii());
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeUI()));
    } catch (e) {
      showErrSnackBar(context, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
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

                var response = await API.putRoom(dict);
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

import 'dart:convert';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:epamms/ui/room.dart';
import 'package:epamms/ui/snack_bar.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
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
  int recipient = 0;
  Map recipientInfo = {};

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
      if (exchangeDate == '') {
        exchangeDate = 'Not specified'.ii();
      }
      isOwner = res['isOwner'];
      clientsCount = res['clientsCount'];
      isParticipant = res['isParticipant'];
      recipient = res['recipient'];
      if (recipient > 0) {
        final response = await API.getRcpProfile(recipient);
        if (!mounted) return;
        if (response.statusCode != 200) {
          throw Exception(API.httpErr + response.statusCode.toString());
        }
        recipientInfo = jsonDecode(response.body);
        debugPrint(recipientInfo.toString());
      }
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
                visible: recipient == 0,
                child: FloatingActionButton(
                  heroTag: 'doEnroll',
                  onPressed: () => _doEnroll(context),
                  elevation: 10,
                  //child: Icon(FontAwesomeIcons.cartPlus),
                  child: (isParticipant)
                      ? Icon(EvaIcons.personRemoveOutline)
                      : Icon(EvaIcons.personAddOutline),
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
        body: _buildRoom(context));
  }

  Widget _buildRoom(context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(5.0),
            child: Card(
              elevation: 10,
              margin: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            softWrap: true,
                          ),
                          SizedBox(height: 2),
                          Text(description, style: TextStyle(fontSize: 16)),
                          SizedBox(height: 2),
                          Text('Exchange date: ${exchangeDate}',
                              style: TextStyle(fontSize: 16)),
                          SizedBox(height: 2),
                          Text(
                              'Players count:  '.ii() + clientsCount.toString(),
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isParticipant)
                          Image.asset('images/star.png', width: 32, height: 32),
                        SizedBox(height: 20),
                        if (isOwner) Icon(Icons.person, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          _buildRecipient(context),
          _buildQR(),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  void _doEnroll(BuildContext context) async {
    //
    try {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.clientId == 0) {
        showErrSnackBar(context, 'You are not logged in'.ii());
        return;
      }
      Map params = Map();
      params['roomId'] = roomId;
      params['state'] = 'enroll';
      if (isParticipant) {
        params['state'] = 'unenroll';
      }
      final response = await API.doEnroll(params);
      if (!mounted) return;
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      final res = jsonDecode(response.body);
      if (res['result'] == 'ok') {
        setState(() {
          isParticipant = !isParticipant;
          clientsCount = clientsCount + (isParticipant ? 1 : -1);
        });
        if (!isParticipant) {
          showSnackBar(context, 'Unenrolled successfully');
        } else {
          showSnackBar(context, 'Enrolled successfully');
        }
      } else {
        throw Exception(res['err']);
      }
    } catch (e) {
      showErrSnackBar(context, e.toString());
    }
  }

  _buildRecipient(context) {
    if (!isParticipant) return Center(child: Text('Your are not in game yet'));
    if (recipient == 0)
      return Center(child: Text('Your recipient haven\'t been selected yet'));
    final sex = recipientInfo['sex'];
    final year = recipientInfo['year'];
    final all = '($sex, $year y.o.)';
    final np = recipientInfo['npAddress'];
    final wishes = recipientInfo['wishlist'];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 300,
              height: 300,
              child: (recipientInfo['photo'] != null &&
                      recipientInfo['photo'] == true)
                  ? Image.network(
                      'https://ms.afisha.news/photo.php?id=${recipientInfo['id']}',
                      fit: BoxFit.cover)
                  : Image.asset('images/user.png', fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('${recipientInfo['name1']} ${recipientInfo['name2']}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
              Text(all, style: TextStyle(fontSize: 12)),
            ],
          ),
          Text('${recipientInfo['phone']}'),
          Text('${recipientInfo['login']}'),
          Divider(),
          SizedBox(height: 10),
          (recipientInfo['delService'] == 1)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipientInfo['delServiceName'],
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(recipientInfo['postIndex'],
                            style: TextStyle(fontSize: 14)),
                        Text(
                            recipientInfo[
                                'clientAddress'], // @todo: add address to profile
                            style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    Image.asset('images/ukrpost-logo.png'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recipientInfo['delServiceName'],
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(np[0], style: TextStyle(fontSize: 14)),
                          Text(np[1], style: TextStyle(fontSize: 14)),
                          Text(np[2],
                              style: TextStyle(fontSize: 14), softWrap: true),
                        ],
                      ),
                    ),
                    Image.asset('images/np-logo.png'),
                  ],
                ),
          SizedBox(height: 10),
          Divider(),
          Text('Hobbies'.ii(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(recipientInfo['hobby'].toString(),
              style: TextStyle(fontSize: 14)),
          Divider(),
          Text('Wishes'.ii(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ListView.builder(
            shrinkWrap: true,
            itemCount: wishes.length,
            itemBuilder: (context, index) {
              final itemMap = wishes[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemMap['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: null,
                        ),
                        if (itemMap['description'].isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              itemMap['description'],
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                              softWrap: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                  itemMap['url'].isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            if (itemMap['url'].isNotEmpty) {
                              launchUrl(Uri.parse(itemMap['url']),
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          behavior: HitTestBehavior.translucent,
                          child: Icon(EvaIcons.link2))
                      : SizedBox.shrink(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  _buildQR() {
    if (recipient != 0) return SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(5.0),
      child: Center(
        child: QrImageView(
          data: 'https://ms.afisha.news/room.php?id=' + roomId.toString(),
          version: QrVersions.auto,
          size: 300.0,
          //embeddedImage: AssetImage('images/logo1.png'),
          embeddedImageStyle: QrEmbeddedImageStyle(
            size: Size(32.0, 32.0),
          ),
        ),
      ),
    );
  }
}

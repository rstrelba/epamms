import 'dart:convert';

import 'package:epamms/ii.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import 'drawer.dart';
import '../state.dart';

class ProfileUI extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ProfileState();
}

// Used for controlling whether the 
class _ProfileState extends State<ProfileUI> {
  bool isLoading = true;
  String partnerName = '';
  String login = '';
  String erValue = '';
  String credit = '';
  String deferment = '';
  String bal = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

    _load() async {
    setState(() {
      isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile".ii()),
      ),
      drawer: DrawerUI(onUpdate: () {}),
      body: Container(
        padding: EdgeInsets.all(5.0),
        child: _buildProfile(context),
      ),
    );
  }

  Widget rowData(String param, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 1, child: Text(param)),
      Expanded(flex: 3, child: Text(value, style: TextStyle(fontWeight: FontWeight.bold)))
    ]);
  }

  Widget _buildProfile(context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rowData('Клиент'.ii(), partnerName),
          rowData('Login', login),
          rowData('Долг'.ii(), bal),
          //rowData('Кредит', credit),
          //rowData('Отсрочка', deferment),
          //rowData('Курс', erValue),
        ],
      ),
    );
  }
}

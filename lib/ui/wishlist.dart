import 'dart:convert';

import 'package:epamms/ii.dart';
import 'package:epamms/ui/snack_bar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import '../api.dart';

class WishEditUI extends StatefulWidget {
  WishEditUI({Key? key, required this.wishId}) : super(key: key);
  final int wishId;

  @override
  State<WishEditUI> createState() => _WishEditState();
}

class _WishEditState extends State<WishEditUI> {
  List<dynamic> wishlist = [];
  bool isLoading = true;
  bool isLoadingAI = false;
  Map wish = {};
  List wishlistAI = [];
  List<String> previousWishesAI = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
    });
    try {
      FirebaseAnalytics.instance.logEvent(name: 'wishlist');
      wish = await API.getWish(widget.wishId);
      debugPrint(wish.toString());
    } on Exception catch (e) {
      showErrSnackBar(context, e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wish".ii()),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: 'delete_wish',
            onPressed: () {
              _delete(context);
            },
            child: Icon(Icons.delete),
            mini: true,
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'save_wish',
            onPressed: () {
              _save(context);
            },
            child: Icon(Icons.check),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(5.0),
        child: _buildWish(context),
      ),
    );
  }

  void _save(BuildContext context) async {
    try {
      final res = await API.putWish(wish);
      wish['id'] = res['id'];
      showSnackBar(context, "Wish saved");
      Navigator.pop(context, wish);
    } on Exception catch (e) {
      showErrSnackBar(context, e.toString());
    }
  }

  Widget _buildWish(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          TextFormField(
              //autofocus: true,
              onChanged: (value) {
                wish['name'] = value;
              },
              initialValue: wish['name'],
              maxLines: null,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Title'.ii(),
                isDense: true,
                contentPadding:
                    EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
              )),
          TextFormField(
              onChanged: (value) {
                wish['description'] = value;
              },
              initialValue: wish['description'],
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Description'.ii(),
                isDense: true,
                contentPadding:
                    EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
              )),
          TextFormField(
              //autofocus: true,
              onChanged: (value) {
                wish['url'] = value;
              },
              initialValue: wish['url'],
              decoration: InputDecoration(
                labelText: 'URL'.ii(),
                isDense: true,
                contentPadding:
                    EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
              )),
          SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                //shape: CircleBorder(),
                padding: EdgeInsets.all(1),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              onPressed: () {
                _getWishListAI(
                    context); // TODO: Implement AI suggestion logic here
              },
              icon: Icon(Icons.auto_awesome, size: 32), // Gemini-like sparkle
              label: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Text(
                  'Come up with AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
          if (isLoadingAI) Center(child: CircularProgressIndicator()),
          if (wishlistAI.isNotEmpty)
            ListView.builder(
              itemCount: wishlistAI.length,
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return _buildAIWish(context, index);
              },
            ),
        ]));
  }

  void _delete(BuildContext context) async {
    try {
      await API.delWish(wish['id']);
      showSnackBar(context, "Wish deleted");
      Navigator.pop(context, null);
    } on Exception catch (e) {
      showErrSnackBar(context, e.toString());
    }
  }

  void _getWishListAI(BuildContext context) async {
    setState(() {
      wishlistAI.clear();
      isLoadingAI = true;
    });
    try {
      final was = previousWishesAI.join(',');
      Map params = Map();
      params['was'] = was;
      wishlistAI.clear();
      final res = await API.getWishListAI(params);
      if (res is! List) {
        throw Exception('AI: Unexpected backend response');
      }
      wishlistAI.addAll(res);
      debugPrint(wishlistAI.toString());
      wishlistAI.forEach((wish) {
        if (!previousWishesAI.contains(wish['name'])) {
          previousWishesAI.add(wish['name']);
        }
      });
    } on Exception catch (e) {
      showErrSnackBar(context, e.toString());
    } finally {}
    setState(() {
      isLoadingAI = false;
    });
  }

  _buildAIWish(BuildContext context, int index) {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: () {
          wish['name'] = wishlistAI[index]['name'];
          wish['description'] = wishlistAI[index]['description'];
          wish['url'] = "";
          _save(context);
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(wishlistAI[index]['name'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(wishlistAI[index]['description'],
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

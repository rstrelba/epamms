import 'dart:convert';

import 'package:epamms/ii.dart';
import 'package:epamms/ui/snack_bar.dart';
import 'package:epamms/ui/wishlist.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import 'home.dart';

class ProfileUI extends StatefulWidget {
  final bool isReadOnly;
  final int id;
  ProfileUI({required this.isReadOnly, required this.id});
  @override
  State<StatefulWidget> createState() => _ProfileState();
}

// Used for controlling whether the
class _ProfileState extends State<ProfileUI> {
  bool isLoading = true;
  Map profile = {};
  List sex = [];
  List languages = [];
  List delService = [];
  File? _selfieImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  // Nova Poshta data
  List npAreaList = [];
  String? npArea = '';
  List npCityList = [];
  String? npCity = '';
  List npWhList = [];
  String? npWh = '';

  bool isLoadingNP = false;
  List wishlist = [];
  bool isReadOnly = false;

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
    isReadOnly = widget.isReadOnly;
    try {
      FirebaseAnalytics.instance.logEvent(name: 'profile');
      final responseLangs = await API.getLanguages();
      if (responseLangs.statusCode != 200) {
        throw Exception(API.httpErr + responseLangs.statusCode.toString());
      }
      languages = jsonDecode(responseLangs.body);

      final responseSex = await API.getSex();
      if (responseSex.statusCode != 200) {
        throw Exception(API.httpErr + responseSex.statusCode.toString());
      }
      sex = jsonDecode(responseSex.body);

      final responseDelService = await API.getDelService();
      if (responseDelService.statusCode != 200) {
        throw Exception(API.httpErr + responseDelService.statusCode.toString());
      }
      delService = jsonDecode(responseDelService.body);

      final responseAreas = await API.getNPArea();
      if (responseAreas.statusCode != 200) {
        throw Exception(API.httpErr + responseDelService.statusCode.toString());
      }
      npAreaList.addAll(jsonDecode(responseAreas.body));

      final response = await API.getProfile(widget.id);
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      if (!mounted) return;

      debugPrint(response.body);
      profile = jsonDecode(response.body);
      if (profile['wishlist'] != null && profile['wishlist'].isNotEmpty) {
        wishlist.addAll(profile['wishlist'] as List);
      }

      // Load Nova Poshta data if it exists in the profile

      if (profile['delService'] == 2 &&
          profile['npWh'] != null &&
          profile['npWh'].toString().isNotEmpty) {
        await _loadNPData();
      }
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
        title: Text("Profile".ii()),
      ),
      floatingActionButton: Visibility(
        visible: !isReadOnly,
        child: FloatingActionButton(
          onPressed: () {
            _save(context);
          },
          child: Icon(Icons.check),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(5.0),
        child: _buildProfile(context),
      ),
    );
  }

  Widget _buildProfile(context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AbsorbPointer(
            absorbing: isReadOnly,
            child: TextFormField(
                //autofocus: true,
                onChanged: (value) {
                  profile['name1'] = value;
                },
                initialValue: profile['name1'],
                decoration: InputDecoration(
                  labelText: 'First name'.ii(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
                )),
          ),
          AbsorbPointer(
            absorbing: isReadOnly,
            child: TextFormField(
                onChanged: (value) {
                  profile['name2'] = value;
                },
                initialValue: profile['name2'],
                decoration: InputDecoration(
                  labelText: 'Second name'.ii(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
                )),
          ),
          AbsorbPointer(
            absorbing: isReadOnly,
            child: TextFormField(
              keyboardType: TextInputType.number,
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                profile['phone'] = value;
              },
              initialValue: profile['phone'],
              decoration: InputDecoration(
                prefixText: '+380 ',
                counterText: '',
                labelText: 'Phone number'.ii(),
                isDense: true,
                contentPadding:
                    EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
                errorText: (profile['phone'] != null &&
                        profile['phone'].toString().length != 9 &&
                        profile['phone'].toString().isNotEmpty)
                    ? 'Enter 9 digits'
                    : null,
              ),
            ),
          ),
          Text('Sex'.ii()),
          AbsorbPointer(
            absorbing: isReadOnly,
            child: DropdownButtonFormField(
              items: sex
                  .map((item) => DropdownMenuItem(
                      child: Text(item['name']), value: item['id']))
                  .toList(),
              initialValue: sex.any((item) => item['id'] == profile['sex'])
                  ? profile['sex']
                  : null,
              onChanged: (value) {
                profile['sex'] = value;
              },
            ),
          ),
          AbsorbPointer(
            absorbing: isReadOnly,
            child: DropdownButtonFormField<String>(
              items: languages
                  .map((item) => DropdownMenuItem<String>(
                      child: Text(item['nativeName']?.toString() ??
                          item['name']?.toString() ??
                          ''),
                      value: item['code']?.toString()))
                  .where((item) => item.value != null)
                  .toList(),
              value: languages.any((item) =>
                      item['code']?.toString() == profile['lang']?.toString())
                  ? profile['lang']?.toString()
                  : null,
              onChanged: (value) {
                if (value != null) {
                  profile['lang'] = value;
                }
              },
              decoration: InputDecoration(
                labelText: 'Language'.ii(),
                isDense: true,
                contentPadding:
                    EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
              ),
            ),
          ),
          SizedBox(height: 10),
          AbsorbPointer(
            absorbing: isReadOnly,
            child: TextFormField(
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                profile['year'] = value;
              },
              initialValue: profile['year'].toString(),
              decoration: InputDecoration(
                labelText: 'Year of birth'.ii(),
                isDense: true,
                contentPadding:
                    EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
              ),
            ),
          ),
          SizedBox(height: 10),
          AbsorbPointer(
            absorbing: isReadOnly,
            child: TextFormField(
              onChanged: (value) {
                profile['hobby'] = value;
              },
              initialValue: profile['hobby'],
              decoration: InputDecoration(
                labelText: 'Hobby'.ii(),
              ),
            ),
          ),
          Text('Delivery service'.ii()),
          AbsorbPointer(
            absorbing: isReadOnly,
            child: DropdownButtonFormField(
              isExpanded: true,
              items: delService
                  .map((item) => DropdownMenuItem(
                      child: Text(item['name']), value: item['id']))
                  .toList(),
              initialValue: profile['delService'] != null &&
                      profile['delService'].toString().isNotEmpty &&
                      delService
                          .any((item) => item['id'] == profile['delService'])
                  ? profile['delService']
                  : null,
              onChanged: (value) async {
                try {
                  setState(() {
                    isLoadingNP = true;
                  });
                  profile['delService'] = value;
                  if (profile['delService'] == 2 &&
                      profile['npWh'] != null &&
                      profile['npWh'].toString().isNotEmpty) {
                    await _loadNPData();
                  }
                } on Exception catch (_) {
                  // TODO: handle exception
                } finally {
                  setState(() {
                    isLoadingNP = false;
                  });
                }
              },
            ),
          ),
          SizedBox(height: 10),
          if (profile['delService'] == 1) _buildUkrPoshta(context),
          if (profile['delService'] == 2) _buildNovaPoshta(context),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Selfie? '.ii()),
              Text('😉', style: TextStyle(fontSize: 28)),
            ],
          ),
          _buildSelfie(context),
          Center(
              child: Text('Tap to take a selfie'.ii(),
                  style: TextStyle(fontSize: 12))),
          SizedBox(height: 10),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('My wishlist'.ii()),
              Text('🎁', style: TextStyle(fontSize: 28)),
            ],
          ),
          _buildWishlist(context),
          Divider(),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUkrPoshta(context) {
    return AbsorbPointer(
      absorbing: isReadOnly,
      child: Column(
        children: [
          Image.asset('images/ukrpost-logo.png'),
          TextFormField(
              //autofocus: true,
              onChanged: (value) {
                profile['postIndex'] = value;
              },
              initialValue: profile['postIndex'],
              decoration: InputDecoration(
                labelText: 'Post index'.ii(),
                isDense: true,
                contentPadding:
                    EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
              )),
          TextFormField(
              //autofocus: true,
              onChanged: (value) {
                profile['address'] = value;
              },
              initialValue: profile['address'],
              decoration: InputDecoration(
                labelText: 'Address'.ii(),
                isDense: true,
                contentPadding:
                    EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
              )),
        ],
      ),
    );
  }

  Widget _buildNovaPoshta(context) {
    if (isLoadingNP) return Center(child: CircularProgressIndicator());
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Image.asset('images/np-logo.png')),
        SizedBox(height: 10),
        Text('Area'.ii()),
        DropdownButtonFormField(
          isExpanded: true,
          items: npAreaList
              .map((item) => DropdownMenuItem(
                  child: Text(item['name'], overflow: TextOverflow.ellipsis),
                  value: item['id']))
              .toList(),
          initialValue: npArea,
          onChanged: (value) async {
            if (npArea!.isNotEmpty) {
              await _loadNPCity(value as String?);
            }
            setState(() {
              npArea = value as String?;
              profile['npArea'] = npArea;
            });
          },
        ),
        Text('City'.ii()),
        DropdownButtonFormField(
          isExpanded: true,
          items: npCityList
              .map((item) => DropdownMenuItem(
                  child: Text(item['name'], overflow: TextOverflow.ellipsis),
                  value: item['id']))
              .toList(),
          initialValue: npCity,
          onChanged: (value) async {
            await _loadNPWh(value as String?);
            setState(() {
              npCity = value as String;
            });
          },
        ),
        if (npCity != null && npCity!.isNotEmpty) ...[
          Text('Warehouse'.ii()),
          DropdownButtonFormField(
            isExpanded: true,
            items: npWhList
                .map((item) => DropdownMenuItem(
                    child: Text(item['name'], overflow: TextOverflow.ellipsis),
                    value: item['id']))
                .toList(),
            initialValue: npWh,
            onChanged: (value) {
              setState(() {
                npWh = value as String?;
                profile['npWh'] = npWh;
              });
            },
          ),
        ],
      ],
    );
  }

  Future<void> _loadNPCity(String? npArea) async {
    try {
      final response = await API.getNPCity(npArea);
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      if (!mounted) return;
      npWhList.clear();
      npCityList.clear();
      npCity = null;
      npWh = null;
      npCityList.addAll(jsonDecode(response.body));
    } on Exception catch (e) {
      if (mounted) {
        showErrSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _loadNPWh(String? npCity) async {
    try {
      final response = await API.getNPWh(npCity);
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      if (!mounted) return;
      npWhList.clear();
      npWh = null;
      npWhList.addAll(jsonDecode(response.body));
    } on Exception catch (e) {
      if (mounted) {
        showErrSnackBar(context, e.toString());
      }
    }
  }

  void _save(BuildContext context) async {
    try {
      debugPrint(profile.toString());
      final response = await API.putProfile(profile);
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      if (!mounted) return;
      showSnackBar(context, 'Profile saved');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeUI()),
      );
    } on Exception catch (e) {
      if (mounted) {
        showErrSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _loadNPData() async {
    try {
      final responseNPWh = await API.getNPbyRef(profile['npWh']);
      if (responseNPWh.statusCode != 200) {
        throw Exception(API.httpErr + responseNPWh.statusCode.toString());
      }
      if (!mounted) return;
      final npAddress = jsonDecode(responseNPWh.body);
      profile['npArea'] = npAddress['area_ref'];
      profile['npCity'] = npAddress['city_ref'];
      npArea = profile['npArea'].toString();
      await _loadNPCity(npArea);
      if (profile['npCity'] != null &&
          profile['npCity'].toString().isNotEmpty) {
        npCity = profile['npCity'].toString();
        await _loadNPWh(npCity);
        if (profile['npWh'] != null && profile['npWh'].toString().isNotEmpty) {
          npWh = profile['npWh'].toString();
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        showErrSnackBar(context, e.toString());
      }
    }
  }

  Widget _buildSelfie(context) {
    return AbsorbPointer(
      absorbing: isReadOnly,
      child: Dismissible(
        key: Key('selfie'),
        onDismissed: (direction) {
          setState(() {});
        },
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text('Delete selfie?'.ii()),
                    content: Text(
                        'Are you sure you want to delete your selfie?'.ii()),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text('Cancel'.ii())),
                      TextButton(
                          onPressed: () async {
                            final photoResponse = await API.delPhoto();
                            if (photoResponse.statusCode != 200) {
                              throw Exception(API.httpErr +
                                  photoResponse.statusCode.toString());
                            }
                            if (!mounted) return;
                            showSnackBar(context, 'Photo deleted successfully');
                            setState(() {
                              _selfieImageFile = null;
                              profile['photo'] = false;
                              profile['selfiePath'] = null;
                            });
                            Navigator.of(context).pop(true);
                          },
                          child: Text('Delete'.ii())),
                    ],
                  ));
        },
        child: GestureDetector(
          onTap: _takeSelfie,
          child: Center(
            child: ClipOval(
              child: SizedBox(
                width: 300,
                height: 300,
                child: _selfieImageFile != null
                    ? Image.file(_selfieImageFile!, fit: BoxFit.cover)
                    : (profile['photo'] != null && profile['photo'] == true
                        ? Image.network(
                            'https://mysterioussanta.afisha.news/photo.php?id=${profile['id']}',
                            fit: BoxFit.cover)
                        : Image.asset('images/user.png', fit: BoxFit.cover)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takeSelfie() async {
    try {
      if (!mounted) return;

      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          if (status.isPermanentlyDenied) {
            showErrSnackBar(context, 'Camera permission permanently denied.');
          } else {
            showErrSnackBar(context, 'Camera permission denied');
          }
          return;
        }
      }

      if (!mounted) return;
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 95,
      );
      if (image == null) return;
      if (!mounted) return;

      final File imageFile = File(image.path);

      // Convert image to base64
      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Save photo to backend
      try {
        final photoResponse = await API.putPhoto({
          'photo': base64Image,
        });

        if (photoResponse.statusCode != 200) {
          throw Exception(API.httpErr + photoResponse.statusCode.toString());
        }

        if (!mounted) return;
        showSnackBar(context, 'Photo saved successfully');
      } catch (e) {
        if (mounted) {
          showErrSnackBar(context, 'Error saving photo: ${e.toString()}');
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _selfieImageFile = imageFile;
        profile['photo'] = true;
        profile['selfiePath'] = image.path;
      });
    } catch (e) {
      if (mounted) {
        showErrSnackBar(context, 'Error taking selfie: ${e.toString()}');
      }
    }
  }

  Widget _buildWishlistItem(context, itemMap) {
    return AbsorbPointer(
      absorbing: isReadOnly,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        //padding: EdgeInsets.all(8),
        child: Dismissible(
          key: Key('wishlist_${itemMap['id']}'),
          onDismissed: (direction) {
            //_delWishlist(itemMap['id']);
            setState(() {
              wishlist.remove(itemMap);
            });
          },
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text('Delete your wish?'.ii()),
                      content: Text(
                          'Are you sure you want to delete this wish?'.ii()),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text('Cancel'.ii())),
                        TextButton(
                            onPressed: () async {
                              final wishlistResponse =
                                  await API.delWishlist(itemMap['id']);
                              if (wishlistResponse.statusCode != 200) {
                                throw Exception(API.httpErr +
                                    wishlistResponse.statusCode.toString());
                              }
                              if (!mounted) return;
                              showSnackBar(
                                  context, 'Wishlist deleted successfully');
                              setState(() {
                                profile['wishlist'].remove(itemMap);
                              });
                              Navigator.of(context).pop(true);
                            },
                            child: Text('Delete'.ii())),
                      ],
                    ));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    final wish = await Navigator.of(context).push<Map>(
                      MaterialPageRoute(
                          builder: (context) =>
                              WishEditUI(wishId: itemMap['id'])),
                    );
                    setState(() {
                      wishlist.remove(itemMap);
                      if (wish != null) wishlist.add(wish);
                    });
                  },
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
          ),
        ),
      ),
    );
  }

  Widget _buildWishlist(context) {
    return AbsorbPointer(
      absorbing: isReadOnly,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return _buildWishlistItem(context, wishlist[index]);
              },
              itemCount: wishlist.length,
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Visibility(
                    visible: !isReadOnly,
                    child: ElevatedButton(
                      onPressed: () async {
                        final wish = await Navigator.of(context).push<Map>(
                          MaterialPageRoute(
                              builder: (context) => WishEditUI(wishId: 0)),
                        );
                        if (wish != null) {
                          setState(() {
                            wishlist.add(wish);
                          });
                        }
                      },
                      child: Icon(Icons.add),
                    ),
                  )
                ],
              ),
            )
          ]),
    );
  }
}

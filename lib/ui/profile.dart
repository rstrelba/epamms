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
  final ImagePicker _imagePicker = ImagePicker();

  // Nova Poshta data
  List npAreaList = [];
  String? npArea = null;
  List npCityList = [];
  String? npCity = '';
  List npWhList = [];
  String? npWh = '';

  bool isLoadingNP = false;
  List wishlist = [];
  bool isReadOnly = false;
  bool wasEdited = false;

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
      languages.addAll(await API.getLanguages());
      sex.addAll(await API.getSex());
      delService.addAll(await API.getDelService());
      npAreaList.addAll(await API.getNPArea());
      debugPrint(npAreaList.toString());
      profile = await API.getProfile(widget.id);
      debugPrint(profile.toString());
      if (!mounted) return;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        debugPrint(
            'onPopInvokedWithResult: didPop: $didPop, wasEdited: $wasEdited');
        if (didPop) return;
        final bool shouldPop = await _handleBackPress(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                  wasEdited = true;
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
                  wasEdited = true;
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
                wasEdited = true;
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
                wasEdited = true;
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
                wasEdited = true;
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
                wasEdited = true;
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
                wasEdited = true;
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
                  wasEdited = true;
                  setState(() {
                    isLoadingNP = true;
                  });
                  debugPrint('delService: ${value}');
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
              child: InfoUI(
            text: 'Tap to take a selfie'.ii(),
          )),
          Center(
              child: InfoUI(
            text: 'Swipe right to delete selfie'.ii(),
          )),
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
                wasEdited = true;
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
                wasEdited = true;
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
          value: npArea,
          onChanged: (value) async {
            npArea = value as String?;
            if (npArea != null && npArea!.isNotEmpty) {
              await _loadNPCity(value as String?);
            }
            wasEdited = true;
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
          //value: npCityList.any((item) => item['id'] == npCity) ? npCity : null,
          value: npCity,
          onChanged: (value) async {
            npCity = value as String?;
            await _loadNPWh(value);
            wasEdited = true;
          },
        ),
        if (npCity != null && npCity!.isNotEmpty) ...[
          Text('Warehouse'.ii()),
          DropdownButtonFormField(
            isExpanded: true,
            items: npWhList
                .map((item) => DropdownMenuItem(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8),
                      child: Text(
                        item['name'],
                        softWrap: true,
                        maxLines: 5,
                        //overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    value: item['id']))
                .toList(),
            value: npWhList.any((item) => item['id'] == npWh) ? npWh : null,
            onChanged: (value) {
              wasEdited = true;
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
    debugPrint('_loadNPCity: ${npArea}');
    setState(() {
      isLoadingNP = true;
    });
    try {
      final res = await API.getNPCity(npArea);
      if (!mounted) return;
      npWhList.clear();
      npCityList.clear();
      npCity = null;
      npWh = null;
      npCityList.addAll(res);
    } on Exception catch (e) {
      if (mounted) {
        showErrSnackBar(context, e.toString());
      }
    } finally {
      setState(() {
        isLoadingNP = false;
      });
    }
  }

  Future<void> _loadNPWh(String? npCity) async {
    debugPrint('_loadNPWh: ${npCity}');
    setState(() {
      isLoadingNP = true;
    });
    try {
      final res = await API.getNPWh(npCity);
      if (!mounted) return;
      npWhList.clear();
      npWh = null;
      npWhList.addAll(res);
    } on Exception catch (e) {
      if (mounted) {
        showErrSnackBar(context, e.toString());
      }
    } finally {
      setState(() {
        isLoadingNP = false;
      });
    }
  }

  Future<void> _save(BuildContext context) async {
    try {
      await API.putProfile(profile);
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
      debugPrint('_loadNPData: ${profile['npWh']}');
      if (profile['npWh'] == null || profile['npWh'].toString().isEmpty) return;
      final npAddress = await API.getNPbyRef(profile['npWh']);
      debugPrint(npAddress.toString());
      if (!mounted) return;
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
      child: profile['photo'].toString().isNotEmpty
          ? Dismissible(
              key: Key(
                  'selfie_${profile['photo']}'), // Уникальный ключ с URL фото
              onDismissed: ((direction) async {
                await API.delPhoto();
                setState(() {
                  profile['photo'] = '';
                  //profile['selfiePath'] = null;
                });
                if (!mounted) return;
                showSnackBar(context, 'Photo deleted successfully');
              }),
              confirmDismiss: ((direction) async {
                return await showYesNoDialog(context, 'Delete selfie?'.ii());
              }),
              child: GestureDetector(
                onTap: _takeSelfie,
                child: Center(
                  child: ClipOval(
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: Image.network(profile['photo'], fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            )
          : GestureDetector(
              onTap: _takeSelfie,
              child: Center(
                child: ClipOval(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Image.asset('images/user.png', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _takeSelfie() async {
    try {
      if (!mounted) return;
      final camStatus = await Permission.camera.status;
      debugPrint('camStatus: ${camStatus.toString()}');
      if (!camStatus.isGranted) {
        final camRequest = await Permission.camera.request();
        if (!camRequest.isGranted) {
          return null;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) return;
      if (!mounted) return;

      final File imageFile = File(image.path);

      // Convert image to base64
      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Save photo to backend
      try {
        wasEdited = true;
        await API.putPhoto({
          'photo': base64Image,
        });

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
        profile['photo'] = API.dbPhotoUrl + profile['id'].toString();
      });
    } catch (e) {
      if (mounted) {
        showErrSnackBar(context, 'Error taking selfie: ${e.toString()}');
      }
    }
  }

  Widget _buildWishlistItem(context, item) {
    return AbsorbPointer(
      absorbing: isReadOnly,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        //padding: EdgeInsets.all(8),
        child: Dismissible(
          key: Key('wishlist_${item['id']}_${item.hashCode}'),
          onDismissed: (direction) async {
            try {
              await API.delWishlist(item['id']);
              if (!mounted) return;
              showSnackBar(context, 'Wishlist deleted successfully');
            } catch (e) {
              if (mounted) {
                showErrSnackBar(
                    context, 'Error deleting wish: ${e.toString()}');
              }
              return; // Don't remove from UI if API returned an error
            }

            wasEdited = true;
            setState(() {
              wishlist.remove(item);
              if (profile['wishlist'] != null) {
                profile['wishlist'].remove(item);
              }
            });
          },
          confirmDismiss: (direction) async {
            return await showYesNoDialog(context, 'Delete your wish?'.ii());
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    debugPrint('onTap: ${item['id']}');
                    final wish = await Navigator.of(context).push<Map>(
                      MaterialPageRoute(
                          builder: (context) => WishEditUI(wishId: item['id'])),
                    );
                    setState(() {
                      wasEdited = true;
                      if (wish != null) {
                        wishlist.remove(item);
                        wishlist.add(wish);
                      }
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        maxLines: null,
                      ),
                      if (item['description'].isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            item['description'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                            softWrap: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              item['url'].isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        if (item['url'].isNotEmpty) {
                          launchUrl(Uri.parse(item['url']),
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
            Visibility(
              visible: wishlist.isNotEmpty,
              child: Center(
                  child: InfoUI(
                text: 'Swipe right to delete wish'.ii(),
              )),
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

  Future<bool> _handleBackPress(BuildContext context) async {
    debugPrint('_handleBackPress: wasEdited: ${wasEdited}');
    if (!wasEdited) {
      return true;
    }
    final bool shouldSave = await showYesNoDialog(
        context, 'You have unsaved changes. Do you want to save them?');
    if (shouldSave) {
      await _save(context);
    }
    return true;
  }
}

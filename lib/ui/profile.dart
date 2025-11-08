import 'dart:convert';

import 'package:epamms/ii.dart';
import 'package:epamms/ui/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

import '../api.dart';
import 'home.dart';

class ProfileUI extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ProfileState();
}

// Used for controlling whether the
class _ProfileState extends State<ProfileUI> {
  bool isLoading = true;
  Map profile = {};
  List sex = [];
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
    try {
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

      final response = await API.getProfile();
      if (response.statusCode != 200) {
        throw Exception(API.httpErr + response.statusCode.toString());
      }
      if (!mounted) return;

      debugPrint(response.body);
      profile = jsonDecode(response.body);

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeUI()),
            );
          },
        ),
        title: Text("Profile".ii()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _save(context);
        },
        child: Icon(Icons.check),
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
          TextFormField(
              autofocus: true,
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
          TextFormField(
              autofocus: true,
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
          TextFormField(
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
              contentPadding: EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
              errorText: (profile['phone'] != null &&
                      profile['phone'].toString().length != 9 &&
                      profile['phone'].toString().isNotEmpty)
                  ? 'Enter 9 digits'
                  : null,
            ),
          ),
          Text('Sex'.ii()),
          DropdownButtonFormField(
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
          Text('Delivery service'.ii()),
          DropdownButtonFormField(
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
          SizedBox(height: 10),
          if (profile['delService'] == 1) _buildUkrPoshta(context),
          if (profile['delService'] == 2) _buildNovaPoshta(context),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Selfie? '.ii()),
              Text('😉', style: TextStyle(fontSize: 28)),
            ],
          ),
          _buildSelfie(context),
          SizedBox(height: 10),
          Text('My wishlist'.ii()),
        ],
      ),
    );
  }

  Widget _buildUkrPoshta(context) {
    return Column(
      children: [
        Image.asset('images/ukrpost-logo.png'),
        TextFormField(
            autofocus: true,
            onChanged: (value) {
              profile['postIndex'] = value;
            },
            initialValue: profile['postIndex'],
            decoration: InputDecoration(
              labelText: 'Post index'.ii(),
              isDense: true,
              contentPadding: EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
            )),
      ],
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
    return GestureDetector(
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
                        'https://ms.afisha.news/photo.php?id=${profile['id']}',
                        fit: BoxFit.cover)
                    : Image.asset('images/user.png', fit: BoxFit.cover)),
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
}

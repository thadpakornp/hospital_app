import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hospitalapp/screens/map_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import 'api_provider.dart';
import 'chewie_list_item.dart';

class AddChartDescription extends StatefulWidget {
  int id;

  AddChartDescription(this.id);

  @override
  _AddChartDescription createState() => _AddChartDescription(id);
}

class _AddChartDescription extends State<AddChartDescription> {
  String endPoint = 'https://suratstroke.com/';
  ApiProvider apiProvider = ApiProvider();
  int id;

  _AddChartDescription(this.id);
  bool _isUploading = false;
  File _image;
  String _description;
  var _geolocation;
  var _lat;
  var _lng;
  double lat;
  double lng;
  var profile;
  bool isVideo = false;
  bool isLoding = true;
  String _name;
  String _surname;
  String _prefix;
  String _images;
  final storage = new FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  var description = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _getProfile() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getProfile(token);
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          isLoding = false;
          profile = jsonResponse['data'];
          _name = profile['name'];
          _surname = profile['surname'];
          _prefix = profile['prefix']['name'];
          _images = profile['profile'];
        });
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (e) {
      print(e);
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
    }
  }

  Future _getLocation() async {
    if (_geolocation == null) {
      bool isLocationEnabled = await Geolocator().isLocationServiceEnabled();
      if (isLocationEnabled) {
        if (await Permission.locationAlways.request().isGranted ||
            await Permission.locationWhenInUse.request().isGranted) {
          Navigator.push(
            context,
            new MaterialPageRoute(builder: (context) => mapScreen()),
          ).then((value) {
            if (value != null) {
              setState(() {
                _geolocation = value;
                lat = value.target.latitude;
                lng = value.target.longitude;
                _lat = value.target.latitude.toStringAsFixed(6);
                _lng = value.target.longitude.toStringAsFixed(6);
              });
              _add();
            }
          });
        } else {
          _scaffoldKey.currentState.showSnackBar(new SnackBar(
              content: Text('กรุณาอนุญาตให้เข้าถึงที่ตั้งของคุณ')));
        }
      } else {
        _scaffoldKey.currentState.showSnackBar(
            new SnackBar(content: Text('กรุณาเปิดการเข้าถึงที่ตั้งของคุณ')));
      }
    } else {
      setState(() {
        _geolocation = null;
        lat = null;
        lng = null;
        _lat = null;
        _lng = null;
      });
    }
  }

  void _add() {
    final MarkerId markerId = MarkerId('1');
    setState(() {
      if (markers.containsKey(markerId)) {
        markers.remove(markerId);
      }
    });
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(lat ?? 13.7248936, lng ?? 100.3529157),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  //========================= Gellary / Camera AlerBox
  void _openImagePickerModal(BuildContext context) {
    final flatButtonColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 150.0,
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 10.0,
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('วิดีโอ'),
                  onPressed: () {
                    setState(() {
                      isVideo = true;
                    });
                    getVideo(ImageSource.camera);
                  },
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('กล้องถ่ายภาพ'),
                  onPressed: () {
                    setState(() {
                      isVideo = false;
                    });
                    getImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          );
        });
  }

  // ================================= Image from camera or gallery
  Future getImage(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);
    setState(() {
      _image = image;
    });
    Navigator.pop(context);
  }

  Future getImageGarally(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);
    setState(() {
      _image = image;
    });
  }

  Future getVideo(ImageSource source) async {
    var image = await ImagePicker.pickVideo(source: source);
    setState(() {
      _image = image;
    });
    Navigator.pop(context);
  }

  //============================================================= API Area to upload image
  void _startUploading() async {
    if (_description == null && _image == null && _geolocation == null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text('ไม่พบข้อมูลให้บันทึก')));
    } else {
      if (_image != null) {
        final response = await _uploadImage(_image);
        setState(() {
          _isUploading = false;
        });
        if (response == null) {
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด')));
        } else {
          Navigator.pop(context);
        }
      } else {
        //Call Api image is null
        setState(() {
          _isUploading = true;
        });
        String token = await storage.read(key: 'token');

        try {
          String _d;
          if (_description == null) {
            _d = '';
          } else {
            _d = _description;
          }
          final response = await apiProvider.uploadWithOutFileByID(
              token, _d, id, lat.toString(), lng.toString());
          setState(() {
            _isUploading = false;
          });
          if (response.statusCode == 200) {
            var jsonResponse = json.decode(response.body);
            if (jsonResponse['code'] == '200') {
              await apiProvider.sendNotifyToWebAndMobile(token, id);
              Navigator.pop(context);
            } else {
              _scaffoldKey.currentState
                  .showSnackBar(SnackBar(content: Text(jsonResponse['data'])));
            }
          } else {
            _scaffoldKey.currentState
                .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด')));
          }
        } catch (error) {
          setState(() {
            _isUploading = false;
          });
          _scaffoldKey.currentState.showSnackBar(
              new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
        }
      }
    }
  }

  Future _uploadImage(File image) async {
    setState(() {
      _isUploading = true;
    });
    String token = await storage.read(key: 'token');

    String fileName = image.path.split('/').last;
    FormData data = new FormData();
    if (_description != null) {
      data = FormData.fromMap({
        "id": id,
        "description": _description,
        "g_location_lat": lat,
        "g_location_long": lng,
        "files[]": await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        ),
      });
    } else {
      data = FormData.fromMap({
        "id": id,
        "g_location_lat": lat,
        "g_location_long": lng,
        "files[]": await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        ),
      });
    }

    Dio dio = new Dio();
    dio.options.headers['Accept'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    Response response = await dio.post(
      '${endPoint}api/v1/charts/stored',
      data: data,
    );
    if (response.statusCode != 200) {
      return null;
    } else {
      await apiProvider.sendNotifyToWebAndMobile(token, id);
      final res = response.data;
      return res;
    }
  }

  Widget showImage() {
    return _image != null
        ? Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlineButton(
                      onPressed: () => deleteImage(),
                      borderSide:
                          BorderSide(color: Theme.of(context).accentColor),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.delete),
                              SizedBox(
                                width: 5.0,
                              ),
                              Text(
                                'ลบ',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: (isVideo)
                        ? ChewieListItem(
                            videoPlayerController:
                                VideoPlayerController.file(_image),
                          )
                        : Image.file(_image),
                  ),
                ],
              ),
            ],
          )
        : _geolocation != null
            ? Container(
                width: MediaQuery.of(context).size.width,
                height: 200.0,
                child: Card(
                  child: GoogleMap(
                    mapType: MapType.hybrid,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat ?? 13.7894338, lng ?? 100.5858793),
                      zoom: 14.4746,
                    ),
                    markers: Set<Marker>.of(markers.values),
                  ),
                ),
              )
            : Text('');
  }

  void deleteImage() {
    setState(() {
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text('เพิ่มข้อมูลการรักษา'),
        leading: IconButton(
          icon: Icon(Icons.close),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _startUploading();
            },
          ),
        ],
      ),
      body: Card(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: ListView(
            children: <Widget>[
              Container(
                height: 60.0,
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                        icon: Icon(Icons.add_a_photo),
                        onPressed: () {
                          _openImagePickerModal(context);
                        }),
                    IconButton(
                        icon: Icon(Icons.crop_original),
                        onPressed: () {
                          setState(() {
                            isVideo = false;
                          });
                          getImageGarally(ImageSource.gallery);
                        }),
                    IconButton(
                        icon: _geolocation != null
                            ? Icon(Icons.location_off)
                            : Icon(Icons.location_on),
                        onPressed: () {
                          _getLocation();
                        }),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: _isUploading
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          )
                        : null,
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          isLoding
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: CircularProgressIndicator())
                              : Row(
                                  children: <Widget>[
                                    Column(
                                      children: <Widget>[
                                        CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(_images),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                '$_prefix $_name $_surname',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: _geolocation != null
                                                    ? Text(
                                                        'อยู่ที่ Lat $_lat , Long $_lng',
                                                        style: TextStyle(
                                                            fontSize: 14),
                                                      )
                                                    : Text(''),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                          SizedBox(
                            height: 5.0,
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: new TextFormField(
                                  autofocus: true,
                                  controller: description,
                                  onChanged: ((String description) {
                                    setState(() {
                                      _description = description;
                                    });
                                  }),
                                  decoration: InputDecoration(
                                    hintText: 'รายละเอียด',
                                    border: InputBorder.none,
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 5,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                          showImage(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

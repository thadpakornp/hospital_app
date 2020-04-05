import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:geolocator/geolocator.dart';

import 'chewie_list_item.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  ApiProvider apiProvider = ApiProvider();

  bool _isUploading = false;
  File _image;
  String _description;
  bool isVideo = false;
  var _golocation;
  final storage = new FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  var description = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future _getLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _golocation = position;
    });
  }

  //========================= Gellary / Camera AlerBox
  void _openImagePickerModal(BuildContext context) {
    final flatButtonColor = Theme.of(context).primaryColor;
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 200.0,
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
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('คลังรูปภาพ'),
                  onPressed: () {
                    setState(() {
                      isVideo = false;
                    });
                    getImage(ImageSource.gallery);
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
      Navigator.pop(context);
    });
  }

  Future getVideo(ImageSource source) async {
    var image = await ImagePicker.pickVideo(source: source);

    setState(() {
      _image = image;
      Navigator.pop(context);
    });
  }

  //============================================================= API Area to upload image
  void _startUploading() async {
    if (_description == null && _image == null) {
      final snackBar = SnackBar(content: Text('ไม่พบข้อมูลให้บันทึก'));
      Scaffold.of(context).showSnackBar(snackBar);
    } else {
      if (_image != null) {
        final response = await _uploadImage(_image);
        setState(() {
          _isUploading = false;
        });
        if (response == null) {
          final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
          Scaffold.of(context).showSnackBar(snackBar);
        } else {
          final snackBar = SnackBar(content: Text(response['data']));
          Scaffold.of(context).showSnackBar(snackBar);
        }
      } else {
        //Call Api image is null
        setState(() {
          _isUploading = true;
        });
        String token = await storage.read(key: 'token');

        try {
          final response =
              await apiProvider.uploadWithOutFile(token, _description);
          setState(() {
            _isUploading = false;
          });
          if (response.statusCode == 200) {
            var jsonResponse = json.decode(response.body);
            if (jsonResponse['code'] == '200') {
              setState(() {
                _description = null;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => description.clear());
                _formKey.currentState.reset();
              });
            }
            final snackBar = SnackBar(content: Text(jsonResponse['data']));
            Scaffold.of(context).showSnackBar(snackBar);
          } else {
            final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
            Scaffold.of(context).showSnackBar(snackBar);
          }
        } catch (error) {
          setState(() {
            _isUploading = false;
          });
          final snackBar =
              SnackBar(content: Text('ไม่สามารถเชื่อมต่อ API ได้'));
          Scaffold.of(context).showSnackBar(snackBar);
        }
      }
    }
  }

  void _resetState() {
    setState(() {
      _description = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => description.clear());
      _image = null;
      _formKey.currentState.reset();
    });
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
        "description": _description,
        "files[]": await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        ),
      });
    } else {
      data = FormData.fromMap({
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
      'http://192.168.101.63/api/v1/charts/uploaded',
      data: data,
    );
    if (response.statusCode != 200) {
      return null;
    } else {
      _resetState();
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
        : Center(child: Text('No Selected'));
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
        title: Text('บันทึกข้อมูลเข้าระบบ'),
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
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'ที่ตั้ง : $_golocation',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 5.0,
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: new TextFormField(
                                  controller: description,
                                  onChanged: ((String description) {
                                    setState(() {
                                      _description = description;
                                    });
                                  }),
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () => WidgetsBinding.instance
                                          .addPostFrameCallback(
                                              (_) => description.clear()),
                                      alignment: Alignment.topRight,
                                    ),
                                    filled: true,
                                    hintText: 'รายละเอียด (ไม่จำเป็น)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 5,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlineButton(
                                  onPressed: () =>
                                      _openImagePickerModal(context),
                                  borderSide: BorderSide(
                                      color: Theme.of(context).accentColor,
                                      width: 1.0),
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(Icons.camera_alt),
                                          SizedBox(
                                            width: 5.0,
                                          ),
                                          Text('เพิ่มรูปภาพหรือวิดีโอ'),
                                        ],
                                      ),
                                    ],
                                  ),
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'chewie_list_item.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isUploading = false;
  File _image;
  String _description = '';
  bool isVideo = false;

  final _formKey = GlobalKey<FormState>();
  var description = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

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
        final Map<String, dynamic> response = await _uploadImage(_image);
        setState(() {
          _isUploading = false;
        });
        if (response == null || response.containsKey(("error"))) {
          //error
          final snackBar = SnackBar(content: Text(response['data']));
          Scaffold.of(context).showSnackBar(snackBar);
        } else {
          // success
          final snackBar = SnackBar(content: Text(response['data']));
          Scaffold.of(context).showSnackBar(snackBar);
        }
      } else {
        //Call Api image is null
        setState(() {
          _isUploading = true;
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = await prefs.get('access_token');
        final url = 'http://192.168.101.50/api/v1/charts/uploaded';
        Map<String, String> headers = {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        };
        final response = await http.post(
          url,
          headers: headers,
          body: {
            "description": _description ?? null,
          },
        );
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

  Future<Map<String, dynamic>> _uploadImage(File image) async {
    setState(() {
      _isUploading = true;
    });
    Uri apiUrl = Uri.parse('http://192.168.101.85/api/v1/charts/uploaded');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = await prefs.get('access_token');

    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };

    final mimeTypeData =
    lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');

    // Intilize the multipart request
    final imageUploadRequest = http.MultipartRequest('POST', apiUrl);

    // Attach the file in the request
    final file = await http.MultipartFile.fromPath('image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

    imageUploadRequest.headers.addAll(headers);
    imageUploadRequest.files.add(file);
    if (_description != null || _description != '') {
      imageUploadRequest.fields['description'] = _description;
    }
    imageUploadRequest.fields['ext'] = mimeTypeData[1];

    try {
      final streamedResponse = await imageUploadRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      print(response.statusCode);
      if (response.statusCode != 200) {
        return null;
      }
      final Map<String, dynamic> responseData = json.decode(response.body);
      _resetState();
      return responseData;
    } catch (e) {
      print(e);
      return null;
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

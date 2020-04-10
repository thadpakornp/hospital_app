import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ApiProvider apiProvider = ApiProvider();
  var profile;
  bool isLoding = true;
  String _mySelection;
  List prefixs = List();
  File _image;
  bool _isUploading = false;
  final storage = new FlutterSecureStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  TextEditingController _name = TextEditingController();
  TextEditingController _surname = TextEditingController();
  TextEditingController _phone = TextEditingController();
  TextEditingController _email = TextEditingController();

  Future _getPrefix() async {
    try {
      final rs = await apiProvider.getPrefix();
      if (rs.statusCode == 200) {
        var jsonResponse = json.decode(rs.body);
        setState(() {
          prefixs = jsonResponse['data'];
        });
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (e) {
      print(e);
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: Text('ไม่สามารถเชื่อมต่อ API ได้')));
    }
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
          _name.text = profile['name'];
          _surname.text = profile['surname'];
          _phone.text = profile['phone'];
          _email.text = profile['email'];
          _mySelection = profile['prefix']['id'];
        });
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (e) {
      print(e);
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: Text('ไม่สามารถเชื่อมต่อ API ได้')));
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getProfile();
    _getPrefix();
  }

  Future getImage(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);
    setState(() {
      _image = image;
      Navigator.pop(context);
    });
  }

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
                  child: Text('กล้องถ่ายภาพ'),
                  onPressed: () {
                    getImage(ImageSource.camera);
                  },
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('คลังรูปภาพ'),
                  onPressed: () {
                    getImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        });
  }

  Future _saved() async {
    setState(() {
      _isUploading = true;
    });
    String token = await storage.read(key: 'token');
    FormData data = new FormData();

    if (_image == null) {
      data = FormData.fromMap({
        'prefix_id': _mySelection.toString(),
        'name': _name.text,
        'surname': _surname.text,
        'phone': _phone.text,
      });
    } else {
      data = FormData.fromMap({
        'prefix_id': _mySelection.toString(),
        'name': _name.text,
        'surname': _surname.text,
        'phone': _phone.text,
        "profile": await MultipartFile.fromFile(
          _image.path,
          filename: _image.path.split('/').last,
        ),
      });
    }

    Dio dio = new Dio();
    dio.options.headers['Accept'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    Response response = await dio.post(
      'http://159.65.14.78/api/v1/users/updated',
      data: data,
    );
    setState(() {
      _isUploading = false;
    });
    if (response.statusCode == 200) {
      var rs = response.data;
      if (rs['code'] == '200') {
        setState(() {
          _getProfile();
          _getPrefix();
        });
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text(rs['data'])));
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text(rs['data'])));
      }
    } else {
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: Text('ไม่สามารถเชื่อมต่อ API ได้')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('แก้ไขข้อมูลผู้ใช้งาน'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              _saved();
            },
          ),
        ],
      ),
      body: isLoding
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Card(
                child: Column(
                  children: <Widget>[
                    Center(
                      child: _isUploading
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            )
                          : null,
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Center(
                      child: CircleAvatar(
                        radius: 80.0,
                        backgroundImage: _image != null
                            ? FileImage(_image)
                            : NetworkImage(profile['profile']),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Center(
                      child: GestureDetector(
                        child: Text(
                          'เปลี่ยนรูปโปรไฟล์',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          _openImagePickerModal(context);
                        },
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        child: Column(
                          children: <Widget>[
                            Align(
                              alignment: Alignment.topLeft,
                              child: new Text(
                                'อีเมลผู้ใช้งาน',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    enabled: false,
                                    controller: _email,
                                    decoration: InputDecoration(
                                      hintText: 'อีเมล',
                                      filled: true,
                                      prefixIcon: Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                start: 10.0),
                                        child: Icon(Icons.email),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: new Text(
                                'ข้อมูลส่วนตัว',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Row(
                              children: <Widget>[
                                Text(
                                  'คำนำหน้า : ',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Center(
                                  child: new DropdownButton(
                                    items: prefixs.map((item) {
                                      return new DropdownMenuItem(
                                        child: new Text(item['name']),
                                        value: item['id'].toString(),
                                      );
                                    }).toList(),
                                    onChanged: (newVal) {
                                      setState(() {
                                        _mySelection = newVal;
                                      });
                                    },
                                    value: _mySelection,
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
                                  child: TextFormField(
                                    controller: _name,
                                    decoration: InputDecoration(
                                      hintText: 'ชื่อ',
                                      filled: true,
                                      prefixIcon: Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                start: 10.0),
                                        child: Icon(Icons.person),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
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
                                  child: TextFormField(
                                    controller: _surname,
                                    decoration: InputDecoration(
                                      hintText: 'นามสกุล',
                                      filled: true,
                                      prefixIcon: Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                start: 10.0),
                                        child: Icon(Icons.person),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
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
                                  child: TextFormField(
                                    controller: _phone,
                                    decoration: InputDecoration(
                                      hintText: 'เบอร์โทรติดต่อ',
                                      filled: true,
                                      prefixIcon: Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                start: 10.0),
                                        child: Icon(Icons.phone_iphone),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    textAlign: TextAlign.start,
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
              ),
            ),
    );
  }
}

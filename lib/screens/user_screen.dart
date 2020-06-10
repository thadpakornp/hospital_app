import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/login_screen.dart';
import 'package:hospitalapp/screens/password_change.dart';
import 'package:hospitalapp/screens/profile_screen.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  ApiProvider apiProvider = ApiProvider();

  bool _isProfile = false;

  String _email;
  String _name;
  String _surname;
  String _img;
  String _prefix;
  String _phone;
  String _type;
  String _office;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final storage = new FlutterSecureStorage();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getProfile();
  }

  Future getProfile() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getProfile(token);
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['code'] == '200') {
          setState(() {
            _email = jsonResponse['data']['email'];
            _name = jsonResponse['data']['name'];
            _surname = jsonResponse['data']['surname'];
            _img = jsonResponse['data']['profile'];
            _prefix = jsonResponse['data']['prefix']['name'];
            _phone = jsonResponse['data']['phone'];
            _type = jsonResponse['data']['type'];
            _office = jsonResponse['data']['office']['name'];
            _isProfile = true;
          });
        } else {
          _scaffoldKey.currentState
              .showSnackBar(new SnackBar(content: Text(jsonResponse['data'])));
        }
      }
    } catch (e) {
      print(e);
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
    }
  }

  Future doLogout(BuildContext context) async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.doLogout(token);
      if (response.statusCode == 200) {
        await storage.deleteAll();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (error) {
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
    }
  }

  @override
  Widget build(BuildContext context) {
    void _showDialog() {
      // flutter defined function
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("ยืนยัน"),
            content: new Text("ต้องการออกระบบ"),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text("ยกเลิก"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text("ตกลง"),
                onPressed: () {
                  doLogout(context);
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('โปรไฟล์'),
        elevation: 0,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _isProfile
                ? Container(
                    padding: EdgeInsets.only(top: 16),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 2,
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(32),
                          bottomLeft: Radius.circular(32)),
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                      fit: BoxFit.fill,
                                      image: NetworkImage(_img)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 25),
                          child: Text(
                            "$_type".toUpperCase(),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 28),
                          child: Text(
                            '$_prefix $_name $_surname',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    '$_phone',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              Column(
                                children: <Widget>[
                                  Icon(
                                    Icons.email,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    '$_email',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Text(
                            '$_office',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : CircularProgressIndicator(),
            Container(
              height: MediaQuery.of(context).size.height / 3,
              padding: EdgeInsets.all(42),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new ProfileScreen()),
                          ).then((value) {
                            if (value != null) {
                              setState(() {
                                _isProfile = false;
                                getProfile();
                              });
                              _scaffoldKey.currentState.showSnackBar(
                                  new SnackBar(content: Text(value)));
                            }
                          });
                        },
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.account_circle,
                              color: Colors.black,
                            ),
                            Text(
                              'แก้ไขข้อมูล',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new passwordChange()),
                          ).then((value) {
                            if (value != null) {
                              _scaffoldKey.currentState.showSnackBar(
                                  new SnackBar(content: Text(value)));
                            }
                          });
                        },
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.vpn_key,
                              color: Colors.black,
                            ),
                            Text(
                              'เปลี่ยนรหัสผ่าน',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showDialog();
                        },
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.exit_to_app,
                              color: Colors.red,
                            ),
                            Text(
                              'ออกจากระบบ',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

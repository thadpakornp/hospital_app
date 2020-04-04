import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ApiProvider apiProvider = ApiProvider();
  var profile;
  bool isLoding = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  TextEditingController _name = TextEditingController();
  TextEditingController _surname = TextEditingController();
  TextEditingController _phone = TextEditingController();
  TextEditingController _email = TextEditingController();

  Future _getProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = await prefs.get('access_token');
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
        });
      } else {
        final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    } catch (e) {
      print(e);
      final snackBar = SnackBar(content: Text('ไม่สามารถเชื่อมต่อ API ได้'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getProfile();
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
            onPressed: () {},
          ),
        ],
      ),
      body: isLoding
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Card(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 10.0,
                    ),
                    Center(
                      child: CircleAvatar(
                        radius: 80.0,
                        backgroundImage: NetworkImage(profile['profile']),
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
                          print('t');
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';

class passwordChange extends StatefulWidget {
  @override
  _passwordChangeState createState() => _passwordChangeState();
}

class _passwordChangeState extends State<passwordChange> {
  ApiProvider apiProvider = ApiProvider();
  bool isLoding = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final storage = new FlutterSecureStorage();

  TextEditingController _oldPassword = TextEditingController();
  TextEditingController _newPassword1 = TextEditingController();
  TextEditingController _newPassword2 = TextEditingController();

  Future _changePassword() async {
    String token = await storage.read(key: 'token');
    setState(() {
      isLoding = false;
    });
    try {
      final response = await apiProvider.changePassword(
          token, _oldPassword.text, _newPassword1.text, _newPassword2.text);
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['code'] == '200') {
          Navigator.of(context).pop(jsonResponse['data']);
        }
        _resetState();
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text(jsonResponse['data'])));
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

  void _resetState() {
    setState(() {
      _formKey.currentState.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) => _oldPassword.clear());
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _newPassword1.clear());
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _newPassword2.clear());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('เปลี่ยนรหัสผ่าน'),
        leading: IconButton(
          icon: Icon(Icons.close),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Card(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 20.0,
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: new Text(
                          'รหัสผ่านเดิม',
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
                              controller: _oldPassword,
                              validator: (value) {
                                if (value.isEmpty) {
                                  _scaffoldKey.currentState.showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'รหัสผ่านเดิมไม่สามารถว่างได้')));
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'รหัสผ่านเดิม',
                                filled: true,
                                prefixIcon: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 10.0),
                                  child: Icon(Icons.vpn_key),
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
                          'รหัสผ่านใหม่',
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
                              controller: _newPassword1,
                              validator: (value) {
                                if (value.isEmpty) {
                                  _scaffoldKey.currentState.showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'รหัสผ่านใหม่ไม่สามารถว่างได้')));
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'รหัสผ่านใหม่',
                                filled: true,
                                prefixIcon: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 10.0),
                                  child: Icon(Icons.vpn_key),
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
                          'รหัสผ่านใหม่อีกครั้ง',
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
                              controller: _newPassword2,
                              validator: (value) {
                                if (value.isEmpty) {
                                  _scaffoldKey.currentState.showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'ยืนยันรหัสผ่านใหม่อีกครั้ง')));
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'รหัสผ่านใหม่อีกครั้ง',
                                filled: true,
                                prefixIcon: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 10.0),
                                  child: Icon(Icons.vpn_key),
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
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: RaisedButton(
                              child: Text(
                                'เปลี่ยนรหัสผ่าน',
                                style: TextStyle(color: Colors.white),
                              ),
                              color: Colors.pink,
                              onPressed: () {
                                if (_formKey.currentState.validate()) {
                                  setState(() {
                                    isLoding = true;
                                  });
                                  _changePassword();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: isLoding
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

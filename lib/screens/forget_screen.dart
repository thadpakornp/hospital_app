import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/login_screen.dart';

class ForgetScreen extends StatefulWidget {
  @override
  _ForgetScreenState createState() => _ForgetScreenState();
}

class _ForgetScreenState extends State<ForgetScreen> {
  ApiProvider apiProvider = ApiProvider();

  bool isLoading = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextEditingController ctrlEmail = TextEditingController();

  Future doForget() async {
    if (ctrlEmail.text == '') {
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('กรุณาระบุอีเมล')));
    } else {
      setState(() {
        isLoading = true;
      });
      try {
        final response = await apiProvider.doForget(ctrlEmail.text);
        setState(() {
          isLoading = false;
        });
        if (response.statusCode == 200) {
          final status = json.decode(response.body);
          if (status['code'] != '200') {
            _scaffoldKey.currentState
                .showSnackBar(new SnackBar(content: Text(status['data'])));
          } else {
            Navigator.of(context).pop(status['data']);
          }
        }
      } catch (e) {
        print(e);
        setState(() {
          isLoading = false;
        });
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.lightBlueAccent, Colors.indigoAccent],
                  ),
                  borderRadius:
                      BorderRadius.only(bottomLeft: Radius.circular(90))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Spacer(),
                  Align(
                    alignment: Alignment.center,
                    child: Image(
                      width: 200.0,
                      height: 200.0,
                      image: AssetImage('assets/images/logo.png'),
                    ),
                  ),
                  Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32, right: 32),
                      child: Text(
                        'Surat Stroke Fast Track'.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.only(top: 62),
              child: Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width / 1.2,
                    height: 45,
                    padding:
                        EdgeInsets.only(top: 4, left: 16, right: 16, bottom: 4),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ]),
                    child: TextField(
                      controller: ctrlEmail,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.email,
                          color: Colors.grey,
                        ),
                        hintText: 'อีเมลผู้ใช้งาน',
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    height: 45,
                    width: MediaQuery.of(context).size.width / 1.2,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.lightBlueAccent, Colors.indigoAccent],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Center(
                      child: !isLoading
                          ? GestureDetector(
                              onTap: () {
                                doForget();
                              },
                              child: Text(
                                'รีเซ็ตรหัสผ่าน',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : CircularProgressIndicator(
                              valueColor: new AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    height: 45,
                    width: MediaQuery.of(context).size.width / 1.2,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFf45d27), Color(0xFFf5851f)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'กลับหน้าล็อคอิน',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

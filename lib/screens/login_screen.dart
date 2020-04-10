import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String device_token;
  ApiProvider apiProvider = ApiProvider();
  final storage = new FlutterSecureStorage();
  final TextEditingController ctrlEmail = TextEditingController();
  final TextEditingController ctrlPassword = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool isLoading = false;

  void initFirebaseMessaging() async {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        //ได้รับ push notify จาก FCM
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        //เมื่อกด notify แล้วไปที่ไหน
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        //คล้ายกับ OnLauncher
        print("onResume: $message");
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      setState(() {
        device_token = token;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    initFirebaseMessaging();
    checkPermission();
    checkToken();
  }

  Future checkPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.storage,
      Permission.microphone,
      Permission.notification
    ].request();
  }

  Future doLogin() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiProvider.doLogin(
          ctrlEmail.text, ctrlPassword.text, device_token);
      setState(() {
        isLoading = false;
      });
      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        if (status['code'] != '200') {
          //error
          final snackBar = SnackBar(content: Text(status['data']));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        } else {
          await storage.write(key: 'token', value: status['data']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  Future<bool> checkToken() async {
    String token = await storage.read(key: 'token');
    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            color: Colors.pink,
          ),
          ListView(
            children: <Widget>[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image(
                      width: 200.0,
                      height: 200.0,
                      image: AssetImage('assets/images/logo.png'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Form(
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: ctrlEmail,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                filled: true,
                                fillColor: Colors.white70,
                              ),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            TextFormField(
                              controller: ctrlPassword,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.vpn_key),
                                filled: true,
                                fillColor: Colors.white70,
                              ),
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: isLoading
                                  ? CircularProgressIndicator()
                                  : null,
                            ),
                            Material(
                              borderRadius:
                                  BorderRadius.all(const Radius.circular(30.0)),
                              shadowColor: Colors.yellowAccent.shade100,
                              elevation: 5.0,
                              child: MaterialButton(
                                minWidth: 290.0,
                                height: 55.0,
                                onPressed: () {
                                  doLogin();
                                },
                                color: Colors.yellow,
                                child: Text('Login'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

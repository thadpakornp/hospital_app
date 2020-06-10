import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hospitalapp/chats/chat_screen.dart';
import 'package:hospitalapp/screens/charts_user_screen.dart';
import 'package:hospitalapp/screens/user_screen.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_provider.dart';
import 'charts_month_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ApiProvider apiProvider = ApiProvider();

  int currentIndex = 0;
  List pages = [
    ChartsMonthScreen(),
    UserScreen(),
  ];

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void initFirebaseMessaging() async {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        showNotification(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        int id = int.tryParse(message['data']['id']);
        if (id == 0) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ChatScreen()));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChartsUserScreen(
                id,
              ),
            ),
          );
        }
      },
      onResume: (Map<String, dynamic> message) async {
        int id = int.tryParse(message['data']['id']);
        if (id == 0) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ChatScreen()));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChartsUserScreen(
                id,
              ),
            ),
          );
        }
      },
    );
  }

  Future _checkVersion() async {
    try {
      final response = await apiProvider.getVersion();
      if (response.statusCode == 200) {
        final jsonRs = json.decode(response.body);
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String version = packageInfo.version;
        if (version != jsonRs['data']) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: new Text("พบเวอร์ชั่นใหม่"),
                  content: new Text(
                      "แอพนี้ได้รับการเปลี่ยนแปลง กรุณาอัปเดทเพื่อใช้งานต่อ"),
                  actions: <Widget>[
                    // usually buttons at the bottom of the dialog
                    new FlatButton(
                      child: new Text("ภายหลัง"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    new FlatButton(
                      child: new Text("อัปเดทตอนนี้"),
                      onPressed: _launchURL,
                    ),
                  ],
                );
              });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  _launchURL() async {
    const url =
        'https://play.google.com/store/apps/details?id=com.imatthio.hospitalapp';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkVersion();
    initFirebaseMessaging();
    var android = new AndroidInitializationSettings('app_icon');
    var ios = new IOSInitializationSettings();
    var initSettings = new InitializationSettings(android, ios);
    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) {
    int id = int.tryParse(payload);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChartsUserScreen(
          id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 5,
        backgroundColor: Colors.green,
        child: Icon(Icons.message),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey,
        shape: CircularNotchedRectangle(),
        notchMargin: 7.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.view_list,
                  color: currentIndex == 0 ? Colors.pink : Colors.black45),
              onPressed: () {
                setState(() {
                  currentIndex = 0;
                });
              },
            ),
            SizedBox(width: 25),
            IconButton(
              icon: Icon(Icons.person_outline,
                  color: currentIndex == 1 ? Colors.pink : Colors.black45),
              onPressed: () {
                setState(() {
                  currentIndex = 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  showNotification(message) async {
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        priority: Priority.High, importance: Importance.Max);
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android, iOS);
    await flutterLocalNotificationsPlugin.show(
        0,
        message['notification']['title'],
        message['notification']['body'],
        platform,
        payload: message['data']['id']);
  }
}

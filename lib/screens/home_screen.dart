import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hospitalapp/screens/charts_screen.dart';
import 'package:hospitalapp/screens/charts_user_screen.dart';
import 'package:hospitalapp/screens/upload_screen.dart';
import 'package:hospitalapp/screens/user_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  List pages = [
    ChartsScreen(),
    UploadScreen(),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChartsUserScreen(
              message['data']['key'],
            ),
          ),
        );
      },
      onResume: (Map<String, dynamic> message) async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChartsUserScreen(
              message['data']['key'],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
    Widget bottomNavBar = BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.accessibility),
            title: Text('ระเบียนผู้ป่วย'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            title: Text('บันทึกข้อมูลเข้าระบบ'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text('ตั้งค่า'),
          ),
        ]);

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: bottomNavBar,
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
        payload: message['data']['key']);
  }
}

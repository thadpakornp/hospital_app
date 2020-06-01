import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hospitalapp/chats/chat_screen.dart';
import 'package:hospitalapp/screens/charts_screen.dart';
import 'package:hospitalapp/screens/charts_user_screen.dart';
import 'package:hospitalapp/screens/user_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  List pages = [
    ChartsScreen(),
    UserScreen(),
    ChatScreen(),
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

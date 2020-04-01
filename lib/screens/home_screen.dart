import 'package:flutter/material.dart';
import 'package:hospitalapp/screens/charts_screen.dart';
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
}

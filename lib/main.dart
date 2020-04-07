import 'package:flutter/material.dart';
import 'package:hospitalapp/screens/login_screen.dart';

void main() {
  runApp(HomePage());
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Saraban',
        scaffoldBackgroundColor: Colors.white70,
        primaryColor: Colors.pink,
        accentColor: Colors.amber,
      ),
      title: 'IMATTHIO',
      home: LoginScreen(),
    );
  }
}

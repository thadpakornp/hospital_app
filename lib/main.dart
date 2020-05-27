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
        primarySwatch: Colors.deepOrange,
      ),
      title: 'IMATTHIO',
      home: LoginScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hospitalapp/screens/login_screen.dart';

void main() {
  runApp(HomePage());
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Saraban',
        primarySwatch: Colors.blue,
      ),
      title: 'IMATTHIO',
      home: LoginScreen(),
    );
  }
}

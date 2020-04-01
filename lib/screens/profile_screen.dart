import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  int id;

  ProfileScreen(this.id);
  @override
  _ProfileScreenState createState() => _ProfileScreenState(id);
}

Widget _appbar() {
  return Row(
    children: <Widget>[
      Column(
        children: <Widget>[
          Text('กลับ'),
          Text('กลับ'),
        ],
      ),
    ],
  );
}

class _ProfileScreenState extends State<ProfileScreen> {
  int id;

  _ProfileScreenState(this.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลผู้ป่วย'),
      ),
      body: Text('$id'),
    );
  }
}

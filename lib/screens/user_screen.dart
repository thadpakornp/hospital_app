import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/login_screen.dart';
import 'package:hospitalapp/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

ApiProvider apiProvider = ApiProvider();

Future doLogout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String access_token = await prefs.get('access_token');

  try {
    final response = await apiProvider.doLogout(access_token);
    if (response.statusCode == 200) {
      bool remove_token = await prefs.remove('access_token');
      if (remove_token) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
    } else {
      final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  } catch (error) {
    print(error);
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Row(
          children: <Widget>[
            new Text('ไม่สามารถเชื่อมต่อ API ได้'),
          ],
        ),
      ),
    );
  }
}



class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {

    void _showDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("ยืนยัน"),
          content: new Text("ต้องการออกระบบ"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("ยกเลิก"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("ตกลง"),
              onPressed: () {
                doLogout(context);
                
              },
            ),
          ],
        );
      },
    );
  }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text('ตั้งค่าการใช้งาน'),
      ),
      body: Card(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('ข้อมูลส่วนตัว'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (context)=> ProfileScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.vpn_key),
              title: Text('เปลี่ยนรหัสผ่าน'),
              trailing: Icon(Icons.keyboard_arrow_right),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.error),
              title: Text('เกี่ยวกับ'),
              trailing: Icon(Icons.keyboard_arrow_right),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('ออกจากระบบ'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
                _showDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}

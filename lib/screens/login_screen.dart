import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ApiProvider apiProvider = ApiProvider();

  final TextEditingController ctrlEmail = TextEditingController();
  final TextEditingController ctrlPassword = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool isLoading = false;

  Future doLogin() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await apiProvider.doLogin(ctrlEmail.text, ctrlPassword.text);
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
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('access_token', status['data']);
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = await prefs.get('access_token');
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
  void initState() {
    // TODO: implement initState
    super.initState();
    checkToken();
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/charts_user_screen.dart';

class ChartsScreen extends StatefulWidget {
  @override
  _ChartsScreenState createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ApiProvider apiProvider = ApiProvider();
  final storage = new FlutterSecureStorage();
  var charts;
  bool isLoding = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Future<Null> _getCharts() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getCharts(token);
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          isLoding = false;
          charts = jsonResponse['data'];
        });
      } else {
        final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    } catch (error) {
      final snackBar = SnackBar(content: Text('ไม่สามารถเชื่อมต่อ API ได้'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCharts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text('ระเบียนผู้ป่วย'),
      ),
      body: isLoding
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _getCharts,
              child: Card(
                child: ListView.builder(
                  itemCount: charts != null ? charts.length : 0,
                  itemBuilder: (context, int index) {
                    return Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                        height: 110,
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage('${charts[index]['profile']}'),
                            ),
                            title: Text(
                                '${charts[index]['prefix']} ${charts[index]['name']} ${charts[index]['surname']}'),
                            subtitle: Text('${charts[index]['address']}'),
                            trailing: Icon(Icons.keyboard_arrow_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChartsUserScreen(
                                    charts[index]['id'],
                                    charts[index]['prefix'],
                                    charts[index]['name'],
                                    charts[index]['surname'],
                                    charts[index]['hn'],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

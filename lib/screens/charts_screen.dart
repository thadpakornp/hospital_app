import 'dart:convert';

import 'package:flutter/cupertino.dart';
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

  String _status = 'all';
  var charts;

  bool isLoding = true;

  final Color accentColor = Color(0XFFFA2B0F);
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final storage = new FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _getCharts();
  }

  Future<Null> _getCharts() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getCharts(token, _status);
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          charts = jsonResponse['data'];
          isLoding = false;
        });
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (error) {
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
    }
  }

  Widget _buildTitle() {
    return Text(
      "แฟ้มประวัติผู้ป่วย",
      style: TextStyle(
          fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBottomCard(double width, double height) {
    return Container(
      width: width,
      height: height / 3,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(16), topLeft: Radius.circular(16))),
    );
  }

  Widget _buildCardsList() {
    return RefreshIndicator(
      onRefresh: _getCharts,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
        child: ListView.builder(
          itemCount: charts != null ? charts.length : 0,
          itemBuilder: (context, int index) {
            return Padding(
              padding: const EdgeInsets.all(0.7),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35.0),
                child: Container(
                  height: 110,
                  child: Card(
                    color: Color(0xFF1E8161),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage('${charts[index]['profile']}'),
                      ),
                      title: Text(
                        '${charts[index]['prefix']} ${charts[index]['name']} ${charts[index]['surname']}',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '${charts[index]['address']}',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      trailing: Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.white,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChartsUserScreen(
                              charts[index]['id'],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[300],
        title: _buildTitle(),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                isLoding = true;
                _status = 'all';
                _getCharts();
              });
            },
            icon: Icon(
              Icons.dashboard,
              color: _status == 'all' ? Colors.pink : Colors.blueGrey,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                isLoding = true;
                _status = 'Activate';
                _getCharts();
              });
            },
            icon: Icon(
              Icons.schedule,
              color: _status == 'Activate' ? Colors.pink : Colors.blueGrey,
            ),
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.only(top: 16),
        child: Stack(
          children: <Widget>[
            Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomCard(width, height)),
            isLoding
                ? Center(child: CircularProgressIndicator())
                : _buildCardsList(),
          ],
        ),
      ),
    );
  }
}

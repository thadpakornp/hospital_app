import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/charts_user_screen.dart';

class ChartsScreen extends StatefulWidget {
  String date_value;

  ChartsScreen(this.date_value);
  @override
  _ChartsScreenState createState() => _ChartsScreenState(date_value);
}

class _ChartsScreenState extends State<ChartsScreen> {
  String date_value;

  _ChartsScreenState(this.date_value);

  ApiProvider apiProvider = ApiProvider();

  String _status = 'all';
  var charts;
  int hn = 0;

  bool isLoding = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final storage = new FlutterSecureStorage();
  TextEditingController _searchQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCharts();
  }

  Future<Null> _getCharts() async {
    String token = await storage.read(key: 'token');
    try {
      final response =
          await apiProvider.getCharts(token, date_value, hn, _status);
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
                    color: Colors.indigo,
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
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
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  if (value == null || value == '') {
                    _scaffoldKey.currentState.showSnackBar(
                        new SnackBar(content: Text('กรุณาระบุหมายเลข HN')));
                  } else {}
                },
                controller: _searchQueryController,
                decoration: InputDecoration(
                    hintText: "ค้นหาด้วยหมายเลข HN",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)))),
              ),
            ),
            isLoding
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: _buildCardsList(),
                  ),
          ],
        ),
      ),
    );
  }
}

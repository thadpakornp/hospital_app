import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';

import 'charts_user_screen.dart';

class ChartsMonthScreen extends StatefulWidget {
  @override
  _ChartsMonthScreenState createState() => _ChartsMonthScreenState();
}

class _ChartsMonthScreenState extends State<ChartsMonthScreen> {
  ApiProvider apiProvider = ApiProvider();

  var mouths;

  bool isLoding = false;
  bool _isSearching = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final storage = new FlutterSecureStorage();
  TextEditingController _searchQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

//  Future<Null> _getMonths() async {
//    String token = await storage.read(key: 'token');
//    try {
//      final response = await apiProvider.getMonths(token);
//      if (response.statusCode == 200) {
//        var jsonResponse = json.decode(response.body);
//        setState(() {
//          mouths = jsonResponse['data'];
//          isLoding = false;
//        });
//      } else {
//        _scaffoldKey.currentState
//            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
//      }
//    } catch (error) {
//      _scaffoldKey.currentState
//          .showSnackBar(new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
//    }
//  }

  Widget _buildTitle() {
    return Text(
      "แฟ้มประวัติผู้ป่วย",
      style: TextStyle(
          fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
    );
  }

  Future _searching() async {
    setState(() {
      _isSearching = true;
    });
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getMonthsFromSeach(
          token, _searchQueryController.text);
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] == null) {
          _scaffoldKey.currentState
              .showSnackBar(new SnackBar(content: Text('ไม่พบข้อมูลที่ค้นหา')));
          setState(() {
            mouths = null;
            _isSearching = false;
          });
        } else {
          setState(() {
            mouths = jsonResponse['data'];
            _isSearching = false;
          });
        }
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (error) {
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
    }
  }

  Widget _buildCardsList() {
    return _isSearching
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
            child: ListView.builder(
              itemCount: mouths != null ? mouths.length : 0,
              itemBuilder: (context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(0.7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35.0),
                    child: Container(
                      height: 70,
                      child: Card(
                        color: Colors.indigo,
                        child: ListTile(
                          title: Text(
                            '${mouths[index]['date_thai']}',
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
                                  mouths[index]['id'],
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
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: _buildTitle(),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 5.0),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _searching();
                  }
                },
                controller: _searchQueryController,
                decoration: InputDecoration(
                    hintText: "ค้นหาด้วยหมายเลข HN",
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          _searchQueryController.clear();
                          setState(() {
                            mouths = null;
                          });
                        }),
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

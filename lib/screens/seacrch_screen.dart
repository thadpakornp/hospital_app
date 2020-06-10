import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_provider.dart';
import 'charts_user_screen.dart';

class searchScreen extends StatefulWidget {
  @override
  _searchScreenState createState() => _searchScreenState();
}

class _searchScreenState extends State<searchScreen> {
  ApiProvider apiProvider = ApiProvider();
  TextEditingController _searchQueryController = TextEditingController();
  bool _isSearching = false;
  var mouths;
  String prefix = '';
  String name = '';
  String surname = '';
  final storage = new FlutterSecureStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

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
            prefix = '';
            name = '';
            surname = '';
          });
        } else {
          setState(() {
            mouths = jsonResponse['data'];
            _isSearching = false;
            prefix = jsonResponse['charts_info']['prefix'];
            name = jsonResponse['charts_info']['name'];
            surname = jsonResponse['charts_info']['surname'];
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
        : ListView.builder(
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
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        title: Text('ค้นหาแฟ้มประวัติ'),
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  if (value == null || value == '') {
                    _scaffoldKey.currentState.showSnackBar(
                        new SnackBar(content: Text('กรุณาระบุหมายเลข HN')));
                  } else {
                    _searching();
                  }
                },
                controller: _searchQueryController,
                decoration: InputDecoration(
                    hintText: "ค้นหาด้วยหมายเลข HN",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)))),
              ),
            ),
            prefix == ''
                ? Container()
                : Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      'ผลการค้นหา: $prefix$name $surname',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
            Expanded(
              child: _buildCardsList(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hospitalapp/resources/chart_files.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:video_player/video_player.dart";

import 'add_charts_description_screen.dart';
import 'chewie_list_item.dart';

class ChartsUserHistoryScreen extends StatefulWidget {
  int id;
  String prefix;
  String name;
  String surname;
  String hn;

  ChartsUserHistoryScreen(
      this.id, this.prefix, this.name, this.surname, this.hn);

  @override
  _ChartsUserHistoryScreen createState() =>
      _ChartsUserHistoryScreen(id, prefix, name, surname, hn);
}

class _ChartsUserHistoryScreen extends State<ChartsUserHistoryScreen> {
  ApiProvider apiProvider = ApiProvider();

  int id;
  String prefix;
  String name;
  String surname;
  String hn;
  bool isLoding = true;
  var chart_lasted;
  var chart_status;
  var charts_date;

  _ChartsUserHistoryScreen(
      this.id, this.prefix, this.name, this.surname, this.hn);

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Future _success() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = await prefs.get('access_token');

    try {
      final response = await apiProvider.successCharts(token, id);
      if (response.statusCode == 200) {
        setState(() {
          _getChart();
        });
        final snackBar = SnackBar(content: Text('สิ้นสุดการรักษาแล้ว'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      } else {
        final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    } catch (error) {
      final snackBar = SnackBar(content: Text('เชื่อมต่อ API ไม่ได้'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  Future<Null> _getChart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = await prefs.get('access_token');

    try {
      final response = await apiProvider.getChartsByID(token, id);
      setState(() {
        isLoding = false;
      });
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          chart_lasted = jsonResponse['data']['lasted'];
          chart_status = jsonResponse['data']['charts_status'][0]['status'];
          charts_date = jsonResponse['data']['charts_date'];
        });
      } else {
        final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
        Scaffold.of(context).showSnackBar(snackBar);
      }
    } catch (error) {
      final snackBar = SnackBar(content: Text('เชื่อมต่อ API ไม่ได้'));
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  Future _getFiles(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = await prefs.get('access_token');

    try {
      final response = await apiProvider.getFile(token, id);
      if (response.statusCode == 200) {
        final articles2 = json.decode(response.body);
        final articles = articles2['data'];
        return articles.map((article) => Article.fromJSON(article)).toList();
      }
    } catch (error) {
      final snackBar = SnackBar(content: Text('เชื่อมต่อ API ไม่ได้'));
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  Widget _video(String files) {
    final String file = files.replaceAll('temnails', 'photos');
    return ChewieListItem(
      videoPlayerController: VideoPlayerController.network('$file'),
    );
  }

  Widget _files(int id) {
    return FutureBuilder(
      future: _getFiles(id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text(snapshot.error));
        return (snapshot.hasData)
            ? ListView.builder(
                scrollDirection:
                    snapshot.data.length > 1 ? Axis.horizontal : Axis.vertical,
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  final files = snapshot.data[index];
                  if (files.type_files == 'mp4') {
                    return _video(files.files);
                  } else {
                    return _image(files.files);
                  }
                },
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _image(String files) {
    return GestureDetector(
      child: Hero(
        tag: 'imageHero$files',
        child: Image.network(files),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) {
          return DetailScreen(files);
        }));
      },
    );
  }

  Widget DetailScreen(String files) {
    final String file = files.replaceAll('temnails', 'photos');
    return GestureDetector(
      child: Center(
        child: Hero(
          tag: 'imageHero$file',
          child: Image.network(
            file,
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes
                      : null,
                ),
              );
            },
          ),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  void _showDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("ยืนยัน"),
          content: new Text("การรักษาเสร็จสิ้นแล้วใช่หรือไม่"),
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
                _success();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getChart();
  }

  @override
  Widget build(BuildContext context) {
    Widget _getFAB() {
      return SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22),
        backgroundColor: Color(0xFF801E48),
        visible: true,
        curve: Curves.bounceIn,
        children: [
          // FAB 1
          SpeedDialChild(
              child: Icon(Icons.add),
              backgroundColor: Color(0xFF801E48),
              onTap: () {
                Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => new AddChartDescription(id)),
                ).then((value) {
                  setState(() {
                    _getChart();
                  });
                });
              },
              label: 'บันทึกการรักษา',
              labelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 16.0),
              labelBackgroundColor: Color(0xFF801E48)),

          SpeedDialChild(
              child: Icon(Icons.check),
              backgroundColor: Color(0xFF801E48),
              onTap: () {
                _showDialog();
              },
              label: 'สิ้นสุดการรักษา',
              labelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 16.0),
              labelBackgroundColor: Color(0xFF801E48))
        ],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('$prefix $name $surname HN $hn'),
      ),
      body: isLoding
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _getChart,
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: ListView.builder(
                  itemCount: chart_lasted.length ?? 0,
                  itemBuilder: (context, int index) {
                    return Card(
                      child: Column(
                        children: <Widget>[
                          Container(
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                    '${chart_lasted[index]['add_by_user']['profile']}'),
                              ),
                              title: Text(
                                  '${chart_lasted[index]['add_by_user']['prefix']['name']} ${chart_lasted[index]['add_by_user']['name']} ${chart_lasted[index]['add_by_user']['surname']}'),
                              subtitle:
                                  Text('${chart_lasted[index]['created_at']}'),
                              trailing: Icon(Icons.more_horiz),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(5.0),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${chart_lasted[index]['description']}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  chart_lasted[index]['files'] != null
                                      ? Container(
                                          height: 200,
                                          child:
                                              _files(chart_lasted[index]['id']),
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: chart_status == 'Activate' ? _getFAB() : null,
    );
  }
}

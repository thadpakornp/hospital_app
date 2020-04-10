import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hospitalapp/resources/chart_files.dart';
import 'package:hospitalapp/screens/add_charts_description_screen.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/charts_map_screen.dart';
import "package:video_player/video_player.dart";

import 'chewie_list_item.dart';

class ChartsUserScreen extends StatefulWidget {
  int id;
  ChartsUserScreen(this.id);

  @override
  _ChartsUserScreenState createState() => _ChartsUserScreenState(id);
}

class _ChartsUserScreenState extends State<ChartsUserScreen> {
  ApiProvider apiProvider = ApiProvider();

  int id;
  String prefix = '';
  String name = '';
  String surname = '';
  String hn = '';
  bool isLoding = true;
  var chart_lasted;
  var chart_status;
  var charts_date;
  var charts_info;

  _ChartsUserScreenState(this.id);
  final storage = new FlutterSecureStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Future _success() async {
    String token = await storage.read(key: 'token');

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

  Future _deleted(int id) async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.deletedCharts(token, id);
      if (response.statusCode == 200) {
        final jsonRs = json.decode(response.body);
        if (jsonRs['code'] == '200') {
          setState(() {
            _getChart();
          });
          final snackBar = SnackBar(content: Text('ลบเรียบร้อยแล้ว'));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        } else {
          final snackBar = SnackBar(content: Text(jsonRs['data']));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
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
    String token = await storage.read(key: 'token');

    try {
      final response = await apiProvider.getChartsByID(token, id);
      setState(() {
        isLoding = false;
      });
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          charts_info = jsonResponse['data']['charts_info'];
          prefix = jsonResponse['data']['charts_info']['prefix'];
          name = jsonResponse['data']['charts_info']['name'];
          surname = jsonResponse['data']['charts_info']['surname'];
          hn = jsonResponse['data']['charts_info']['hn'];
          chart_lasted = jsonResponse['data']['lasted'];
          chart_status = jsonResponse['data']['charts_status'][0]['status'];
          charts_date = jsonResponse['data']['charts_date'];
        });
      } else {
        final snackBar = SnackBar(content: Text('เกิดข้อผิดพลาด'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      }
    } catch (error) {
      final snackBar = SnackBar(content: Text('เชื่อมต่อ API ไม่ได้'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  Future _getFiles(int id) async {
    String token = await storage.read(key: 'token');

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
                  if (files.type_files == 'mp4' || files.type_files == 'MOV') {
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
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Hero(
          tag: 'imageHero$files',
          child: Image.network(files),
        ),
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) {
          return _detailScreen(files);
        }));
      },
    );
  }

  Widget _detailScreen(String files) {
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

  Widget _calendar(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 300.0,
            child: Column(
              children: <Widget>[
                Stack(children: [
                  Container(
                    height: 56.0,
                    child: Center(
                        child: Text('ประวัติการรักษา') // Your desired title
                        ),
                  ),
                  Positioned(
                      left: 0.0,
                      top: 5.0,
                      child: IconButton(
                          icon: Icon(Icons.close), // Your desired icon
                          onPressed: () {
                            Navigator.of(context).pop();
                          })),
                ]),
                Stack(
                  children: <Widget>[
                    Container(
                      height: 220.0,
                      child: ListView.builder(
                        itemCount: charts_date.length ?? 0,
                        itemBuilder: (context, int index) {
                          return FlatButton(
                            onPressed: () {
                              setState(() {
                                id = charts_date[index]['id'];
                                isLoding = true;
                                _getChart();
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 40.0,
                              child: Center(
                                  child: Text(
                                charts_date[index]['created_at'],
                                style: (id == charts_date[index]['id'])
                                    ? TextStyle(color: Colors.pink)
                                    : TextStyle(color: Colors.black),
                              ) // Your desired title
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  Widget _profileFull(String files) {
    return GestureDetector(
      child: Center(
        child: Hero(
          tag: 'imageHero$files',
          child: Image.network(
            files,
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

  Widget _profile(BuildContext context) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 500,
            child: Column(
              children: <Widget>[
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 56.0,
                      child: Center(
                          child: Text('ข้อมูลผู้ป่วย') // Your desired title
                          ),
                    ),
                    Positioned(
                        left: 0.0,
                        top: 5.0,
                        child: IconButton(
                            icon: Icon(Icons.close), // Your desired icon
                            onPressed: () {
                              Navigator.of(context).pop();
                            }))
                  ],
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SingleChildScrollView(
                    dragStartBehavior: DragStartBehavior.start,
                    scrollDirection: Axis.vertical,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            GestureDetector(
                              child: Hero(
                                tag: 'imageHero${charts_info['profile']}',
                                child: CircleAvatar(
                                  radius: 70,
                                  backgroundImage:
                                      NetworkImage(charts_info['profile']),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) {
                                  return _profileFull(charts_info['profile']);
                                }));
                              },
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'สถานะ: ',
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                                charts_info['status'] == 'Activate'
                                    ? Row(
                                        children: <Widget>[
                                          Text(
                                            'อยู่ระหว่างการรักษา ',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          new IconTheme(
                                            data: new IconThemeData(
                                                color: Colors.red),
                                            child: new Icon(Icons.domain),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: <Widget>[
                                          Text(
                                            'สิ้นสุดการรักษา ',
                                            style:
                                                TextStyle(color: Colors.green),
                                          ),
                                          new IconTheme(
                                            data: new IconThemeData(
                                                color: Colors.green),
                                            child: new Icon(Icons.home),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              '$prefix $name $surname',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'HN $hn',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: 15.0,
                            ),
                            Text(
                              'เบอร์ติดต่อ: ${charts_info['phone']}',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              'ที่อยู่: ${charts_info['address']}',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getChart();
  }

  void _showDialogDeleted(int id) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("ยืนยัน"),
          content: new Text("ต้องการลบรายการที่เลือก?"),
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
                _deleted(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
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
                    isLoding = true;
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
          // FAB 2
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
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              _calendar(context);
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              _profile(context);
            },
          ),
        ],
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
                              trailing: Wrap(
                                spacing: 0,
                                children: <Widget>[
                                  IconButton(
                                    alignment: Alignment.centerRight,
                                    icon: Icon(
                                      Icons.near_me,
                                      color: (chart_lasted[index]
                                                  ['g_location_lat']) !=
                                              null
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      (chart_lasted[index]['g_location_lat']) !=
                                              null
                                          ? Navigator.of(context).push(MaterialPageRoute(
                                              builder: (context) => chartsMapScreen(
                                                  num.tryParse(chart_lasted[index]
                                                          ['g_location_lat'])
                                                      .toDouble(),
                                                  num.tryParse(chart_lasted[index]
                                                          ['g_location_long'])
                                                      .toDouble())))
                                          : _scaffoldKey.currentState
                                              .showSnackBar(SnackBar(
                                                  content: Text('ไม่พบเส้นทาง')));
                                    },
                                  ),
                                  IconButton(
                                    alignment: Alignment.centerRight,
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      _showDialogDeleted(
                                          chart_lasted[index]['id']);
                                    },
                                  ),
                                ],
                              ),
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
                                      : chart_lasted[index]['g_location_lat'] !=
                                              null
                                          ? Container(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 200.0,
                                              child: GoogleMap(
                                                mapType: MapType.hybrid,
                                                initialCameraPosition:
                                                    CameraPosition(
                                                  target: LatLng(
                                                      num.tryParse(chart_lasted[
                                                                      index][
                                                                  'g_location_lat'])
                                                              .toDouble() ??
                                                          13.7894338,
                                                      num.tryParse(chart_lasted[
                                                                      index][
                                                                  'g_location_long'])
                                                              .toDouble() ??
                                                          100.5858793),
                                                  zoom: 14.4746,
                                                ),
                                              ),
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

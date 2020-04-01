import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hospitalapp/resources/chart_files.dart';
import 'package:hospitalapp/screens/add_charts_description_screen.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:video_player/video_player.dart";

import 'chewie_list_item.dart';

class ChartsUserScreen extends StatefulWidget {
  int id;
  String prefix;
  String name;
  String surname;
  String hn;

  ChartsUserScreen(this.id, this.prefix, this.name, this.surname, this.hn);

  @override
  _ChartsUserScreenState createState() =>
      _ChartsUserScreenState(id, prefix, name, surname, hn);
}

class _ChartsUserScreenState extends State<ChartsUserScreen> {
  ApiProvider apiProvider = ApiProvider();

  int id;
  String prefix;
  String name;
  String surname;
  String hn;
  bool isLoding = true;
  var chart_lasted;
  var chart_status;

  _ChartsUserScreenState(
      this.id, this.prefix, this.name, this.surname, this.hn);

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
                          icon: Icon(Icons.arrow_back), // Your desired icon
                          onPressed: () {
                            Navigator.of(context).pop();
                          })),
                ]),
              ],
            ),
          );
        });
  }

  Widget _profile(BuildContext context) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 400,
            child: Column(
              children: <Widget>[
                Stack(children: [
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
                          icon: Icon(Icons.arrow_back), // Your desired icon
                          onPressed: () {
                            Navigator.of(context).pop();
                          }))
                ]),
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

  @override
  Widget build(BuildContext context) {
    Widget floatingBar = FloatingActionButton(
      backgroundColor: Colors.blue,
      tooltip: 'เพิ่มจ้อมูล',
      onPressed: () {
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
      child: Icon(Icons.add),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('$prefix $name $surname HN $hn'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              _calendar(context);
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
      floatingActionButton: chart_status == 'Activate' ? floatingBar : null,
    );
  }
}

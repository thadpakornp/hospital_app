import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/charts_map_screen.dart';
import 'package:hospitalapp/screens/chewie_list_item_copy.dart';
import 'package:hospitalapp/screens/map_screen.dart';
import 'package:hospitalapp/screens/play_video.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ApiProvider apiProvider = ApiProvider();

  bool _showBottom = false;
  bool isLoding = true;
  bool isUpload = false;

  var _isMe;
  var chats;
  var _isDate;
  File _image;
  double lat;
  double lng;
  String _description;
  String url = "https://suratstroke.com/public/assets/img/temnails/";
  String url2 = "https://suratstroke.com/public/assets/img/photos/";
  String endPoint = 'https://suratstroke.com/';

  List<IconData> icons = [
    Icons.camera_alt,
    Icons.videocam,
    Icons.image,
    Icons.location_on,
  ];

  ScrollController _scrollController = ScrollController();
  var description = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final storage = new FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    getID();
    getChats();
  }

  void _switch(int i) {
    switch (i) {
      case 0:
        {
          getFileAttactImage(ImageSource.camera);
        }
        break;
      case 1:
        {
          getFileAttactVideo(ImageSource.camera);
        }
        break;
      case 2:
        {
          getFileAttactImage(ImageSource.gallery);
        }
        break;
      case 3:
        {
          onSendLocation();
        }
        break;
    }
  }

  Future saveLocation() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.uploadWithOutFile(
          token, '', lat.toString(), lng.toString());
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['code'] == '200') {
          description.clear();
          await apiProvider.sendNotifyToWeb(token);
          setState(() {
            getChats();
            lat = null;
            lng = null;
            _showBottom = false;
          });
        } else {
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text(jsonResponse['data'])));
        }
      } else {
        _scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (e) {
      print(e);
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
    }
  }

  Future getFileAttactVideo(ImageSource source) async {
    var image = await ImagePicker.pickVideo(source: source);
    if (image != null) {
      setState(() {
        _image = image;
      });
      uploadFile();
    }
  }

  Future getFileAttactImage(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _image = image;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    setState(() {
      isUpload = true;
    });
    String token = await storage.read(key: 'token');
    String fileName = _image.path.split('/').last;
    FormData data = new FormData();
    data = FormData.fromMap({
      "g_location_lat": lat,
      "g_location_long": lng,
      "type_charts": "1",
      "files[]": await MultipartFile.fromFile(
        _image.path,
        filename: fileName,
      ),
    });
    Dio dio = new Dio();
    dio.options.headers['Accept'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    Response response = await dio.post(
      '${endPoint}api/v1/charts/uploaded',
      data: data,
    );
    if (response.statusCode != 200) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text('การส่งเกิดข้อผิดพลาด')));
    } else {
      await apiProvider.sendNotifyToWeb(token);
      setState(() {
        isUpload = false;
        _showBottom = false;
        getChats();
      });
    }
  }

  Widget _loading() {
    return Positioned(
      child: Container(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xfff5a623)),
          ),
        ),
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }

  Future<void> onSendLocation() async {
    bool isLocationEnabled = await Geolocator().isLocationServiceEnabled();
    if (isLocationEnabled) {
      if (await Permission.locationAlways.request().isGranted ||
          await Permission.locationWhenInUse.request().isGranted) {
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => mapScreen()),
        ).then((value) {
          if (value != null) {
            setState(() {
              lat = value.target.latitude;
              lng = value.target.longitude;
            });
            saveLocation();
          }
        });
      } else {
        _scaffoldKey.currentState.showSnackBar(
            new SnackBar(content: Text('กรุณาอนุญาตให้เข้าถึงที่ตั้งของคุณ')));
      }
    } else {
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: Text('กรุณาเปิดการเข้าถึงที่ตั้งของคุณ')));
    }
  }

  Future<void> onSendMessage() async {
    if (_description == null) {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text('กรุณาพิมพ์รายละเอียด')));
    } else {
      String token = await storage.read(key: 'token');
      try {
        final response = await apiProvider.uploadWithOutFile(
            token, _description, lat.toString(), lng.toString());
        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          if (jsonResponse['code'] == '200') {
            description.clear();
            await apiProvider.sendNotifyToWeb(token);
            setState(() {
              getChats();
            });
          } else {
            _scaffoldKey.currentState
                .showSnackBar(SnackBar(content: Text(jsonResponse['data'])));
          }
        } else {
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด')));
        }
      } catch (e) {
        print(e);
        _scaffoldKey.currentState.showSnackBar(
            new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
      }
    }
  }

  Widget geolocate(double _lat, double _lng) {
    return FutureBuilder(
        future: _geolocate(_lat, _lng),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: <Widget>[
                Icon(Icons.location_on),
                Text(
                  snapshot.data,
                  style: Theme.of(context).textTheme.body2.apply(
                        color: Colors.black,
                      ),
                ),
              ],
            );
          } else {
            return Text(
              'ไม่สามารถระบุข้อมูลที่ตั้งได้',
              style: Theme.of(context).textTheme.body2.apply(
                    color: Colors.black,
                  ),
            );
          }
        });
  }

  Future _geolocate(double _lat, double _lng) async {
    List<Placemark> newPlace =
        await Geolocator().placemarkFromCoordinates(_lat, _lng);
    Placemark placeMark = newPlace[0];
    String name = placeMark.name;
    String subLocality = placeMark.subLocality;
    String locality = placeMark.locality;
    String administrativeArea = placeMark.administrativeArea;
    String postalCode = placeMark.postalCode;
    String country = placeMark.country;
    String address =
        "${name} ${subLocality} ${locality} ${administrativeArea} ${country} ${postalCode}";
    return address;
  }

  Future getID() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getID(token);
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          _isMe = jsonResponse['data'];
        });
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (e) {
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: Text('ไม่สามารถเชื่อมต่อ API ได้')));
    }
  }

  Future<Null> getChats() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getChats(token);
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          chats = jsonResponse['data'];
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

  @override
  Widget build(BuildContext context) {
    if (!isLoding) {
      Timer(
          Duration(milliseconds: 300),
          () => _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: new Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Surat Stroke Fast Track'),
        leading: IconButton(
          icon: Icon(Icons.close),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoding
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                  ],
                ),
              ],
            )
          : Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(4),
                          itemCount: chats.length ?? 0,
                          itemBuilder: (context, int i) {
                            _isDate = chats[i]['created_at'];
                            if (chats[i]['add_by_user']['id'] == _isMe) {
                              //ส่งข้อความ
                              return Column(
                                children: <Widget>[
                                  _isDate == null
                                      ? Container()
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(4.0),
                                            ),
                                          ),
                                          child: Text(
                                            _isDate,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 7.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              "${chats[i]['timed_at']}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2
                                                  .apply(color: Colors.grey),
                                            ),
                                            SizedBox(width: 3),
                                            Container(
                                              constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          .8),
                                              padding: chats[i]['files'] == null
                                                  ? const EdgeInsets.all(15.0)
                                                  : null,
                                              decoration: chats[i]['files'] ==
                                                      null
                                                  ? BoxDecoration(
                                                      color: chats[i]
                                                                  ['files'] ==
                                                              null
                                                          ? Colors.blue
                                                          : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(25),
                                                        topRight:
                                                            Radius.circular(25),
                                                        bottomLeft:
                                                            Radius.circular(25),
                                                      ),
                                                    )
                                                  : null,
                                              child: Column(
                                                children: <Widget>[
                                                  chats[i]['files'] == null
                                                      ? (chats[i]['g_location_lat'] ==
                                                                  null &&
                                                              chats[i][
                                                                      'g_location_long'] ==
                                                                  null)
                                                          ? chats[i]['description'] ==
                                                                  ''
                                                              ? Text(
                                                                  'ข้อความนี้ถูกลบแล้ว',
                                                                  style:
                                                                      TextStyle(
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                    color: Colors
                                                                        .blueGrey,
                                                                  ),
                                                                )
                                                              : Text(
                                                                  "${chats[i]['description']}",
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .body2
                                                                      .apply(
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                )
                                                          : GestureDetector(
                                                              onLongPress: () {
                                                                Navigator.of(context).push(MaterialPageRoute(
                                                                    builder: (context) => chartsMapScreen(
                                                                        num.tryParse(chats[i]['g_location_lat'])
                                                                            .toDouble(),
                                                                        num.tryParse(chats[i]['g_location_long'])
                                                                            .toDouble())));
                                                              },
                                                              child: geolocate(
                                                                  num.tryParse(chats[
                                                                              i]
                                                                          [
                                                                          'g_location_lat'])
                                                                      .toDouble(),
                                                                  num.tryParse(
                                                                          chats[i]
                                                                              [
                                                                              'g_location_long'])
                                                                      .toDouble()),
                                                            )
                                                      : (chats[i]['files'][
                                                                      'type_files'] ==
                                                                  'mp4' ||
                                                              chats[i]['files'][
                                                                      'type_files'] ==
                                                                  'MOV')
                                                          ? GestureDetector(
                                                              onLongPress: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        PlayVideo(
                                                                            '$url2${chats[i]['files']['files']}'),
                                                                  ),
                                                                );
                                                              },
                                                              child:
                                                                  ChewieListItem(
                                                                videoPlayerController:
                                                                    VideoPlayerController
                                                                        .network(
                                                                            '$url2${chats[i]['files']['files']}'),
                                                                looping: false,
                                                              ),
                                                            )
                                                          : GestureDetector(
                                                              onLongPress: () {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (_) {
                                                                  return _detailScreen(
                                                                      '$url${chats[i]['files']['files']}');
                                                                }));
                                                              },
                                                              child:
                                                                  CachedNetworkImage(
                                                                fit: BoxFit
                                                                    .cover,
                                                                imageUrl:
                                                                    '$url${chats[i]['files']['files']}',
                                                                placeholder: (context,
                                                                        url) =>
                                                                    CircularProgressIndicator(),
                                                                errorWidget: (context,
                                                                        url,
                                                                        error) =>
                                                                    Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          15.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .grey,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .only(
                                                                      topLeft: Radius
                                                                          .circular(
                                                                              25),
                                                                      topRight:
                                                                          Radius.circular(
                                                                              25),
                                                                      bottomLeft:
                                                                          Radius.circular(
                                                                              25),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    'รูปภาพถูกลบแล้ว',
                                                                    style:
                                                                        TextStyle(
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .italic,
                                                                      color: Colors
                                                                          .blueGrey,
                                                                    ),
                                                                  ),
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
                                  ),
                                ],
                              );
                            } else {
                              //รับข้อความ
                              return Column(
                                children: <Widget>[
                                  _isDate == null
                                      ? Container()
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(4.0),
                                            ),
                                          ),
                                          child: Text(
                                            _isDate,
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 7.0),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black12
                                                      .withOpacity(.3),
                                                  offset: Offset(0, 2),
                                                  blurRadius: 5)
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                '${chats[i]['add_by_user']['profile']}'),
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              "${chats[i]['add_by_user']['name']} ${chats[i]['add_by_user']['surname']}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption,
                                            ),
                                            Container(
                                              constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          .7),
                                              padding: chats[i]['files'] == null
                                                  ? const EdgeInsets.all(15.0)
                                                  : const EdgeInsets.all(0.0),
                                              decoration: chats[i]['files'] ==
                                                      null
                                                  ? BoxDecoration(
                                                      color: chats[i]
                                                                  ['files'] !=
                                                              null
                                                          ? Colors.white
                                                          : Colors.black12,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(25),
                                                        topRight:
                                                            Radius.circular(25),
                                                        bottomLeft:
                                                            Radius.circular(25),
                                                      ),
                                                    )
                                                  : null,
                                              child: Column(
                                                children: <Widget>[
                                                  chats[i]['files'] == null
                                                      ? (chats[i]['g_location_lat'] ==
                                                                  null &&
                                                              chats[i][
                                                                      'g_location_long'] ==
                                                                  null)
                                                          ? chats[i]['description'] ==
                                                                  ''
                                                              ? Text(
                                                                  'ข้อความนี้ถูกลบแล้ว',
                                                                  style:
                                                                      TextStyle(
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                    color: Colors
                                                                        .blueGrey,
                                                                  ),
                                                                )
                                                              : Text(
                                                                  "${chats[i]['description']}",
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .body2
                                                                      .apply(
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                )
                                                          : GestureDetector(
                                                              onLongPress: () {
                                                                Navigator.of(context).push(MaterialPageRoute(
                                                                    builder: (context) => chartsMapScreen(
                                                                        num.tryParse(chats[i]['g_location_lat'])
                                                                            .toDouble(),
                                                                        num.tryParse(chats[i]['g_location_long'])
                                                                            .toDouble())));
                                                              },
                                                              child: geolocate(
                                                                  num.tryParse(chats[
                                                                              i]
                                                                          [
                                                                          'g_location_lat'])
                                                                      .toDouble(),
                                                                  num.tryParse(
                                                                          chats[i]
                                                                              [
                                                                              'g_location_long'])
                                                                      .toDouble()),
                                                            )
                                                      : (chats[i]['files'][
                                                                      'type_files'] ==
                                                                  'mp4' ||
                                                              chats[i]['files'][
                                                                      'type_files'] ==
                                                                  'MOV')
                                                          ? GestureDetector(
                                                              onLongPress: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        PlayVideo(
                                                                            '$url2${chats[i]['files']['files']}'),
                                                                  ),
                                                                );
                                                              },
                                                              child:
                                                                  ChewieListItem(
                                                                videoPlayerController:
                                                                    VideoPlayerController
                                                                        .network(
                                                                            '$url2${chats[i]['files']['files']}'),
                                                                looping: false,
                                                              ),
                                                            )
                                                          : GestureDetector(
                                                              onLongPress: () {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (_) {
                                                                  return _detailScreen(
                                                                      '$url${chats[i]['files']['files']}');
                                                                }));
                                                              },
                                                              child:
                                                                  CachedNetworkImage(
                                                                fit: BoxFit
                                                                    .cover,
                                                                imageUrl:
                                                                    '$url${chats[i]['files']['files']}',
                                                                placeholder: (context,
                                                                        url) =>
                                                                    CircularProgressIndicator(),
                                                                errorWidget: (context,
                                                                        url,
                                                                        error) =>
                                                                    Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          15.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .black12,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .only(
                                                                      topLeft: Radius
                                                                          .circular(
                                                                              25),
                                                                      topRight:
                                                                          Radius.circular(
                                                                              25),
                                                                      bottomLeft:
                                                                          Radius.circular(
                                                                              25),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    'รูปภาพถูกลบแล้ว',
                                                                    style:
                                                                        TextStyle(
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .italic,
                                                                      color: Colors
                                                                          .blueGrey,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          "${chats[i]['timed_at']}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .body2
                                              .apply(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(15.0),
                        height: 61,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(35.0),
                                  boxShadow: [
                                    BoxShadow(
                                        offset: Offset(0, 3),
                                        blurRadius: 5,
                                        color: Colors.grey)
                                  ],
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 15.0),
                                        child: TextField(
                                          controller: description,
                                          decoration: InputDecoration(
                                              hintText: "Aa...",
                                              border: InputBorder.none),
                                          onChanged: ((String description) {
                                            setState(() {
                                              _description = description;
                                            });
                                          }),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: InkWell(
                                        onLongPress: () {
                                          onSendMessage();
                                        },
                                        child: Icon(
                                          Icons.send,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.all(15.0),
                              decoration: BoxDecoration(
                                  color: Colors.green, shape: BoxShape.circle),
                              child: InkWell(
                                child: Icon(
                                  Icons.attach_file,
                                  color: Colors.white,
                                ),
                                onLongPress: () {
                                  setState(() {
                                    _showBottom = true;
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showBottom = false;
                      });
                    },
                  ),
                ),
                _showBottom
                    ? Positioned(
                        bottom: 90,
                        left: 25,
                        right: 25,
                        child: Container(
                          padding: EdgeInsets.all(25.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  offset: Offset(0, 5),
                                  blurRadius: 15.0,
                                  color: Colors.grey)
                            ],
                          ),
                          child: GridView.count(
                            mainAxisSpacing: 21.0,
                            crossAxisSpacing: 21.0,
                            shrinkWrap: true,
                            crossAxisCount: 4,
                            children: List.generate(
                              icons.length,
                              (i) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15.0),
                                    color: Colors.grey[200],
                                    border: Border.all(
                                        color: Colors.green, width: 2),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      icons[i],
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      _switch(i);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    : Container(),
                isUpload ? _loading() : Container(),
              ],
            ),
    );
  }
}

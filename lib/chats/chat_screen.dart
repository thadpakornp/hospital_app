import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospitalapp/chats/receivedmessagewidget.dart';
import 'package:hospitalapp/chats/receivedmessagewidgetwithfile.dart';
import 'package:hospitalapp/chats/receivedmessagewidgetwithmap.dart';
import 'package:hospitalapp/chats/sentmessagewidget.dart';
import 'package:hospitalapp/chats/sentmessagewidgetwithfile.dart';
import 'package:hospitalapp/chats/sentmessagewidgetwithmap.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/map_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  SocketIO socketIO;
  ApiProvider apiProvider = ApiProvider();

  Color myGreen = Color(0xff4bb17b);

  bool _showBottom = false;
  var _isMe;
  var messages;
  File _image;
  bool _loading = true;
  String _description;
  double lat;
  double lng;

  String endPoint = 'https://suratstroke.com/';
  ScrollController _scrollController = ScrollController();
  var description = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final storage = new FlutterSecureStorage();

  List<IconData> icons = [
    Icons.image,
    Icons.photo_camera,
    Icons.videocam,
    Icons.location_on,
  ];

  @override
  void initState() {
    _getID();
    _getOldChat();
    socketIO = SocketIOManager()
        .createSocketIO('https://real-chat-suratstroke.herokuapp.com', '/');
    socketIO.init();
    socketIO.subscribe('r_message', (jsonData) {
      _getOldChat();
    });
    //Connect to the socket
    socketIO.connect();
    super.initState();
  }

  Future _getID() async {
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
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('กำลังเชื่อมต่อ...')));
    }
  }

  Future _getOldChat() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getChats(token);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          messages = data['data'];
          _loading = false;
        });
        Timer(
            Duration(milliseconds: 1300),
            () => _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 600),
                  curve: Curves.ease,
                ));
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (e) {
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('กำลังเชื่อมต่อ...')));
    }
  }

  void _switch(int i) {
    switch (i) {
      case 0:
        {
          getFileAttactImage(ImageSource.gallery);
        }
        break;
      case 1:
        {
          getFileAttactImage(ImageSource.camera);
        }
        break;
      case 2:
        {
          getFileAttactVideo(ImageSource.camera);
        }
        break;
      case 3:
        {
          onSendLocation();
        }
        break;
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

  Future getFileAttactVideo(ImageSource source) async {
    var image = await ImagePicker.pickVideo(source: source);
    if (image != null) {
      setState(() {
        _image = image;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
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
      await apiProvider.sendNotifyToWeb(token, _description);
      setState(() {
        _showBottom = false;
      });
      socketIO.sendMessage('send_message', json.encode({'message': 'ok'}));
    }
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

  Future saveLocation() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.uploadWithOutFile(
          token, '', lat.toString(), lng.toString());
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['code'] == '200') {
          description.clear();
          await apiProvider.sendNotifyToWeb(token, _description);
          setState(() {
            lat = null;
            lng = null;
            _showBottom = false;
          });
          socketIO.sendMessage('send_message', json.encode({'message': 'ok'}));
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
          .showSnackBar(new SnackBar(content: Text('กำลังเชื่อมต่อ...')));
    }
  }

  @override
  void dispose() {
    socketIO.disconnect();
    super.dispose();
  }

  Widget _buildChatView() {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Column(
            children: <Widget>[
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(15),
                        itemCount: messages.length ?? 0,
                        itemBuilder: (BuildContext context, int index) {
                          if (messages[index]['add_by_user']['id'] != _isMe) {
                            return messages[index]['files'] == null
                                ? messages[index]['description'] == '' ||
                                        messages[index]['description'] == null
                                    ? ReceivedMessagesWidgetwithmap(
                                        image: messages[index]['add_by_user']
                                            ['profile'],
                                        name:
                                            '${messages[index]['add_by_user']['name']} ${messages[index]['add_by_user']['surname']}',
                                        g_location_lat: num.tryParse(
                                                messages[index]
                                                    ['g_location_lat'])
                                            .toDouble(),
                                        g_location_long: num.tryParse(
                                                messages[index]
                                                    ['g_location_long'])
                                            .toDouble(),
                                        time: messages[index]['timed_at'],
                                      )
                                    : ReceivedMessagesWidget(
                                        image: messages[index]['add_by_user']
                                            ['profile'],
                                        name:
                                            '${messages[index]['add_by_user']['name']} ${messages[index]['add_by_user']['surname']}',
                                        description: messages[index]
                                            ['description'],
                                        time: messages[index]['timed_at'],
                                      )
                                : ReceivedMessagesWidgetwithfile(
                                    image: messages[index]['add_by_user']
                                        ['profile'],
                                    name:
                                        '${messages[index]['add_by_user']['name']} ${messages[index]['add_by_user']['surname']}',
                                    file: messages[index]['files']['files'],
                                    typefile: messages[index]['files']
                                        ['type_files'],
                                    time: messages[index]['timed_at']);
                          } else {
                            return messages[index]['files'] == null
                                ? messages[index]['description'] == '' ||
                                        messages[index]['description'] == null
                                    ? SentMessageWidgetwithmap(
                                        g_location_lat: num.tryParse(
                                                messages[index]
                                                    ['g_location_lat'])
                                            .toDouble(),
                                        g_location_long: num.tryParse(
                                                messages[index]
                                                    ['g_location_long'])
                                            .toDouble(),
                                        time: messages[index]['timed_at'],
                                      )
                                    : SentMessageWidget(
                                        description: messages[index]
                                            ['description'],
                                        time: messages[index]['timed_at'],
                                      )
                                : SentMessageWidgetwithfile(
                                    file: messages[index]['files']['files'],
                                    typefile: messages[index]['files']
                                        ['type_files'],
                                    time: messages[index]['timed_at']);
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
                                padding: const EdgeInsets.only(left: 15.0),
                                child: TextField(
                                  controller: description,
                                  decoration: InputDecoration(
                                      hintText: "Aa", border: InputBorder.none),
                                  onChanged: ((String description) {
                                    setState(() {
                                      _description = description;
                                    });
                                  }),
                                ),
                              ),
                            ),
                            InkWell(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.attach_file),
                              ),
                              onLongPress: () {
                                setState(() {
                                  _showBottom = true;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Container(
                      padding: const EdgeInsets.all(15.0),
                      decoration:
                          BoxDecoration(color: myGreen, shape: BoxShape.circle),
                      child: InkWell(
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                        onLongPress: () {
                          onSendMessage();
                        },
                      ),
                    )
                  ],
                ),
              ),
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
                            border: Border.all(color: myGreen, width: 2),
                          ),
                          child: IconButton(
                            icon: Icon(
                              icons[i],
                              color: myGreen,
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
      ],
    );
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
            await apiProvider.sendNotifyToWeb(token, _description);
            socketIO.sendMessage(
                'send_message', json.encode({'message': 'ok'}));
          } else {
            _scaffoldKey.currentState
                .showSnackBar(SnackBar(content: Text(jsonResponse['data'])));
          }
        } else {
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด')));
        }
      } catch (e) {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('กำลังเชื่อมต่อ...')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _buildChatView(),
    );
  }
}

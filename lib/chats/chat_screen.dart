import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:hospitalapp/resources/chart_files.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:hospitalapp/screens/map_screen.dart';
import 'package:hospitalapp/screens/show_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'multiple_image_update_screen.dart';
import 'mycircleavatar.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  SocketIO socketIO;
  ApiProvider apiProvider = ApiProvider();

  Color myGreen = Color(0xff4bb17b);

  bool _showBottom = false;
  bool isUpload = false;
  var _isMe;
  var messages;
  File _image;
  bool _loading = true;
  double lat;
  double lng;

  String endPoint = 'https://suratstroke.com/';
  ScrollController _scrollController = ScrollController();
  final description = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = new GlobalKey<FormState>();
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
    _getOldChats();
    socketIO = SocketIOManager()
        .createSocketIO('https://real-chat-suratstroke.herokuapp.com', '/');
    socketIO.init();
    socketIO.subscribe('r_message', (jsonData) {
      _getOldChat();
    });
    socketIO.connect();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    description.dispose();
    socketIO.disconnect();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getOldChat();
    }
  }

  Widget _buildLoding() {
    return Positioned(
      child: isUpload
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xfff5a623)),
                ),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
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

  Future _getOldChats() async {
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
            Duration(milliseconds: 1600),
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
      return null;
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
        });
        Timer(
            Duration(milliseconds: 1200),
            () => _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 400),
                  curve: Curves.ease,
                ));
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (e) {
      return null;
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
      description.clear();
      await apiProvider.sendNotifyToWeb(token, description.text ?? '');
      setState(() {
        isUpload = false;
        _showBottom = false;
      });
      _getOldChat();
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
    setState(() {
      isUpload = true;
    });
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.uploadWithOutFile(
          token, description.text ?? '', lat.toString(), lng.toString());
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['code'] == '200') {
          description.clear();
          await apiProvider.sendNotifyToWeb(token, description.text ?? '');
          setState(() {
            lat = null;
            lng = null;
            _showBottom = false;
            isUpload = false;
          });
          _getOldChat();
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
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('กำลังเชื่อมต่อ...')));
    }
  }

  Widget _gridImageReceived(
      int id, String profile, String name, String description, String time) {
    return FutureBuilder(
        future: _getImageChat(id),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * .6),
              child: Text(snapshot.error),
            );
          return (snapshot.hasData)
              ? Row(
                  children: <Widget>[
                    MyCircleAvatar(
                      imgUrl: profile,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "$name",
                          style: Theme.of(context).textTheme.caption,
                        ),
                        Container(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * .6),
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: Color(0xfff9f9f9),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(25),
                              bottomLeft: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text('$description'),
                              GridView.count(
                                shrinkWrap: true,
                                crossAxisCount:
                                    snapshot.data.length == 1 ? 1 : 2,
                                children: List.generate(
                                  snapshot.data.length ?? 0,
                                  (index) {
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ShowImage(
                                                snapshot.data[index].files),
                                          ),
                                        );
                                      },
                                      child: CachedNetworkImage(
                                        filterQuality: FilterQuality.low,
                                        imageUrl: snapshot.data[index].files,
                                        placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 15),
                    Text(
                      "$time",
                      style: Theme.of(context)
                          .textTheme
                          .body2
                          .apply(color: Colors.grey),
                    ),
                  ],
                )
              : CircularProgressIndicator();
        });
  }

  Widget _gridImageSend(int id, String description, String time) {
    return FutureBuilder(
        future: _getImageChat(id),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * .6),
              child: Text(snapshot.error),
            );
          return (snapshot.hasData)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      "$time",
                      style: Theme.of(context)
                          .textTheme
                          .body2
                          .apply(color: Colors.grey),
                    ),
                    SizedBox(width: 15),
                    Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * .6),
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: myGreen,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                          bottomLeft: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Text('$description'),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: snapshot.data.length == 1 ? 1 : 2,
                            children: List.generate(
                              snapshot.data.length ?? 0,
                              (index) {
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ShowImage(
                                            snapshot.data[index].files),
                                      ),
                                    );
                                  },
                                  child: CachedNetworkImage(
                                    filterQuality: FilterQuality.low,
                                    imageUrl: snapshot.data[index].files,
                                    placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : CircularProgressIndicator();
        });
  }

  Future _getImageChat(int id) async {
    String token = await storage.read(key: 'token');
    final response = await apiProvider.getChatImage(token, id);
    if (response.statusCode == 200) {
      final articles2 = json.decode(response.body);
      final articles = articles2['data'];
      return articles.map((article) => Article.fromJSON(article)).toList();
    }
  }

  Widget _buildChatView() {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(2),
                      itemCount: messages.length ?? 0,
                      itemBuilder: (BuildContext context, int index) {
                        return Align(
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  messages[index]['created_at'],
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey),
                                ),
                              ),
                              messages[index]['add_by_user']['id'] != _isMe
                                  ? messages[index]['files'] == null
                                      ? messages[index]['description'] == '' ||
                                              messages[index]['description'] ==
                                                  null
                                          ? ReceivedMessagesWidgetwithmap(
                                              image: messages[index]
                                                  ['add_by_user']['profile'],
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
                                              image: messages[index]
                                                  ['add_by_user']['profile'],
                                              name:
                                                  '${messages[index]['add_by_user']['name']} ${messages[index]['add_by_user']['surname']}',
                                              description: messages[index]
                                                  ['description'],
                                              time: messages[index]['timed_at'],
                                            )
                                      : messages[index]['type_desc'] == 1
                                          ? _gridImageReceived(
                                              messages[index]['id'],
                                              messages[index]['add_by_user']
                                                  ['profile'],
                                              '${messages[index]['add_by_user']['name']} ${messages[index]['add_by_user']['surname']}',
                                              messages[index]['description'],
                                              messages[index]['timed_at'])
                                          : ReceivedMessagesWidgetwithfile(
                                              image: messages[index]
                                                  ['add_by_user']['profile'],
                                              name:
                                                  '${messages[index]['add_by_user']['name']} ${messages[index]['add_by_user']['surname']}',
                                              file: messages[index]['files']
                                                  ['files'],
                                              typefile: messages[index]['files']
                                                  ['type_files'],
                                              time: messages[index]['timed_at'])
                                  : messages[index]['files'] == null
                                      ? messages[index]['description'] == '' ||
                                              messages[index]['description'] ==
                                                  null
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
                                      : messages[index]['type_desc'] == 1
                                          ? _gridImageSend(
                                              messages[index]['id'],
                                              messages[index]['description'],
                                              messages[index]['timed_at'])
                                          : SentMessageWidgetwithfile(
                                              file: messages[index]['files']
                                                  ['files'],
                                              typefile: messages[index]['files']
                                                  ['type_files'],
                                              time: messages[index]
                                                  ['timed_at']),
                            ],
                          ),
                        );
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
                          InkWell(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 15.0),
                              child: Icon(Icons.attach_file),
                            ),
                            onTap: () {
                              if (_showBottom) {
                                setState(() {
                                  _showBottom = false;
                                });
                              } else {
                                setState(() {
                                  _showBottom = true;
                                });
                              }
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextField(
                                key: _formKey,
                                controller: description,
                                decoration: InputDecoration(
                                    hintText: "Aa", border: InputBorder.none),
                              ),
                            ),
                          ),
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
                      onTap: () {
                        onSendMessage();
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
        _showBottom
            ? Positioned(
                bottom: 90,
                left: 25,
                right: 25,
                child: Container(
                  padding: EdgeInsets.all(25.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                      topLeft: Radius.circular(25),
                    ),
                    color: Colors.grey,
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
        _buildLoding(),
      ],
    );
  }

  Future<void> onSendMessage() async {
    if (description.text == null || description.text == '') {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text('กรุณาพิมพ์รายละเอียด')));
    } else {
      String token = await storage.read(key: 'token');
      try {
        final response = await apiProvider.uploadWithOutFile(
            token, description.text, lat.toString(), lng.toString());
        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          if (jsonResponse['code'] == '200') {
            await apiProvider.sendNotifyToWeb(token, description.text);
            description.clear();
            _getOldChat();
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
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) => new multipleUpdateImage()),
              ).then((value) async {
                if (value != null && value == true) {
                  String token = await storage.read(key: 'token');
                  await apiProvider.sendNotifyToWeb(token, 'สร้างอัลบั้มใหม่');
                  _getOldChat();
                  socketIO.sendMessage(
                      'send_message', json.encode({'message': 'ok'}));
                }
              });
            },
            icon: Icon(
              Icons.filter_9_plus,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: _buildChatView(),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/api_provider.dart';
import 'package:image_picker/image_picker.dart';

class multipleUpdateImage extends StatefulWidget {
  @override
  _multipleUpdateImageState createState() => _multipleUpdateImageState();
}

class _multipleUpdateImageState extends State<multipleUpdateImage> {
  String endPoint = 'https://suratstroke.com/';
  ApiProvider apiProvider = ApiProvider();
  final storage = new FlutterSecureStorage();
  final description = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = new GlobalKey<FormState>();
  List images = [];
  List<int> _uoloadID = [];
  String _error = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    description.dispose();
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(images.length ?? 0, (index) {
        File files = images[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: <Widget>[
              Image.file(
                files,
                width: 300,
                height: 300,
              ),
              Positioned(
                left: 40,
                bottom: 40,
                child: InkWell(
                  onTap: () {
                    images.remove(files);
                    setState(() {});
                  },
                  child: Icon(
                    Icons.remove_circle,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future loadAssets() async {
    String error = '';
    File resultList;
    try {
      resultList = await ImagePicker.pickImage(source: ImageSource.gallery);
    } on Exception catch (e) {
      error = e.toString();
    }
    if (resultList == null) {
      return null;
    }

    if (images.length > 9) {
      _scaffoldKey.currentState.showSnackBar(
          new SnackBar(content: Text('เพิ่มได้สูงสุด 10 รูปเท่านั้น')));
    } else {
      setState(() {
        images.add(resultList);
        _error = error;
      });
    }
  }

  Future _uploads() async {
    setState(() {
      _loading = true;
    });
    String token = await storage.read(key: 'token');
    for (File files in images) {
      String fileName = files.path.split('/').last;
      FormData data = new FormData.fromMap({
        "files": await MultipartFile.fromFile(
          files.path,
          filename: fileName,
        ),
      });
      Dio dio = new Dio();
      dio.options.headers['Accept'] = 'application/json';
      dio.options.headers["Authorization"] = "Bearer $token";
      Response response = await dio.post(
        '${endPoint}api/v1/charts/chat/uploaded',
        data: data,
      );
      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
        });
        _scaffoldKey.currentState.showSnackBar(
            new SnackBar(content: Text('การอัปโหลดเกิดข้อผิดพลาด')));
        return null;
      } else {
        final res = response.data;
        _uoloadID.add(res['data']);
        setState(() {});
      }
    }
    _lastProcess();
  }

  Future _lastProcess() async {
    String token = await storage.read(key: 'token');
    try {
      final response =
          await apiProvider.lastProcessChat(token, description.text, _uoloadID);
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _loading = false;
          _uoloadID = [];
        });
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (error) {
      print(error);
      setState(() {
        _loading = false;
      });
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text('ไม่พบสัญญาณอินเตอร์เน็ต')));
    }
  }

  Widget _buildLoding() {
    return AlertDialog(
      backgroundColor: Colors.green,
      title: new Text("กำลังอัปโหลด"),
      content: new Text(
          "กรุณาอย่าปิดแอพหรือดำเนินการใดๆจนกว่าจะดำเนินเรียบร้อยแล้ว"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('สร้างอัลบั้ม'),
        actions: <Widget>[
          IconButton(
            onPressed: () => loadAssets(),
            icon: Icon(
              Icons.add_photo_alternate,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () => _uploads(),
            icon: Icon(
              Icons.file_upload,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _error != null ? Text('$_error') : Container(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              key: _formKey,
              controller: description,
              decoration: InputDecoration(hintText: "ชื่ออัลบั้ม"),
            ),
          ),
          Expanded(
            child: buildGridView(),
          ),
          _loading ? _buildLoding() : Container(),
        ],
      ),
    );
  }
}

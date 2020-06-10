import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hospitalapp/screens/play_video.dart';
import 'package:hospitalapp/screens/show_image.dart';
import 'package:video_player/video_player.dart';

import 'api_provider.dart';
import 'chewie_list_item.dart';

class chartsImagesScreen extends StatefulWidget {
  int id;

  chartsImagesScreen(this.id);
  @override
  _chartsImagesScreenState createState() => _chartsImagesScreenState(id);
}

class _chartsImagesScreenState extends State<chartsImagesScreen> {
  int id;

  _chartsImagesScreenState(this.id);
  ApiProvider apiProvider = ApiProvider();

  bool isLoding = true;
  var chart_image;
  String prefix = '';
  String name = '';
  String surname = '';
  final storage = new FlutterSecureStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  CarouselController buttonCarouselController = CarouselController();

  @override
  void initState() {
    super.initState();
    _getInfoImage();
  }

  Future _getInfoImage() async {
    String token = await storage.read(key: 'token');
    try {
      final response = await apiProvider.getImageChart(token, widget.id);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          prefix = data['data']['charts_info']['prefix'];
          name = data['data']['charts_info']['name'];
          surname = data['data']['charts_info']['surname'];
          chart_image = data['data']['charts_files'];
          isLoding = false;
        });
      } else {
        _scaffoldKey.currentState
            .showSnackBar(new SnackBar(content: Text('เกิดข้อผิดพลาด')));
      }
    } catch (e) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: Text(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('ไฟล์ของ $prefix $name $surname'),
      ),
      body: isLoding
          ? Center(child: CircularProgressIndicator())
          : GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              children: List.generate(
                chart_image.length ?? 0,
                (index) {
                  return Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: chart_image[index]['type_files'] == 'mp4' ||
                            chart_image[index]['type_files'] == 'MOV'
                        ? InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PlayVideo(chart_image[index]['files']),
                                ),
                              );
                            },
                            child: ChewieListItem(
                              videoPlayerController:
                                  VideoPlayerController.network(
                                      chart_image[index]['files']),
                              looping: false,
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) {
                                return ShowImage(chart_image[index]['files']);
                              }));
                            },
                            child: CachedNetworkImage(
                              filterQuality: FilterQuality.low,
                              imageUrl: chart_image[index]['files'],
                              placeholder: (context, url) =>
                                  Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                  );
                },
              ),
            ),
    );
  }
}

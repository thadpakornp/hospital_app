import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hospitalapp/screens/chewie_list_item_copy.dart';
import 'package:hospitalapp/screens/play_video.dart';
import 'package:hospitalapp/screens/show_image.dart';
import 'package:video_player/video_player.dart';

class SentMessageWidgetwithfile extends StatelessWidget {
  final String file;
  final String typefile;
  final String time;
  const SentMessageWidgetwithfile(
      {@required this.file, @required this.typefile, @required this.time});

  @override
  Widget build(BuildContext context) {
    String url = "https://suratstroke.com/public/assets/img/temnails/";
    String url2 = "https://suratstroke.com/public/assets/img/photos/";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            "$time",
            style: Theme.of(context).textTheme.body2.apply(color: Colors.grey),
          ),
          SizedBox(width: 15),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * .7),
            child: typefile == 'mp4' || typefile == 'mov'
                ? InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayVideo('$url2$file'),
                        ),
                      );
                    },
                    child: ChewieListItem(
                      videoPlayerController:
                          VideoPlayerController.network('$url2$file'),
                      looping: false,
                    ),
                  )
                : InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowImage('$url$file'),
                        ),
                      );
                    },
                    child: CachedNetworkImage(
                      filterQuality: FilterQuality.low,
                      imageUrl: '$url$file',
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) =>
                              CircularProgressIndicator(
                                  value: downloadProgress.progress),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

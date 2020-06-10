import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChewieListItem extends StatefulWidget {
  // This will contain the URL/asset path which we want to play
  final VideoPlayerController videoPlayerController;
  final bool looping;

  ChewieListItem({
    @required this.videoPlayerController,
    this.looping,
    Key key,
  }) : super(key: key);

  @override
  _ChewieListItemState createState() => _ChewieListItemState();
}

class _ChewieListItemState extends State<ChewieListItem> {
  ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _chewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,
      allowFullScreen: false,
      aspectRatio: 16 / 9,
      autoInitialize: true,
      looping: widget.looping,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'ไม่พบวิดีโอหรือถูกลบไปแล้ว',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Chewie(
      controller: _chewieController,
    );
  }

//  @override
//  void dispose() {
//    widget.videoPlayerController.dispose();
//    _chewieController.dispose();
//    super.dispose();
//  }
}

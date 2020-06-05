import 'package:flutter/material.dart';

class ShowImage extends StatefulWidget {
  String url;

  ShowImage(this.url);
  @override
  _ShowImageState createState() => _ShowImageState(url);
}

class _ShowImageState extends State<ShowImage> {
  String url;

  _ShowImageState(this.url);

  @override
  Widget build(BuildContext context) {
    final String file = url.replaceAll('temnails', 'photos');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.close,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class blankScreen extends StatefulWidget {
  @override
  _blankScreenState createState() => _blankScreenState();
}

class _blankScreenState extends State<blankScreen> {
  var connect =
      IOWebSocketChannel.connect("ws://real-chat-suratstroke.herokuapp.com");

  @override
  void initState() {
    connect.stream.listen((event) {
      print(event);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            StreamBuilder(
              stream: connect.stream,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(snapshot.hasData ? '${snapshot.data}' : ''),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

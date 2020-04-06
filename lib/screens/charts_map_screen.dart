import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class chartsMapScreen extends StatefulWidget {
  double lat;
  double lng;

  chartsMapScreen(this.lat, this.lng);
  @override
  _chartsMapScreenState createState() => _chartsMapScreenState(lat, lng);
}

class _chartsMapScreenState extends State<chartsMapScreen> {
  double lat;
  double lng;
  _chartsMapScreenState(this.lat, this.lng);

  Completer<GoogleMapController> _controller = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _currectPosition();
    _add();
  }

  Future _currectPosition() async {
    _add();
    CameraPosition _myPosition = CameraPosition(
        bearing: 192.8334901395799,
        target: LatLng(lat, lng),
        tilt: 59.440717697143555,
        zoom: 19.151926040649414);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_myPosition));
  }

  void _add() {
    final MarkerId markerId = MarkerId('1');
    setState(() {
      if (markers.containsKey(markerId)) {
        markers.remove(markerId);
      }
    });
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(lat ?? 13.7248936, lng ?? 100.3529157),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(target: LatLng(lat, lng)),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: Set<Marker>.of(markers.values),
          ),
        ],
      ),
    );
  }
}

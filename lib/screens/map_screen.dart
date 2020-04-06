import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class mapScreen extends StatefulWidget {
  @override
  _mapScreenState createState() => _mapScreenState();
}

class _mapScreenState extends State<mapScreen> {
  double _lat;
  double _lng;

  double _currectlat;
  double _currectlng;

  var _currectPossition;

  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition myPosition = CameraPosition(
    target: LatLng(13.7894338, 100.5858793),
    zoom: 14.4746,
  );

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  Future gotoCurrectPosition() async {
    _currectlat = _lat;
    _currectlng = _lng;
    _add();
    CameraPosition _myPosition = CameraPosition(
        bearing: 192.8334901395799,
        target: LatLng(_lat, _lng),
        tilt: 59.440717697143555,
        zoom: 19.151926040649414);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_myPosition));
  }

  Future _getLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _lat = position.latitude ?? 13.7248936;
      _lng = position.longitude ?? 100.3529157;
    });
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
      position: LatLng(_currectlat ?? 13.7248936, _currectlng ?? 100.3529157),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getLocation();
    _add();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: myPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onCameraMove: (CameraPosition position) {
              setState(() {
                _currectPossition = position;
                _currectlat = position.target.latitude;
                _currectlng = position.target.longitude;
              });
              _add();
            },
            markers: Set<Marker>.of(markers.values),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40.0, right: 20.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.pink),
                    child: IconButton(
                      iconSize: 50,
                      color: Colors.white,
                      icon: Icon(Icons.gps_fixed),
                      onPressed: () {
                        gotoCurrectPosition();
                        _add();
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.pink),
                    child: IconButton(
                      iconSize: 50,
                      color: Colors.white,
                      icon: Icon(Icons.save),
                      onPressed: () {
                        Navigator.of(context).pop(_currectPossition);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

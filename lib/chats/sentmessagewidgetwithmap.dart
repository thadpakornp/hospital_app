import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'global.dart';

class SentMessageWidgetwithmap extends StatelessWidget {
  final double g_location_lat;
  final double g_location_long;
  final String time;
  const SentMessageWidgetwithmap(
      {@required this.g_location_lat,
      @required this.g_location_long,
      @required this.time});

  @override
  Widget build(BuildContext context) {
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
                maxWidth: MediaQuery.of(context).size.width * .6),
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: myGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomLeft: Radius.circular(25),
              ),
            ),
            child: geolocate(g_location_lat, g_location_long),
          ),
        ],
      ),
    );
  }

  Widget geolocate(double _lat, double _lng) {
    return FutureBuilder(
        future: _geolocate(_lat, _lng),
        builder: (context, locate) {
          if (locate.connectionState == ConnectionState.done) {
            return Column(
              children: <Widget>[
                Icon(Icons.location_on),
                Text(
                  locate.data,
                  style: Theme.of(context).textTheme.body2.apply(
                        color: Colors.black,
                      ),
                ),
              ],
            );
          } else {
            return Text(
              'ไม่สามารถระบุข้อมูลที่ตั้งได้',
              style: Theme.of(context).textTheme.body2.apply(
                    color: Colors.black,
                  ),
            );
          }
        });
  }

  Future _geolocate(double _lat, double _lng) async {
    List<Placemark> newPlace =
        await Geolocator().placemarkFromCoordinates(_lat, _lng);
    Placemark placeMark = newPlace[0];
    String name = placeMark.name;
    String subLocality = placeMark.subLocality;
    String locality = placeMark.locality;
    String administrativeArea = placeMark.administrativeArea;
    String postalCode = placeMark.postalCode;
    String country = placeMark.country;
    String address =
        "${name} ${subLocality} ${locality} ${administrativeArea} ${country} ${postalCode}";
    return address;
  }
}

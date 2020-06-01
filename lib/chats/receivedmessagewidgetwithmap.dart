import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'mycircleavatar.dart';

class ReceivedMessagesWidgetwithmap extends StatelessWidget {
  final String image;
  final String name;
  final double g_location_lat;
  final double g_location_long;
  final String time;
  const ReceivedMessagesWidgetwithmap(
      {@required this.image,
      @required this.name,
      @required this.g_location_lat,
      @required this.g_location_long,
      @required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: <Widget>[
          MyCircleAvatar(
            imgUrl: image,
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
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Color(0xfff9f9f9),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: geolocate(g_location_lat, g_location_long),
              ),
            ],
          ),
          SizedBox(width: 15),
          Text(
            "$time",
            style: Theme.of(context).textTheme.body2.apply(color: Colors.grey),
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

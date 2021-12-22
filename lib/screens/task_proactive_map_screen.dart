import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import './task_proactive_screen.dart';

class TaskProactiveMapScreen extends StatelessWidget {
  static const routeName = 'task_proactive_map';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('請選擇餐廳!'),
      ),
      body: Container(child: GoogleMapScreen()),
    );
  }
}

class GoogleMapScreen extends StatefulWidget {
  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  GoogleMapController mapController;
  bool mapToggle = false;
  var currentLocation;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Geolocator.getCurrentPosition().then((currloc) {
      setState(() {
        currentLocation = currloc;
        mapToggle = true;
      });
    });
    getrestaurants();
  }

  getrestaurants() async {
    await Firebase.initializeApp();
    final firebaseFirestore = FirebaseFirestore.instance;
    firebaseFirestore.collection('restaurants').get().then((value) {
      if (value.docs.isNotEmpty) {
        for (int i = 0; i < value.docs.length; i++) {
          if (value.docs[i]['checked'] == '2') {
            initMarker(value.docs[i], value.docs[i].id);
          }
        }
      } else {
        print('It is empty!');
      }
    });
  }

  void initMarker(location, locationId) {
    try {
      var markerIdVal = locationId;
      final MarkerId markerId = MarkerId(markerIdVal);

      // Create a new marker
      final Marker marker = Marker(
        markerId: markerId,
        position: LatLng(
          double.parse(location['lat']),
          double.parse(location['lng']),
        ),
        infoWindow: InfoWindow(
          title: location['name'],
          snippet: location['rating'] == '' ? '沒有評分' : location['rating'],
          onTap: () {
            Navigator.of(context).pushNamed(
              TaskProactiveScreen.routeName,
              arguments: {
                'restaurantsName': location['name'],
                'restaurantsId': locationId,
                'task_type': 'proactive',
              },
            );
          },
        ),
      );
      setState(() {
        markers[markerId] = marker;
      });
    } catch (err) {
      print('error occurs on $locationId');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height - 80,
              width: double.infinity,
              child: mapToggle
                  ? GoogleMap(
                      onMapCreated: _onMapCreated,
                      markers: Set<Marker>.of(markers.values),
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          currentLocation.latitude,
                          currentLocation.longitude,
                        ),
                        zoom: 17.5,
                      ),
                    )
                  : Center(
                      child: Text('Loading...'),
                    ),
            ),
          ],
        )
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import './task_add_screen.dart';

class TaskAddMapScreen extends StatelessWidget {
  static const routeName = '/task_add_map';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('請點選地點以添加新的餐廳!'),
      ),
      body: GoogleMapScreen(),
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
  bool markerCreate = false;
  var currentLocation;
  LatLng currentPoint;
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
          if (int.parse(value.docs[i]['checked']) >= 2) {
            initMarker(value.docs[i], value.docs[i].id);
          }
        }
      } else {
        print('It is empty!');
      }
    });
  }

  void initMarker(location, locationId) {
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
        snippet: location['rating'],
      ),
    );
    setState(() {
      markers[markerId] = marker;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  _handleTap(LatLng point) {
    setState(() {
      markers[MarkerId('current')] = Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        draggable: true,
        infoWindow: InfoWindow(
          title: '是否新增餐廳於此?',
        ),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
      );
      currentPoint = point;
      markerCreate = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height - 150,
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
                      onTap: _handleTap,
                    )
                  : Center(
                      child: Text('Loading...'),
                    ),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: OutlinedButton(
            style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.disabled)) {
                  return Colors.grey[100];
                }
                return Colors.blue;
              }),
            ),
            child: Text(
              '新增餐廳於此',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              if (!markerCreate) {
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: Text('錯誤!'),
                          content: Text(
                            '請選擇地點',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ));
              } else {
                Navigator.of(context)
                    .pushNamed(TaskAddScreen.routeName, arguments: {
                  'restaurantsLocation': currentPoint,
                });
              }
            },
          ),
        ),
      ],
    );
  }
}

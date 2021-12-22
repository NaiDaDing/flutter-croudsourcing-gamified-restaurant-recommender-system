import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import '../providers/auth.dart';
import '../widgets/gamification_dialog.dart';

class TaskAssignedMapScreen extends StatelessWidget {
  static const routeName = 'task_assigned_map';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('請選擇您想了解情況的餐廳!'),
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

  Future<void> addTask(var location) {
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks.add({
      'complete': 'false',
      'create_time': DateTime.now().toIso8601String(),
      'record': [],
      'requester': Provider.of<Auth>(context, listen: false).email,
      'restaurants': json.encode(location.data()),
      'restaurantsId': location.id,
      'task_type': 'assigned',
    });
  }

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
        onTap: () {
          List<dynamic> logs = [
            {
              'event': 'request_task',
              'timestamp': DateTime.now().toIso8601String(),
              'restaurantsId': locationId,
            }
          ];
          Provider.of<Auth>(context, listen: false).updateUserLog(logs);
          addTask(location);
          Provider.of<Auth>(context, listen: false)
              .updateUserCount('count_requester')
              .whenComplete(() {
            var email = Provider.of<Auth>(context, listen: false).email;
            CollectionReference users =
                FirebaseFirestore.instance.collection('users');
            return users.where('email', isEqualTo: email).get().then((value) {
              value.docs.forEach((element) {
                users.doc(element.id).get().then((value) {
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (ctx) => WillPopScope(
                            onWillPop: () async => false,
                            child: GamificationDialog(
                              countType: 'count_requester',
                              selfCount: int.parse(value['count_requester']),
                            ),
                          ));
                });
              });
            });
          });
        },
      ),
    );
    setState(() {
      markers[markerId] = marker;
    });
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../providers/auth.dart';
import '../widgets/gamification_dialog.dart';

class CheckAddMapScreen extends StatelessWidget {
  static const routeName = '/check_add_map';

  @override
  Widget build(BuildContext context) {
    dynamic obj = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: Text('請確認餐廳地點'),
      ),
      body: GoogleMapScreen(
        obj: obj,
      ),
    );
  }
}

class GoogleMapScreen extends StatefulWidget {
  dynamic obj;

  GoogleMapScreen({this.obj});

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  GoogleMapController mapController;
  bool mapToggle = false;
  bool willComplete = false;
  var currentLocation;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void initState() {
    // TODO: implement initState
    super.initState();
    print('init');
    Geolocator.getCurrentPosition().then((currloc) {
      setState(() {
        currentLocation = currloc;
        mapToggle = true;
      });
    });
    initMarker(
        this.widget.obj['restaurants'], this.widget.obj['restaurants']['id']);
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
        title: '餐廳名稱: ' + location['name'],
      ),
    );
    setState(() {
      markers[markerId] = marker;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> locationCorrectTask() async {
    await Firebase.initializeApp();
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks
        .where('requester', isEqualTo: this.widget.obj['task']['email'])
        .where('create_time', isEqualTo: this.widget.obj['task']['create_time'])
        .get()
        .then((value) {
      value.docs.forEach((element) {
        List<dynamic> logsArray = element['record'];
        if (logsArray.length > 0) {
          int count = 0;
          for (var i = 0; i < logsArray.length; i++) {
            logsArray[i]['judgment'] == 'correct' ? count++ : null;
          }
          if (count == 1) {
            willComplete = true;
          }
        }
        List<dynamic> logs = [
          {
            'judgment': 'correct',
            'timestamp': DateTime.now().toIso8601String(),
            'user': Provider.of<Auth>(context, listen: false).email,
          }
        ];
        tasks.doc(element.id).update({
          'record': FieldValue.arrayUnion(logs),
          'complete': willComplete ? 'true' : 'false',
        });
        if (willComplete) {
          CollectionReference forLoading =
              FirebaseFirestore.instance.collection('forLoading');
          forLoading.doc('7esgqVsJmvdkZUGPIkxq').update({
            'deleted_restaurants':
                FieldValue.arrayUnion([element['restaurantsId']])
          });
        }
      });
    });
  }

  Future<void> locationCorrectrestaurants() async {
    await Firebase.initializeApp();
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    return restaurants
        .where('id', isEqualTo: this.widget.obj['restaurants']['id'])
        .get()
        .then((value) {
      value.docs.forEach((element) {
        restaurants
            .doc(element.id)
            .update({'checked': '2'})
            .then((value) => print('success'))
            .catchError((error) {
              print(error);
              print('錯誤!');
            });
      });
    });
  }

  Future<void> locationIncorrect() async {
    await Firebase.initializeApp();
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks
        .where('requester', isEqualTo: this.widget.obj['task']['email'])
        .where('create_time', isEqualTo: this.widget.obj['task']['create_time'])
        .get()
        .then((value) {
      value.docs.forEach((element) {
        List<dynamic> logsArray = element['record'];
        if (logsArray.length > 0) {
          int count = 0;
          for (var i = 0; i < logsArray.length; i++) {
            logsArray[i]['judgment'] == 'incorrect' ? count++ : null;
          }
          if (count == 1) {
            willComplete = true;
          }
        }
        List<dynamic> logs = [
          {
            'judgment': 'incorrect',
            'timestamp': DateTime.now().toIso8601String(),
            'user': Provider.of<Auth>(context, listen: false).email,
          }
        ];
        tasks.doc(element.id).update({
          'record': FieldValue.arrayUnion(logs),
          'complete': willComplete ? 'true' : 'false',
        });
      });
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
                          double.parse(this.widget.obj['restaurants']['lat']),
                          double.parse(this.widget.obj['restaurants']['lng']),
                        ),
                        zoom: 17.5,
                      ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton(
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
                '錯誤!',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                locationIncorrect();
                Provider.of<Auth>(context, listen: false)
                    .updateUserCount('count_verify_add')
                    .whenComplete(() {
                  var email = Provider.of<Auth>(context, listen: false).email;
                  CollectionReference users =
                      FirebaseFirestore.instance.collection('users');
                  return users
                      .where('email', isEqualTo: email)
                      .get()
                      .then((value) {
                    value.docs.forEach((element) {
                      users.doc(element.id).get().then((value) {
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (ctx) => WillPopScope(
                                  onWillPop: () async => false,
                                  child: GamificationDialog(
                                    countType: 'count_verify_add',
                                    selfCount:
                                        int.parse(value['count_verify_add']),
                                  ),
                                ));
                      });
                    });
                  });
                });
                List<dynamic> logs = [
                  {
                    'event': 'verify_added_restaurants',
                    'timestamp': DateTime.now().toIso8601String(),
                    'judgment': 'incorrect',
                  }
                ];
                Provider.of<Auth>(context, listen: false).updateUserLog(logs);
              },
            ),
            OutlinedButton(
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
                '正確!',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                locationCorrectTask().whenComplete(() {
                  if (willComplete) {
                    locationCorrectrestaurants();
                  }
                });
                Provider.of<Auth>(context, listen: false)
                    .updateUserCount('count_verify_add')
                    .whenComplete(() {
                  var email = Provider.of<Auth>(context, listen: false).email;
                  CollectionReference users =
                      FirebaseFirestore.instance.collection('users');
                  return users
                      .where('email', isEqualTo: email)
                      .get()
                      .then((value) {
                    value.docs.forEach((element) {
                      users.doc(element.id).get().then((value) {
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (ctx) => WillPopScope(
                                  onWillPop: () async => false,
                                  child: GamificationDialog(
                                    countType: 'count_verify_add',
                                    selfCount:
                                        int.parse(value['count_verify_add']),
                                  ),
                                ));
                      });
                    });
                  });
                });
                List<dynamic> logs = [
                  {
                    'event': 'verify_added_restaurants',
                    'timestamp': DateTime.now().toIso8601String(),
                    'judgment': 'correct',
                  }
                ];
                Provider.of<Auth>(context, listen: false).updateUserLog(logs);
              },
            ),
          ],
        ),
      ],
    );
  }
}

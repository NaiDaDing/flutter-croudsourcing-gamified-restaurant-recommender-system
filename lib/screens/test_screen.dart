import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestScreen extends StatelessWidget {
  //final List restaurants_data = res;
  List<Map<String, dynamic>> users = [
    {"id": 123, "name": "a", "age": 25},
    {"id": 345, "name": "b", "age": 44},
    {"id": 35, "name": "c", "age": 40},
    {"id": 3, "name": "d", "age": 40},
    {"id": 5, "name": "e", "age": 50},
    {"id": 15, "name": "f", "age": 85},
    {"id": 33, "name": "g", "age": 40},
  ];

  String test =
      "{'俄羅斯式': 0, '台式': 1, '法式': 0, '義式': 1, '餐酒館/酒吧': 0, '咖啡': 0, '中東式': 0, '東南亞': 1, '泰式': 1, '印式': 0, '飲料': 1, '墨式': 0, '夏威夷式': 1, '中式': 1, '德式': 0, '歐式': 1, '韓式': 1, '日式': 1, '美式': 1, '越式': 1, '港式': 1}";

  Map testMap = {
    '俄羅斯式': 0,
    '台式': 1,
    '法式': 0,
    '義式': 1,
    '餐酒館/酒吧': 0,
    '咖啡': 0,
    '中東式': 0,
    '東南亞': 1,
    '泰式': 1,
    '印式': 0,
    '飲料': 1,
    '墨式': 0,
    '夏威夷式': 1,
    '中式': 1,
    '德式': 0,
    '歐式': 1,
    '韓式': 1,
    '日式': 1,
    '美式': 1,
    '越式': 1,
    '港式': 1
  };

  Map<String, dynamic> updatedData = {
    "parking": 0,
    "air_conditioning": 0,
    "crowdedness_dinein": 0,
    "count_choosen": 0,
    "count_explored": 0,
    "open_log": [],
    "tv": 0,
    "tv_log": [],
    "open": 0,
    "crowdedness_takeout": 0,
    "crowdedness_takeout_log": [],
    "air_conditioning_log": [],
    "promotion": 0,
    "music": 0,
    "covid_change_log": [],
    "pics": [],
    "promotion_log": [],
    "safety_log": [],
    "safety": 0,
    "parking_log": [],
    "wifi": 0,
    "covid_change": 0,
    "wifi_log": [],
    "crowdedness_dinein_log": [],
    "music_log": []
  };

  Future<void> updateFixedData() async {
    await Firebase.initializeApp();
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    return restaurants.get().then((value) {
      value.docs.forEach((element) {
        restaurants.doc(element.id).update({
          "parking": 0,
          "air_conditioning": 0,
          "crowdedness_dinein": 0,
          "count_choosen": 0,
          "count_explored": 0,
          "open_log": [],
          "tv": 0,
          "tv_log": [],
          "open": 0,
          "crowdedness_takeout": 0,
          "crowdedness_takeout_log": [],
          "air_conditioning_log": [],
          "promotion": 0,
          "music": 0,
          "covid_change_log": [],
          "pics": [],
          "promotion_log": [],
          "safety_log": [],
          "safety": 0,
          "parking_log": [],
          "wifi": 0,
          "covid_change": 0,
          "wifi_log": [],
          "crowdedness_dinein_log": [],
          "music_log": []
        });
      });
    });
  }

  Future<void> printRes() async {
    await Firebase.initializeApp();
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    return restaurants.get().then((value) {
      print('總共有' + value.docs.length.toString() + '餐廳');
    });
  }

  Future<void> adjestment() async {
    List contexts = [
      'air_conditioning',
      'crowdedness_dinein',
      'crowdedness_takeout',
      'music',
      'open',
      'parking',
      'promotion',
      'safety',
      'tv',
      'wifi',
    ];
    await Firebase.initializeApp();
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    for (String ctx in contexts) {
      print('test for $ctx');
      String contextsLog = ctx + '_log';
      var contextScore;
      restaurants.where(ctx, isNotEqualTo: 0).get().then((value) {
        value.docs.forEach((element) {
          List<dynamic> array = element[contextsLog];
          if (array.length == 0) {
            restaurants.doc(element.id).update({ctx: 0});
          } else {
            if (ctx == 'crowdedness_dinein' || ctx == 'crowdedness_takeout') {
              Map threeNumbers = {
                1: 0,
                0.5: 0,
                0.3: 0,
              };
              bool isEmpty = true;
              for (var m in array) {
                if (DateTime.now()
                        .difference(DateTime.parse(m['timestamp']))
                        .inHours >=
                    2) {
                  restaurants.doc(element.id).update({
                    contextsLog: FieldValue.arrayRemove([m]),
                  });
                } else {
                  isEmpty = false;
                  threeNumbers[m['score']] = threeNumbers[m['score']] + 1;
                }
              }
              if (isEmpty) {
                contextScore = 0;
              } else {
                var finalValue = 0;
                threeNumbers.forEach((key, value) {
                  if (value > finalValue) {
                    finalValue = value;
                    contextScore = key;
                  }
                });
              }
              restaurants.doc(element.id).update({
                ctx: contextScore,
              });
            } else if (ctx == 'safety') {
              Map threeNumbers = {
                1: 0,
                5: 0,
                10: 0,
              };
              bool isEmpty = true;
              for (var m in array) {
                if (DateTime.now()
                        .difference(DateTime.parse(m['timestamp']))
                        .inDays >=
                    1) {
                  restaurants.doc(element.id).update({
                    contextsLog: FieldValue.arrayRemove([m]),
                  });
                } else {
                  isEmpty = false;
                  threeNumbers[m['score']] = threeNumbers[m['score']] + 1;
                }
              }
              if (isEmpty) {
                contextScore = 0;
              } else {
                var finalValue = 0;
                threeNumbers.forEach((key, value) {
                  if (value > finalValue) {
                    finalValue = value;
                    contextScore = key;
                  }
                });
              }
              restaurants.doc(element.id).update({
                ctx: contextScore,
              });
            } else {
              Map twoNumbers = {
                1: 0,
                -1: 0,
              };
              bool isEmpty = true;
              for (var m in array) {
                if (DateTime.now()
                        .difference(DateTime.parse(m['timestamp']))
                        .inDays >=
                    1) {
                  restaurants.doc(element.id).update({
                    contextsLog: FieldValue.arrayRemove([m]),
                  });
                } else {
                  isEmpty = false;
                  twoNumbers[m['score']] = twoNumbers[m['score']] + 1;
                }
              }
              if (isEmpty) {
                contextScore = 0;
              } else {
                var finalValue = 0;
                twoNumbers.forEach((key, value) {
                  if (value > finalValue) {
                    finalValue = value;
                    contextScore = key;
                  }
                });
              }
              restaurants.doc(element.id).update({
                ctx: contextScore,
              });
            }
          }
        });
      });
    }
  }

  Future<void> addrestaurants(Map resData) {
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    return restaurants.add({
      "id": resData['id'],
      "name": resData['name'],
      "address": resData['address'],
      "lng": resData['lng.'],
      "lat": resData['lat.'],
      "rating": resData['rating'],
      "price_segment": resData['price_segment'],
      "info": resData['info'],
      "cuisine_type": resData['cuisine_type'],
      "inout": resData['inout'],
      "checked": resData['checked'],
    }).catchError((error) => print("Failed to add user: $error"));
  }

  Future<void> deleteField(String collection) async {
    CollectionReference collections =
        FirebaseFirestore.instance.collection(collection);
    return collections.get().then((value) {
      value.docs.forEach((element) {
        print('Start!');
        collections.doc(element.id).update({
          'cuisine_type': element['cuisine_type'].replaceAll("'日本': 0, ", "")
        }).whenComplete(() => print('Done'));
      });
    });
  }

  /*Future<void> addSubCollection() {
    FirebaseFirestore.instance.runTransaction((tx) {
      tx.set(FirebaseFirestore.instance.collection('restaurants').doc()(), {'test', 'test'});
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Center(
        child: OutlinedButton(
          child: Text('get data from firebase'),
          onPressed: () async {
            await Firebase.initializeApp();
            Map<String, dynamic> resultData;
            CollectionReference users =
                FirebaseFirestore.instance.collection('users');
            users
                .where("email", isEqualTo: 'qq122618071@gmail.com')
                .get()
                .then((querySnapshot) {
              querySnapshot.docs.forEach((result) {
                resultData = Map<String, dynamic>.from(result.data());
                print(resultData['email']);
              });
            }).catchError((error) => print("Failed appends!: $error"));
          },
        ),
      ),
      Center(
          child: OutlinedButton(
        child: Text('clenr the local data'),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear().then((_) => print('clear!'));
        },
      )),
      Center(
          child: OutlinedButton(
              child: Text('get data form tasks'),
              onPressed: () async {
                await Firebase.initializeApp();
                CollectionReference tasks =
                    FirebaseFirestore.instance.collection('tasks');
                tasks
                    .where('complete', isEqualTo: 'false')
                    .where('task_type', isEqualTo: 'addMap')
                    .get()
                    .then((querySnapshot) {
                  querySnapshot.docs.forEach((element) {
                    var map = Map<String, dynamic>.from(element.data());
                    print(json
                        .decode(map['restaurants'])['cusine_type']
                        .runtimeType);
                  });
                });
              })),
      Center(
        child: OutlinedButton(
          child: Text('delete check=1 restaurants'),
          onPressed: () async {
            await Firebase.initializeApp();
            CollectionReference restaurants =
                FirebaseFirestore.instance.collection('restaurants');
            return restaurants
                .where('checked', isEqualTo: '1')
                .get()
                .then((value) {
              value.docs.forEach((element) {
                restaurants
                    .doc(element.id)
                    .delete()
                    .then((value) => print('success'));
              });
            });
          },
        ),
      ),
      Center(
        child: OutlinedButton(
          child: Text('print checked=1 restaurants'),
          onPressed: () async {
            await Firebase.initializeApp();
            CollectionReference restaurants =
                FirebaseFirestore.instance.collection('restaurants');
            return restaurants
                .where('checked', isEqualTo: '1')
                .get()
                .then((querySnapshot) {
              if (querySnapshot.docs.isEmpty) {
                print('Empty!');
                return;
              }
              querySnapshot.docs.forEach((element) {
                print(element.id + '' + '${element.data()}');
              });
            });
          },
        ),
      ),
      Center(
        child: OutlinedButton(
          child: Text('Get specific restaurants id'),
          onPressed: () async {
            await Firebase.initializeApp();
            CollectionReference restaurants =
                FirebaseFirestore.instance.collection('restaurants');
            return restaurants
                .where('crowdedness_dinein', isNull: true)
                .get()
                .then((value) {
              value.docs.forEach((element) {
                print(element.id + '  ' + element['name']);
              });
            });
          },
        ),
      ),
      Center(
        child: OutlinedButton(
          child: Text('Create new field or clear fields values.'),
          onPressed: () async {
            await Firebase.initializeApp();
            CollectionReference restaurants =
                FirebaseFirestore.instance.collection('restaurants');
            restaurants.get().then((value) {
              value.docs.forEach((element) {
                /*restaurants.doc(element.id).set(
                  {'count_explored': 0, 'count_choosen': 0},
                  SetOptions(merge: true),*/
                restaurants.doc(element.id).set(
                  {'covid_change': 0, 'covid_change_log': [], 'pics': []},
                  SetOptions(merge: true),
                );
              });
            });
          },
        ),
      ),
      /*Center(
        child: OutlinedButton(
          child: Text('show image'),
          onPressed: () {
            var url =
                'https://firebasestorage.googleapis.com/v0/b/flutter-paper-project.appspot.com/o/test%2Fdraw_teitu.jpg?alt=media&token=d8cc321b-8330-470f-8618-882263cb08fe';
            Image.network(url);
          },
        ),
      ),
      Center(
        child: OutlinedButton(
          child: Text('reset all data'),
          onPressed: () async {
            // 需要記下check 1 restaurants to check two
            await Firebase.initializeApp();
            CollectionReference restaurants =
                FirebaseFirestore.instance.collection('restaurants');
            CollectionReference users =
                FirebaseFirestore.instance.collection('users');
            CollectionReference forLoading =
                FirebaseFirestore.instance.collection('forLoading');
            List<dynamic> checkOneRes;
            forLoading.doc('7esgqVsJmvdkZUGPIkxq').get().then((value) {
              checkOneRes = value.get('deleted_restaurants');
              forLoading
                  .doc('7esgqVsJmvdkZUGPIkxq')
                  .set({'deleted_restaurants': []});
            });
            restaurants.where('checked', isEqualTo: '1').get().then((value) {
              value.docs.forEach((element) {
                restaurants.doc(element.id).delete();
              });
            });
            if (checkOneRes != null) {
              for (var resId in checkOneRes) {
                restaurants.where('id', isEqualTo: resId).get().then((value) {
                  value.docs.forEach((element) {
                    restaurants.doc(element.id).delete();
                  });
                });
              }
            }

            restaurants.get().then((value) {
              value.docs.forEach((element) {
                restaurants.doc(element.id).update({
                  'open': 0,
                  'crowdedness_dinein': 0,
                  'crowdedness_takeout': 0,
                  'safety': 0,
                  'covid_change': 0,
                  'parking': 0,
                  'wifi': 0,
                  'air_conditioning': 0,
                  'tv': 0,
                  'music': 0,
                  'promotion': 0,
                });
                restaurants.doc(element.id).set({
                  'open_log': [],
                  'crowdedness_dinein_log': [],
                  'crowdedness_takeout_log': [],
                  'safety_log': [],
                  'covid_change_log': [],
                  'parking_log': [],
                  'wifi_log': [],
                  'air_conditioning_log': [],
                  'tv_log': [],
                  'music_log': [],
                  'promotion_log': [],
                  'pics': [],
                });
              });
            });
            users.get().then((value) {
              value.docs.forEach((element) {
                users.doc(element.id).update({
                  'count_add': '0',
                  'count_assigned': '0',
                  'count_goto': '0',
                  'count_picture': '0',
                  'count_proactive': '0',
                  'count_rating': '0',
                  'count_recommend': '0',
                  'count_requester': '0',
                  'count_verify_add': '0',
                  'count_verify_assigned': '0',
                  'count_verify_proactive': '0',
                });
                users.doc(element.id).set({'log': []});
              });
            });
          },
        ),
      ),*/
      /*Center(
        child: OutlinedButton(
          child: Text('change cuisine'),
          onPressed: () async {
            await Firebase.initializeApp();
            CollectionReference restaurants =
                FirebaseFirestore.instance.collection('restaurants');
            return restaurants.get().then((value) {
              value.docs.forEach((element) {
                restaurants.doc(element.id).get().then((value) {
                  var previous = value['cusine_type'];
                  return restaurants.doc(element.id).update({
                    'cuisine_type': previous,
                    'cusine_type': FieldValue.delete(),
                  });
                });
              });
            });
          },
        ),
      ),*/
      /*Center(
        child: OutlinedButton(
          child: Text('Update fixed data!'),
          onPressed: () => updateFixedData(),
        ),
      ),*/
      /*Center(
        child: OutlinedButton(
          child: Text('Create sub coolection of specific restaurants'),
          onPressed: () async {
            await Firebase.initializeApp();
            CollectionReference restaurants =
                FirebaseFirestore.instance.collection('restaurants');
            for (var k in subcollection.keys) {
              restaurants
                  .doc('8Xneh9QQ4xNQCUFevHgb')
                  .collection('contexts')
                  .doc(k)
                  .set(subcollection[k]);
            }
            print('done!');
          },
        ),
      ),*/
      // Update restaurants
      /*Center(
        child: OutlinedButton(
          child: Text('Update all restaurants!'),
          onPressed: () async {
            await Firebase.initializeApp();
            for (var i = 0; i <= restaurants_data.length; i++) {
              addrestaurants(restaurants_data[i]);
              print(restaurants_data[i]['name']);
            }
          },
        ),
      ),*/
    ]);
  }
}

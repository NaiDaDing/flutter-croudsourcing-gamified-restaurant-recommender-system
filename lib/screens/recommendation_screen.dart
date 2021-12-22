import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/score_mapper.dart' as Score_mapper;
import '../widgets/gamification_dialog.dart';
import '../models/recommender_algo.dart';
import '../providers/auth.dart';
import './photo_screen.dart';

class RecommendationScreen extends StatefulWidget {
  static const routeName = '/recommendation';
  final obj;

  RecommendationScreen({this.obj});

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<Map<String, dynamic>> scoresList = [];
  Map<String, dynamic> resMap = <String, dynamic>{};
  Map<String, dynamic> userCuisine;
  List userList;
  bool isLoaded = false;
  var currentLocation;

  Map<String, dynamic> priceType = {
    'm': '150以下',
    'mm': '150-600',
    'mmm': '600-1200',
    'mmmm': '1200以上',
  };

  Map<String, String> revisedPriceType = {
    '150以下': 'm',
    '150-600': 'mm',
    '600-1200': 'mmm',
    '1200以上': 'mmmm',
  };

  Map contextNameTranslater = {
    'open': '營業狀況',
    'crowdedness_dinein': '餐廳內用人潮',
    'crowdedness_takeout': '餐廳排隊人潮',
    'safety': '實施防疫措施',
    'covid_change': '疫情特殊餐點',
    'parking': '停車空位',
    'wifi': 'wifi',
    'air_conditioning': '空調狀況',
    'tv': '電視狀況',
    'music': '音樂狀況',
    'promotion': '特殊活動',
  };

  Map numToScoreBinary = {
    1: 1,
    -1: 0.3,
    0: 0.3,
  };

  Map numToScoreSafety = {
    1: 1,
    5: 1,
    10: 1,
    0: 0.1,
  };

  Map numToScoreCrowd = {
    1: 1,
    0.5: 0.5,
    0.3: 0.3,
    0: 0.5,
  };

  Map numToScoreOpen = {
    1: 1,
    -1: 0,
    0: 0.9,
  };

  @override
  void initState() {
    super.initState();
    Geolocator.getCurrentPosition().then((currloc) {
      currentLocation = currloc;
    });
    getUserList().whenComplete(() {
      adjustContexts().whenComplete(() {
        calculateScore(userList).whenComplete(() {
          scoresList.sort((a, b) => a['score'].compareTo(b['score']));
          scoresList = scoresList.reversed.toList();
          isLoaded = true;
          setState(() {});
        });
      });
    });
  }

  Future<void> adjustContexts() async {
    List contexts = [
      'air_conditioning',
      'crowdedness_dinein',
      'crowdedness_takeout',
      'music',
      'open',
      'parking',
      'promotion',
      'safety',
      'covid_change',
      'tv',
      'wifi',
    ];
    await Firebase.initializeApp();
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    for (String ctx in contexts) {
      print('Adjustment of $ctx');
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

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> calculateScore(List userList) async {
    try {
      await Firebase.initializeApp();
      double min = 0;
      CollectionReference restaurants =
          FirebaseFirestore.instance.collection('restaurants');
      if (this.widget.obj['attributes'][1] != '無限制') {
        String price = revisedPriceType[this.widget.obj['attributes'][1]];
        return restaurants
            .where('checked', isEqualTo: '2')
            .where('open', isNotEqualTo: -1)
            .where(
              'price_segment',
              isEqualTo: price,
            )
            .get()
            .then((value) {
          value.docs.forEach((element) async {
            List restaurantsList =
                json.decode(element['cuisine_type']).values.toList();
            Map contextMap = {
              'open': element['open'],
              'crowdedness_dinein': element['crowdedness_dinein'],
              'crowdedness_takeout': element['crowdedness_takeout'],
              'safety': element['safety'],
              'parking': element['parking'],
              'wifi': element['wifi'],
              'air_conditioning': element['air_conditioning'],
              'tv': element['tv'],
              'music': element['music'],
              'promotion': element['promotion'],
            };
            bool showContexts = false;
            for (var value in contextMap.values) {
              if (value != 0) {
                showContexts = true;
              }
            }
            resMap['show_contexts'] = showContexts;
            resMap['id'] = element.id;
            resMap['name'] = element['name'];
            resMap['address'] = element['address'];
            resMap['inout'] = element['inout'];
            resMap['cuisine_type'] = element['cuisine_type'];
            resMap['restaurantsList'] = restaurantsList;
            resMap['lat'] = element['lat'];
            resMap['lng'] = element['lng'];
            resMap['info'] = element['info'];
            resMap['price_segment'] = element['price_segment'];
            resMap['rating'] = element['rating'];
            resMap['pics'] = element['pics'];
            resMap['contexts'] = contextMap;
            resMap['distance'] = calculateDistance(
              currentLocation.latitude,
              currentLocation.longitude,
              double.parse(element['lat']),
              double.parse(element['lng']),
            );
            double score = RecommenderAlgo.cosineSimularity(
              userArray: userList,
              restautantArray: restaurantsList,
            );
            resMap['score'] = score;
            if (this.widget.obj['attributes'][0] == '無限制') {
              min = topList(
                  scoresList, resMap, min, score, this.widget.obj['contexts']);
            } else if (this.widget.obj['attributes'][0] == '500m內') {
              if (resMap['distance'] <= 0.5) {
                min = topList(scoresList, resMap, min, score,
                    this.widget.obj['contexts']);
              }
            } else {
              if (resMap['distance'] <= 1.0) {
                min = topList(scoresList, resMap, min, score,
                    this.widget.obj['contexts']);
              }
            }
            resMap = <String, dynamic>{};
          });
        });
      } else {
        return restaurants.where('checked', isEqualTo: '2').get().then((value) {
          value.docs.forEach((element) async {
            List restaurantsList =
                json.decode(element['cuisine_type']).values.toList();
            Map contextMap = {
              'open': element['open'],
              'crowdedness_dinein': element['crowdedness_dinein'],
              'crowdedness_takeout': element['crowdedness_takeout'],
              'safety': element['safety'],
              'covid_change': element['covid_change'],
              'parking': element['parking'],
              'wifi': element['wifi'],
              'air_conditioning': element['air_conditioning'],
              'tv': element['tv'],
              'music': element['music'],
              'promotion': element['promotion'],
            };
            bool showContexts = false;
            for (var value in contextMap.values) {
              if (value != 0) {
                showContexts = true;
              }
            }
            resMap['show_contexts'] = showContexts;
            resMap['id'] = element.id;
            resMap['name'] = element['name'];
            resMap['address'] = element['address'];
            resMap['inout'] = element['inout'];
            resMap['cuisine_type'] = element['cuisine_type'];
            resMap['restaurantsList'] = restaurantsList;
            resMap['lat'] = element['lat'];
            resMap['lng'] = element['lng'];
            resMap['info'] = element['info'];
            resMap['price_segment'] = element['price_segment'];
            resMap['rating'] = element['rating'];
            resMap['pics'] = element['pics'];
            resMap['contexts'] = contextMap;
            resMap['distance'] = calculateDistance(
              currentLocation.latitude,
              currentLocation.longitude,
              double.parse(element['lat']),
              double.parse(element['lng']),
            );
            double score = RecommenderAlgo.cosineSimularity(
              userArray: userList,
              restautantArray: restaurantsList,
            );
            resMap['score'] = score;
            if (this.widget.obj['attributes'][0] == '無限制') {
              min = topList(
                  scoresList, resMap, min, score, this.widget.obj['contexts']);
            } else if (this.widget.obj['attributes'][0] == '500m內') {
              if (resMap['distance'] <= 0.5) {
                min = topList(scoresList, resMap, min, score,
                    this.widget.obj['contexts']);
              }
            } else {
              if (resMap['distance'] <= 1.0) {
                min = topList(scoresList, resMap, min, score,
                    this.widget.obj['contexts']);
              }
            }
            resMap = <String, dynamic>{};
          });
        });
      }
    } catch (e, stacktrace) {
      print('Exception: ' + e.toString());
      print('Stacktrace: ' + stacktrace.toString());
    }
  }

  double topList(
    List scoreList,
    Map resMap,
    double min,
    double score,
    List contexts,
  ) {
    try {
      double innerScore = score;
      if (contexts.length != 0) {
        for (var ctx in contexts) {
          if (ctx == 'crowdedness_dinein' || ctx == 'crowdedness_takeout') {
            innerScore = score * numToScoreCrowd[resMap['contexts'][ctx]];
          } else if (ctx == 'safety') {
            innerScore = score * numToScoreSafety[resMap['contexts'][ctx]];
          } else if (ctx == 'open') {
            innerScore = score * numToScoreOpen[resMap['contexts'][ctx]];
          } else {
            innerScore = score * numToScoreBinary[resMap['contexts'][ctx]];
          }
        }
      }
      if (scoreList.length == 0) {
        scoreList.add(resMap);
        return innerScore;
      } else if (scoreList.length > 0 && scoreList.length < 15) {
        scoreList.add(resMap);
        if (innerScore <= min) {
          return innerScore;
        }
        return min;
      } else {
        if (innerScore >= min) {
          scoreList.sort((a, b) => a['score'].compareTo(b['score']));
          scoreList.remove(scoreList.first);
          scoreList.add(resMap);
          scoreList.shuffle();
          scoreList.sort((a, b) => a['score'].compareTo(b['score']));
          return scoreList.first['score'];
        }
        return min;
      }
    } catch (e, stacktrace) {
      print('錯在function內!');
      print('Exception: ' + e.toString());
      print('Stacktrace: ' + stacktrace.toString());
    }
  }

  Future<void> getUserList() async {
    await Firebase.initializeApp();
    String email = Provider.of<Auth>(context, listen: false).email;
    print(email);
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users.where('email', isEqualTo: email).get().then((value) {
      value.docs.forEach((element) {
        userCuisine = json.decode(element['cuisine_type']);
        userList = json.decode(element['cuisine_type']).values.toList();
        print(userList);
        return userList;
      });
    });
  }

  Future<void> updateUserCuisine() async {
    int count = 0;
    for (var k in userCuisine.keys) {
      userCuisine[k] = userList[count];
      count++;
    }
    await Firebase.initializeApp();
    String email = Provider.of<Auth>(context, listen: false).email;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    users.where('email', isEqualTo: email).get().then((value) {
      value.docs.forEach((element) {
        users
            .doc(element.id)
            .update({'cuisine_type': json.encode(userCuisine)});
      });
    });
  }

  Future<void> addTask(String restaurantsName) {
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks.add({
      'complete': 'false',
      'create_time': DateTime.now().toIso8601String(),
      'record': [],
      'owner': Provider.of<Auth>(context, listen: false).email,
      'restaurants_name': restaurantsName,
      'task_type': 'rating',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('餐廳推薦清單'),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, "/", (r) => false)),
      ),
      body: !isLoaded
          ? Center(
              child: CircularProgressIndicator(),
            )
          : (scoresList.length == 0
              ? Center(
                  child: Text(
                    '目前沒有適合您的餐廳,\n您可以調整篩選條件',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView(
                  children: [
                    ListView.builder(
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: scoresList.length,
                        itemBuilder: (context, index) {
                          return Container(
                            child: Card(
                              elevation: 8,
                              margin: EdgeInsets.all(5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF333366),
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 10),
                                      Row(
                                        children: [
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.store,
                                            size: 15,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              scoresList[index]['name'] + ' ',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17.5,
                                              ),
                                            ),
                                          ),
                                          scoresList[index]['rating'] == ''
                                              ? null
                                              : Flexible(
                                                  child: Text(
                                                    '(${scoresList[index]['rating']})',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                      scoresList[index]['pics'].length == 0
                                          ? Container(
                                              height: 5,
                                            )
                                          : Row(
                                              children: [
                                                SizedBox(width: 10),
                                                Icon(
                                                  Icons.photo,
                                                  size: 15,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 10),
                                                InkWell(
                                                  child: Text(
                                                    '#查看照片',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PhotoScreen(
                                                            photos: scoresList[
                                                                index]['pics'],
                                                          ),
                                                        ));
                                                  },
                                                ),
                                              ],
                                            ),
                                      Row(
                                        children: [
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.place,
                                            size: 15,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 10),
                                          scoresList[index]['address'] == ''
                                              ? Text(
                                                  '無地址資訊',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                )
                                              : Text(
                                                  scoresList[index]['address'],
                                                  overflow: TextOverflow.fade,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.map,
                                            size: 15,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            '距離: ' +
                                                scoresList[index]['distance']
                                                    .toStringAsFixed(2) +
                                                '公里',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.attach_money,
                                            size: 15,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            '平均消費: ' +
                                                priceType[scoresList[index]
                                                    ['price_segment']],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.restaurant,
                                            size: 15,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            json
                                                .decode(scoresList[index]
                                                    ['cuisine_type'])
                                                .keys
                                                .where((k) =>
                                                    json.decode(scoresList[
                                                            index]
                                                        ['cuisine_type'])[k] ==
                                                    1)
                                                .toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.yellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(width: 2),
                                          InkWell(
                                            child: Text(
                                              '#詳細資訊',
                                              style: TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                            onTap: () async {
                                              List<dynamic> logs = [
                                                {
                                                  'event':
                                                      'get_restaurants_info',
                                                  'timestamp': DateTime.now()
                                                      .toIso8601String(),
                                                  'restaurantsId':
                                                      scoresList[index]['id'],
                                                },
                                              ];
                                              Provider.of<Auth>(context,
                                                      listen: false)
                                                  .updateUserLog(logs);
                                              Provider.of<Auth>(context,
                                                      listen: false)
                                                  .updaterestaurantsCount(
                                                'count_explored',
                                                scoresList[index]['id'],
                                              );
                                              final url = scoresList[index]
                                                          ['info'] ==
                                                      ''
                                                  ? ''
                                                  : scoresList[index]['info'];
                                              if (url != '') {
                                                if (await canLaunch(url)) {
                                                  await launch(
                                                    url,
                                                    forceSafariVC: false,
                                                  );
                                                } else {
                                                  showDialog(
                                                    context: context,
                                                    builder: (ctx) =>
                                                        AlertDialog(
                                                      title: Text('錯誤!'),
                                                      content: Text('抱歉，連結失效!'),
                                                    ),
                                                  );
                                                }
                                              } else {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: Text('錯誤!'),
                                                    content: Text('抱歉，連結失效!'),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          SizedBox(width: 30),
                                          scoresList[index]['show_contexts']
                                              ? ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          primary: Colors.pink),
                                                  child: Text(
                                                    '即時資訊',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    List textList = [];
                                                    scoresList[index]
                                                            ['contexts']
                                                        .forEach((key, value) {
                                                      if (value != 0) {
                                                        textList.add({
                                                          'contextTitle': Text(
                                                            contextNameTranslater[
                                                                key],
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          'contexts': Text(
                                                            Score_mapper
                                                                .scoreMapper[
                                                                    key]
                                                                .keys
                                                                .firstWhere(
                                                                    (k) =>
                                                                        Score_mapper.scoreMapper[key]
                                                                            [
                                                                            k] ==
                                                                        value,
                                                                    orElse: () =>
                                                                        null),
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        });
                                                      }
                                                    });
                                                    Dialog contextsdDialog =
                                                        Dialog(
                                                      child: Container(
                                                        height: 300,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            Center(
                                                              child: Text(
                                                                '餐廳資訊',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: 20,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceEvenly,
                                                              children: [
                                                                Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceEvenly,
                                                                  children: [
                                                                    for (var textMap
                                                                        in textList)
                                                                      textMap[
                                                                          'contextTitle']
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceEvenly,
                                                                  children: [
                                                                    for (var textMap
                                                                        in textList)
                                                                      textMap[
                                                                          'contexts']
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(
                                                              height: 30,
                                                            ),
                                                            ElevatedButton(
                                                              style: ElevatedButton
                                                                  .styleFrom(
                                                                      primary:
                                                                          Colors
                                                                              .blue),
                                                              child: Text(
                                                                '確定',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                            ),
                                                            SizedBox(
                                                              width: 5,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                    showDialog(
                                                      // barrierDismissible: false,
                                                      context: context,
                                                      builder: (ctx) =>
                                                          contextsdDialog,
                                                    );
                                                  },
                                                )
                                              : SizedBox(
                                                  width: 60,
                                                ),
                                          ElevatedButton(
                                            child: Text(
                                              '選擇餐廳',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            onPressed: () {
                                              Provider.of<Auth>(context,
                                                      listen: false)
                                                  .updateUserCount('count_goto')
                                                  .whenComplete(() {
                                                var email = Provider.of<Auth>(
                                                        context,
                                                        listen: false)
                                                    .email;
                                                CollectionReference users =
                                                    FirebaseFirestore.instance
                                                        .collection('users');
                                                return users
                                                    .where('email',
                                                        isEqualTo: email)
                                                    .get()
                                                    .then((value) {
                                                  value.docs.forEach((element) {
                                                    users
                                                        .doc(element.id)
                                                        .get()
                                                        .then((value) {
                                                      showDialog(
                                                          barrierDismissible:
                                                              false,
                                                          context: context,
                                                          builder:
                                                              (ctx) =>
                                                                  WillPopScope(
                                                                    onWillPop:
                                                                        () async =>
                                                                            false,
                                                                    child:
                                                                        GamificationDialog(
                                                                      countType:
                                                                          'count_goto',
                                                                      selfCount:
                                                                          int.parse(
                                                                              value['count_goto']),
                                                                    ),
                                                                  ));
                                                    });
                                                  });
                                                });
                                              });
                                              ;
                                              userList =
                                                  RecommenderAlgo.updateCuisine(
                                                userArray: userList,
                                                restaurantsArray:
                                                    scoresList[index]
                                                        ['restaurantsList'],
                                              );
                                              updateUserCuisine();
                                              List<dynamic> logs = [
                                                {
                                                  'event': 'goto_restaurants',
                                                  'timestamp': DateTime.now()
                                                      .toIso8601String(),
                                                  'restaurantsId':
                                                      scoresList[index]['id'],
                                                },
                                              ];
                                              Provider.of<Auth>(context,
                                                      listen: false)
                                                  .updateUserLog(logs);
                                              Provider.of<Auth>(context,
                                                      listen: false)
                                                  .updaterestaurantsCount(
                                                'count_choosen',
                                                scoresList[index]['id'],
                                              );
                                              addTask(
                                                  scoresList[index]['name']);
                                            },
                                            style: ElevatedButton.styleFrom(
                                                primary: Colors.blue),
                                          ),
                                          SizedBox(width: 2),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                    ]),
                              ),
                            ),
                          );
                        }),
                  ],
                )),
    );
  }
}

import 'dart:convert';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/score_mapper.dart' as Score_mapper;
import './task_proactive_screen.dart';
import '../providers/auth.dart';
import '../widgets/gamification_dialog.dart';

class TaskAssignedAssignedScreen extends StatefulWidget {
  static const routeName = '/task_assigned_assigned';

  @override
  _TaskAssignedAssignedScreenState createState() =>
      _TaskAssignedAssignedScreenState();
}

class _TaskAssignedAssignedScreenState
    extends State<TaskAssignedAssignedScreen> {
  List tasksList = [];
  var currentLocation;
  bool isloaded = false;

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

  @override
  void initState() {
    super.initState();
    Geolocator.getCurrentPosition().then((currloc) {
      currentLocation = currloc;
      getTasks().then((value) {
        createAssessmentTask().whenComplete(() {
          isloaded = true;
          setState(() {});
        });
      });
    });
  }

  Future<void> createAssessmentTask() async {
    List contexts = [
      'air_conditioning',
      'crowdedness_dinein',
      'crowdedness_takeout',
      'music',
      'open',
      'parking',
      'promotion',
      'covid_change',
      'tv',
      'wifi',
    ];
    await Firebase.initializeApp();
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    for (String ctx in contexts) {
      String contextsLog = ctx + '_log';
      await restaurants.where(ctx, isNotEqualTo: 0).get().then((value) {
        value.docs.forEach((element) {
          Map<String, dynamic> taskMap = {};
          bool isTask = false;
          Map contextOptionPairs = {};
          if (ctx == 'crowdedness_dinein' || ctx == 'crowdedness_takeout') {
            int countless = 0;
            int countMiddle = 0;
            int countLot = 0;
            for (var m in element[contextsLog]) {
              if (m['score'] == 1) {
                countless++;
              } else if (m['score'] == 0.5) {
                countMiddle++;
              } else {
                countLot++;
              }
            }
            if (countless == countMiddle &&
                countMiddle == countLot &&
                countLot == countless) {
              isTask = true;
              contextOptionPairs[ctx] =
                  Score_mapper.scoreMapper[ctx].keys.toList();
              contextOptionPairs[ctx].remove('');
            }
            if (countless == countMiddle && countLot < countless) {
              isTask = true;
              contextOptionPairs[ctx] =
                  Score_mapper.scoreMapper[ctx].keys.toList();
              contextOptionPairs[ctx].remove('');
              contextOptionPairs[ctx].removeAt(2);
            }
            if (countMiddle == countLot && countless < countMiddle) {
              isTask = true;
              contextOptionPairs[ctx] =
                  Score_mapper.scoreMapper[ctx].keys.toList();
              contextOptionPairs[ctx].remove('');
              contextOptionPairs[ctx].removeAt(0);
            }
            if (countLot == countless && countMiddle < countLot) {
              isTask = true;
              contextOptionPairs[ctx] =
                  Score_mapper.scoreMapper[ctx].keys.toList();
              contextOptionPairs[ctx].remove('');
              contextOptionPairs[ctx].removeAt(1);
            }
          } else {
            int countOne = 0;
            int countNagetiveOne = 0;
            for (var m in element[contextsLog]) {
              if (m['score'] == 1) {
                countOne++;
              } else {
                countNagetiveOne++;
              }
            }
            if (countOne == countNagetiveOne) {
              isTask = true;
              contextOptionPairs[ctx] =
                  Score_mapper.scoreMapper[ctx].keys.toList();
              contextOptionPairs[ctx].remove('');
            }
          }
          if (isTask) {
            taskMap['lat'] = element['lat'];
            taskMap['lng'] = element['lng'];
            taskMap['task_type'] = 'assessment';
            taskMap['context_title'] = ctx;
            taskMap['contextOptionPairs'] = contextOptionPairs;
            taskMap['restaurants_name'] = element['name'];
            taskMap['restaurants_id'] = element.id;
            tasksList.add(taskMap);
          }
        });
      });
    }
  }

  Future<void> getTasks() async {
    await Firebase.initializeApp();
    String email = Provider.of<Auth>(context, listen: false).email;
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks
        .where('complete', isEqualTo: 'false')
        .where('task_type', isEqualTo: 'assigned')
        .where('requester', isNotEqualTo: email)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        print('Empty!');
        return;
      }
      querySnapshot.docs.forEach((element) {
        tasksList.add(Map<String, dynamic>.from(element.data()));
      });
    });
  }

  void selectAssignedTask(BuildContext context, Map taskMap) {
    Navigator.of(context).pushNamed(
      TaskProactiveScreen.routeName,
      arguments: {
        'restaurantsName': json.decode(taskMap['restaurants'])['name'],
        'restaurantsId': taskMap['restaurantsId'],
        'task_type': 'assigned',
        'owner': taskMap['requester'],
        'timestamp': taskMap['create_time'],
      },
    );
  }

  void selectAssessmentTask(BuildContext context, Map taskMap) {
    showDialog(
      // barrierDismissible: false,
      context: context,
      builder: (ctx) => ContextsDialog(
        contexts: taskMap['contextOptionPairs'][taskMap['context_title']],
        taskMap: taskMap,
      ),
    );
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: !isloaded
          ? Center(
              child: CircularProgressIndicator(),
            )
          : (tasksList.length == 0
              ? Center(
                  child: Text(
                    '目前沒有任務',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView(
                  children: [
                    RichText(
                      text: TextSpan(
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: '任務清單 - 幫助他人蒐集餐廳資訊\n\n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            TextSpan(
                              text: '點選想蒐集資訊的餐廳',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ]),
                    ),
                    SizedBox(height: 20),
                    ListView.builder(
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: tasksList.length,
                        itemBuilder: (context, index) {
                          print(tasksList[index]);
                          return InkWell(
                            onTap: () => tasksList[index]['task_type'] ==
                                    'assigned'
                                ? selectAssignedTask(context, tasksList[index])
                                : selectAssessmentTask(
                                    context, tasksList[index]),
                            child: Card(
                              elevation: 8,
                              margin: EdgeInsets.all(5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF333366),
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 30,
                                    ),
                                    Icon(
                                      Icons.restaurant,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 30,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 10,
                                        ),
                                        tasksList[index]['task_type'] ==
                                                'assigned'
                                            ? Text(
                                                json.decode(tasksList[index]
                                                    ['restaurants'])['name'],
                                                overflow: TextOverflow.fade,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : RichText(
                                                overflow: TextOverflow.fade,
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                        text: tasksList[index][
                                                            'restaurants_name']),
                                                    TextSpan(
                                                      text:
                                                          '(${contextNameTranslater[tasksList[index]['context_title']]})',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          '您在餐廳附近嗎?\n幫助他人蒐集餐廳的即時資訊!',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.yellow,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        tasksList[index]['task_type'] ==
                                                'assigned'
                                            ? Text(
                                                '距離: ' +
                                                    calculateDistance(
                                                      currentLocation.latitude,
                                                      currentLocation.longitude,
                                                      double.parse(json.decode(
                                                              tasksList[index][
                                                                  'restaurants'])[
                                                          'lat']),
                                                      double.parse(json.decode(
                                                              tasksList[index][
                                                                  'restaurants'])[
                                                          'lng']),
                                                    ).toStringAsFixed(2) +
                                                    '公里',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                '距離: ' +
                                                    calculateDistance(
                                                      currentLocation.latitude,
                                                      currentLocation.longitude,
                                                      double.parse(
                                                          tasksList[index]
                                                              ['lat']),
                                                      double.parse(
                                                          tasksList[index]
                                                              ['lng']),
                                                    ).toStringAsFixed(2) +
                                                    '公里',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        tasksList[index]['task_type'] ==
                                                'assigned'
                                            ? Align(
                                                child: Text(
                                                  tasksList[index]
                                                              ['create_time']
                                                          .substring(
                                                              0,
                                                              tasksList[index][
                                                                      'create_time']
                                                                  .indexOf(
                                                                      'T')) +
                                                      '  ' +
                                                      tasksList[index]
                                                              ['create_time']
                                                          .substring(
                                                              tasksList[index][
                                                                          'create_time']
                                                                      .indexOf(
                                                                          'T') +
                                                                  1,
                                                              16),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                alignment: Alignment.bottomLeft,
                                              )
                                            : Text(
                                                'Right now',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                        SizedBox(height: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                  ],
                )),
    );
  }
}

class ContextButton {
  String name;
  int index;
  ContextButton({this.name, this.index});
}

class ContextsDialog extends StatefulWidget {
  final List contexts;
  final Map taskMap;

  ContextsDialog({this.contexts, this.taskMap});

  @override
  _ContextsDialogState createState() => _ContextsDialogState();
}

class _ContextsDialogState extends State<ContextsDialog> {
  List buttons;
  String radioItem;
  int id;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    buttons = this
        .widget
        .contexts
        .map(
          (e) => ContextButton(
            name: e,
            index: this.widget.contexts.indexOf(e),
          ),
        )
        .toList();
    radioItem = this.widget.contexts[0];
    id = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 300,
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Text(
                this.widget.taskMap['restaurants_name'],
                overflow: TextOverflow.fade,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                '幫助選擇正確的餐廳即時資訊',
                overflow: TextOverflow.fade,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.red,
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            for (var btn in buttons)
              RadioListTile(
                activeColor: Colors.pink[300],
                title: Text(btn.name),
                groupValue: id,
                value: btn.index,
                onChanged: (value) => setState(() {
                  radioItem = btn.name;
                  id = btn.index;
                }),
              ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red),
                child: Text(
                  '確定',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () async {
                  await Firebase.initializeApp();
                  CollectionReference restaurants =
                      FirebaseFirestore.instance.collection('restaurants');
                  List<dynamic> logs = [
                    {
                      'score': Score_mapper
                              .scoreMapper[this.widget.taskMap['context_title']]
                          [radioItem],
                      'timestamp': DateTime.now().toIso8601String(),
                    }
                  ];
                  restaurants
                      .doc(this.widget.taskMap['restaurants_id'])
                      .update({
                    this.widget.taskMap['context_title']: Score_mapper
                            .scoreMapper[this.widget.taskMap['context_title']]
                        [radioItem],
                    this.widget.taskMap['context_title'] + '_log':
                        FieldValue.arrayUnion(logs),
                  });
                  Provider.of<Auth>(context, listen: false)
                      .updateUserCount('count_verify_proactive');
                  List<dynamic> userlogs = [
                    {
                      'event': 'assess_proactive',
                      'timestamp': DateTime.now().toIso8601String(),
                    }
                  ];
                  Provider.of<Auth>(context, listen: false)
                      .updateUserLog(userlogs);
                  Navigator.pushNamedAndRemoveUntil(context, "/", (r) => false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

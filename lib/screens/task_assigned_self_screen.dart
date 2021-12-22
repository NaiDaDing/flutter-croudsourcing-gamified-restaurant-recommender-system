import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/score_mapper.dart' as Score_mapper;
import '../providers/auth.dart';
import '../widgets/rating.dart';
import './photo_screen.dart';
import '../widgets/gamification_dialog.dart';

class TaskAssignedSelfScreen extends StatefulWidget {
  @override
  _TaskAssignedSelfScreenState createState() => _TaskAssignedSelfScreenState();
}

class _TaskAssignedSelfScreenState extends State<TaskAssignedSelfScreen> {
  List tasksList = [];
  bool isloaded = false;
  int _rating;

  Map contextNameTranslater = {
    'open': '營業狀況',
    'crowdedness_dinein': '餐廳內用人潮',
    'crowdedness_takeout': '餐廳排隊人潮',
    'safety': '實施防疫措施',
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
    getAssignedTasks().then((value) {
      getRankingTasks().then((value) {
        isloaded = true;
        setState(() {});
      });
    });
  }

  Future<void> getAssignedTasks() async {
    await Firebase.initializeApp();
    String email = Provider.of<Auth>(context, listen: false).email;
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks
        .where('complete', isEqualTo: 'false')
        .where('task_type', isEqualTo: 'solveAssigned')
        .where('owner', isEqualTo: email)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return;
      }
      querySnapshot.docs.forEach((element) {
        tasksList.add(Map<String, dynamic>.from(element.data()));
      });
    });
  }

  Future<void> getRankingTasks() async {
    await Firebase.initializeApp();
    String email = Provider.of<Auth>(context, listen: false).email;
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks
        .where('complete', isEqualTo: 'false')
        .where('task_type', isEqualTo: 'rating')
        .where('owner', isEqualTo: email)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return;
      }
      querySnapshot.docs.forEach((element) {
        tasksList.add(Map<String, dynamic>.from(element.data()));
      });
    });
  }

  Future<void> changeAssignedTaskComplete(
      String timestamp, String quality) async {
    await Firebase.initializeApp();
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    var email = Provider.of<Auth>(context, listen: false).email;
    tasks
        .where('owner', isEqualTo: email)
        .where('create_time', isEqualTo: timestamp)
        .get()
        .then((value) {
      value.docs.forEach((element) {
        List<dynamic> logs = [
          {
            'evaluator': email,
            'quality': quality,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ];
        tasks.doc(element.id).update({
          'complete': 'true',
          'record': FieldValue.arrayUnion(logs),
        });
      });
    });
  }

  Future<void> changeRatingTaskComplete(String timestamp, String score) async {
    await Firebase.initializeApp();
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    var email = Provider.of<Auth>(context, listen: false).email;
    tasks
        .where('owner', isEqualTo: email)
        .where('create_time', isEqualTo: timestamp)
        .get()
        .then((value) {
      value.docs.forEach((element) {
        List<dynamic> logs = [
          {
            'score': score,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ];
        tasks.doc(element.id).update({
          'complete': 'true',
          'record': FieldValue.arrayUnion(logs),
        });
      });
    });
  }

  void selectAssignedTask(BuildContext context, Map taskMap) {
    List textList = [];
    taskMap['contexts'].forEach((key, value) {
      if (value != 0) {
        textList.add({
          'contextTitle': Text(
            contextNameTranslater[key],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          'contexts': Text(
            Score_mapper.scoreMapper[key].keys.firstWhere(
                (k) => Score_mapper.scoreMapper[key][k] == value,
                orElse: () => null),
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.red,
            ),
          )
        });
      }
    });
    Dialog assignedDialog = Dialog(
      child: Container(
        height: 300,
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          taskMap['url'] == ''
              ? Center(
                  child: Text(
                    '餐廳資訊',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      '餐廳資訊',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      child: Row(
                        children: [
                          Text(
                            '查看照片',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                          Icon(
                            Icons.photo,
                            color: Colors.lightBlue,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoScreen(
                                url: taskMap['url'],
                                situation: 'single_photo',
                              ),
                            ));
                      },
                    )
                  ],
                ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var textMap in textList) textMap['contextTitle']
                ],
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [for (var textMap in textList) textMap['contexts']],
              ),
            ],
          ),
          SizedBox(
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.red),
                child: Text(
                  '資訊\n對我沒有幫助',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  List<dynamic> logs = [
                    {
                      'event': 'evaluate_solver_quality',
                      'timestamp': DateTime.now().toIso8601String(),
                      'solver': taskMap['solver'],
                      'quality': 'bad',
                    },
                  ];
                  Provider.of<Auth>(context, listen: false).updateUserLog(logs);
                  Provider.of<Auth>(context, listen: false)
                      .updateUserCount('count_verify_assigned')
                        ..whenComplete(() {
                          var email =
                              Provider.of<Auth>(context, listen: false).email;
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
                                            countType: 'count_verify_assigned',
                                            selfCount: int.parse(
                                                value['count_verify_assigned']),
                                          ),
                                        ));
                              });
                            });
                          });
                        });
                  ;
                  changeAssignedTaskComplete(taskMap['create_time'], 'bad');
                },
              ),
              SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(primary: Colors.blue),
                child: Text(
                  '資訊\n對我有幫助',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  List<dynamic> logs = [
                    {
                      'event': 'evaluate_solver_quality',
                      'timestamp': DateTime.now().toIso8601String(),
                      'solver': taskMap['solver'],
                      'quality': 'good',
                    },
                  ];
                  Provider.of<Auth>(context, listen: false).updateUserLog(logs);
                  Provider.of<Auth>(context, listen: false)
                      .updateUserCount('count_verify_assigned')
                        ..whenComplete(() {
                          var email =
                              Provider.of<Auth>(context, listen: false).email;
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
                                            countType: 'count_verify_assigned',
                                            selfCount: int.parse(
                                                value['count_verify_assigned']),
                                          ),
                                        ));
                              });
                            });
                          });
                        });
                  changeAssignedTaskComplete(taskMap['create_time'], 'good');
                },
              ),
              SizedBox(width: 10),
            ],
          ),
        ]),
      ),
    );
    showDialog(
      // barrierDismissible: false,
      context: context,
      builder: (ctx) => assignedDialog,
    );
  }

  void selectRankingTask(BuildContext context, Map taskMap) {
    Dialog ratingDialog = Dialog(
      child: Container(
        height: 300.0,
        width: 300.0,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: 30,
              ),
              Flexible(
                child: Text(
                  '是否滿意${taskMap['restaurants_name']}',
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(
                height: 70,
              ),
              Rating((rating) {
                setState(() {
                  _rating = rating;
                });
              }, 5),
              SizedBox(
                height: 80,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 180,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Colors.blue),
                    child: Text(
                      '確定',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      List<dynamic> logs = [
                        {
                          'event': 'rating_restaurants',
                          'timestamp': DateTime.now().toIso8601String(),
                          'rating': _rating.toString(),
                          'restaurants_name': taskMap['restaurants_name'],
                        },
                      ];
                      Provider.of<Auth>(context, listen: false)
                          .updateUserLog(logs);
                      Provider.of<Auth>(context, listen: false)
                          .updateUserCount('count_rating')
                          .whenComplete(() {
                        var email =
                            Provider.of<Auth>(context, listen: false).email;
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
                                          countType: 'count_rating',
                                          selfCount:
                                              int.parse(value['count_rating']),
                                        ),
                                      ));
                            });
                          });
                        });
                      });
                      changeRatingTaskComplete(
                          taskMap['create_time'], _rating.toString());
                    },
                  ),
                  SizedBox(
                    width: 10,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
    showDialog(
      // barrierDismissible: false,
      context: context,
      builder: (ctx) => ratingDialog,
    );
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
                    '目前沒有需要確認的新餐廳',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView(
                  children: [
                    Text(
                      '個人任務與訊息',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    ListView.builder(
                        physics: ScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: tasksList.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () => tasksList[index]['task_type'] ==
                                    'solveAssigned'
                                ? selectAssignedTask(context, tasksList[index])
                                : selectRankingTask(context, tasksList[index]),
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
                                      Icons.message,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 30,
                                    ),
                                    tasksList[index]['task_type'] ==
                                            'solveAssigned'
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                tasksList[index]
                                                        ['restaurants_name'] +
                                                    ' 即時資訊',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                '您先前想了解的餐廳情況已經完成\n請點選查看',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.yellow,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Align(
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
                                                alignment: Alignment.center,
                                              ),
                                              SizedBox(height: 20),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                '您對 ' +
                                                    tasksList[index]
                                                        ['restaurants_name'] +
                                                    ' 的評價',
                                                overflow: TextOverflow.fade,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                '請點擊評分',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.yellow,
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Align(
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
                                                alignment: Alignment.center,
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

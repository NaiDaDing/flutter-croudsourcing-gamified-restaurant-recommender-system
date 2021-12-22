import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import './check_add_map_screen.dart';
import '../providers/auth.dart';

class TaskAssignedAddScreen extends StatefulWidget {
  static const routeName = '/task_assigned_add';

  @override
  _TaskAssignedAddScreenState createState() => _TaskAssignedAddScreenState();
}

class _TaskAssignedAddScreenState extends State<TaskAssignedAddScreen> {
  List tasksList = [];
  bool isloaded = false;
  Map<String, dynamic> priceType = {
    'm': '150以下',
    'mm': '150-600',
    'mmm': '600-1200',
    'mmmm': '1200以上',
  };

  @override
  void initState() {
    super.initState();
    getTasks().then((value) {
      isloaded = true;
      setState(() {});
    });
  }

  Future<void> getTasks() async {
    await Firebase.initializeApp();
    String email = Provider.of<Auth>(context, listen: false).email;
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks
        .where('complete', isEqualTo: 'false')
        .where('task_type', isEqualTo: 'addMap')
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

  void selectTask(BuildContext context, Map taskMap) {
    var resMap = json.decode(taskMap['restaurants']);
    Navigator.of(context).pushNamed(
      CheckAddMapScreen.routeName,
      arguments: {
        'restaurants': resMap,
        'task': taskMap,
      },
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
                    RichText(
                      text: TextSpan(
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: '任務清單 - 確認他人新增的餐廳\n\n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            TextSpan(
                              text: '假如餐廳名稱與資訊確認無誤，請點選以確認地點',
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
                          return InkWell(
                            onTap: () => selectTask(
                              context,
                              tasksList[index],
                            ),
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
                                        Text(
                                          json.decode(tasksList[index]
                                              ['restaurants'])['name'],
                                          overflow: TextOverflow.fade,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Container(
                                          height: 5,
                                          color: Colors.red,
                                        ),
                                        Text(
                                          '口味: ' +
                                              json
                                                  .decode(json.decode(
                                                          tasksList[index]
                                                              ['restaurants'])[
                                                      'cuisine_type'])
                                                  .keys
                                                  .firstWhere(
                                                      (k) =>
                                                          json.decode(json.decode(
                                                                  tasksList[
                                                                          index]
                                                                      [
                                                                      'restaurants'])[
                                                              'cuisine_type'])[k] ==
                                                          1,
                                                      orElse: () => '未提供'),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '價格: ' +
                                              priceType[json.decode(
                                                      tasksList[index]
                                                          ['restaurants'])[
                                                  'price_segment']],
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '用餐方式: ' +
                                              json
                                                  .decode(json.decode(tasksList[
                                                          index]
                                                      ['restaurants'])['inout'])
                                                  .keys
                                                  .firstWhere(
                                                      (k) =>
                                                          json.decode(json.decode(
                                                                  tasksList[
                                                                          index]
                                                                      [
                                                                      'restaurants'])[
                                                              'inout'])[k] ==
                                                          1,
                                                      orElse: () => '未提供'),
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Align(
                                          child: Text(
                                            tasksList[index]['create_time']
                                                    .substring(
                                                        0,
                                                        tasksList[index]
                                                                ['create_time']
                                                            .indexOf('T')) +
                                                '  ' +
                                                tasksList[index]['create_time']
                                                    .substring(
                                                        tasksList[index][
                                                                    'create_time']
                                                                .indexOf('T') +
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

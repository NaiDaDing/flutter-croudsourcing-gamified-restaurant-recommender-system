import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/auth.dart';

class GamificationDialog extends StatefulWidget {
  final int selfCount;
  final String countType;

  GamificationDialog({this.selfCount, this.countType});

  @override
  _GamificationDialogState createState() => _GamificationDialogState();
}

class _GamificationDialogState extends State<GamificationDialog> {
  String condition;
  bool isLoaded = false;
  List usersList = [];

  final Map<String, int> pointMapper = {
    'count_proactive': 5,
    'count_assigned': 5,
    'count_requester': 3,
    'count_add': 8,
    'count_picture': 8,
    'count_verify_add': 5,
    'count_verify_assigned': 5,
    'count_verify_proactive': 5,
    'count_recommend': 3,
    'count_goto': 5,
    'count_rating': 5,
  };

  final Map<String, dynamic> badgeMapper = {
    'count_proactive': {
      'sliver': 7,
      'gold': 21,
      'task': '主動蒐集即時資訊',
    },
    'count_assigned': {
      'sliver': 7,
      'gold': 21,
      'task': '幫助他人蒐集即時資訊',
    },
    'count_requester': {
      'sliver': 7,
      'gold': 21,
      'task': '發起蒐集即時資訊任務',
    },
    'count_add': {
      'sliver': 3,
      'gold': 9,
      'task': '新增餐廳',
    },
    'count_picture': {
      'sliver': 3,
      'gold': 9,
      'task': '上傳相關照片',
    },
    'count_verify_add': {
      'sliver': 7,
      'gold': 21,
      'task': '驗證他人上傳資訊',
    },
    'count_verify_assigned': {
      'sliver': 7,
      'gold': 21,
      'task': '驗證他人上傳資訊',
    },
    'count_verify_proactive': {
      'sliver': 7,
      'gold': 21,
      'task': '驗證他人上傳資訊',
    },
    'count_recommend': {
      'sliver': 14,
      'gold': 28,
      'task': '使用推薦系統',
    },
    'count_goto': {
      'sliver': 14,
      'gold': 28,
      'task': '前往推薦餐廳',
    },
    'count_rating': {
      'sliver': 14,
      'gold': 28,
      'task': '給予推薦餐廳評分',
    },
  };

  void initState() {
    super.initState();
    getUsersRank();
  }

  Future<void> getUsersRank() async {
    await Firebase.initializeApp();
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users.get().then((value) {
      final int documents = value.docs.length;
      value.docs.forEach((element) {
        return users.doc(element.id).get().then((value) {
          int points = 0;
          for (var k in pointMapper.keys) {
            points += int.parse(value.get(k)) * pointMapper[k];
          }
          final Map userMap = {
            'name': value['name'],
            'points': points,
          };
          usersList.add(userMap);
        }).whenComplete(() {
          if (usersList.length == documents) {
            usersList.sort((a, b) => a['points'].compareTo(b['points']));
            usersList = usersList.reversed.toList();
          }
          setState(() {
            isLoaded = true;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    condition = Provider.of<Auth>(context, listen: false).condition;
    print(condition);
    return condition == 'control'
        ? AlertDialog(
            title: Text('提示'),
            content: Text('成功!'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, "/", (r) => false);
                  },
                  child: Text('Okey!'))
            ],
          )
        : (condition == 'self'
            ? Dialog(
                child: Container(
                  height: 300,
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          '個人數據統計',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Text(
                            badgeMapper[this.widget.countType]['task'] +
                                '次數累計 : ',
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            this.widget.selfCount.toString(),
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          this.widget.selfCount <
                                  badgeMapper[this.widget.countType]['gold']
                              ? Text(
                                  '距離獲得該項目 ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  '您已蒐集完該任務所有徽章!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          Text(
                            this.widget.selfCount <
                                    badgeMapper[this.widget.countType]['sliver']
                                ? '銀牌'
                                : this.widget.selfCount <
                                        badgeMapper[this.widget.countType]
                                            ['gold']
                                    ? '金牌'
                                    : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: this.widget.selfCount <
                                      badgeMapper[this.widget.countType]
                                          ['sliver']
                                  ? Colors.blueGrey
                                  : Colors.yellow,
                            ),
                          ),
                          Text(
                            this.widget.selfCount <
                                    badgeMapper[this.widget.countType]['sliver']
                                ? ' 剩' +
                                    (badgeMapper[this.widget.countType]
                                                ['sliver'] -
                                            this.widget.selfCount)
                                        .toString() +
                                    '次'
                                : this.widget.selfCount <
                                        badgeMapper[this.widget.countType]
                                            ['gold']
                                    ? ' 剩' +
                                        (badgeMapper[this.widget.countType]
                                                ['gold'] -
                                            badgeMapper[
                                                this.widget.countType]) +
                                        '次'.toString()
                                    : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 100,
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
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', (r) => false);
                        },
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              )
            : (condition == 'social'
                ? Dialog(
                    child: !isLoaded
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : Container(
                            height: 350,
                            padding: EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Center(
                                  child: Text(
                                    '分數排行數據',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '您獲得: ${pointMapper[this.widget.countType]}分',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                for (var i = 0; i <= 2; i++)
                                  Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 5,
                                          blurRadius: 7,
                                          offset: Offset(0,
                                              3), // changes position of shadow
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Center(
                                                    child: Icon(
                                                  FontAwesomeIcons.crown,
                                                  size: 36,
                                                  color: Colors.yellow,
                                                )),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0, top: 6),
                                                  child: Center(
                                                      child: Text(
                                                    (i + 1).toString(),
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: 15,
                                            ),
                                            Text(
                                              usersList[i]['name'],
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          usersList[i]['points'].toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.brown,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                SizedBox(
                                  height: 20,
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      primary: Colors.blue),
                                  child: Text(
                                    '確定',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, '/', (r) => false);
                                  },
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          ),
                  )
                : Dialog(
                    child: !isLoaded
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : Container(
                            height: 500,
                            padding: EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Center(
                                  child: Text(
                                    '個人數據統計',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      badgeMapper[this.widget.countType]
                                              ['task'] +
                                          '次數累計 : ',
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      this.widget.selfCount.toString(),
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    this.widget.selfCount <
                                            badgeMapper[this.widget.countType]
                                                ['gold']
                                        ? Text(
                                            '距離獲得該項目',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : Text(
                                            '您已蒐集完該徽章!',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    Text(
                                      this.widget.selfCount <
                                              badgeMapper[this.widget.countType]
                                                  ['sliver']
                                          ? '銀牌'
                                          : this.widget.selfCount <
                                                  badgeMapper[this
                                                      .widget
                                                      .countType]['gold']
                                              ? '金牌'
                                              : '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: this.widget.selfCount <
                                                badgeMapper[this
                                                    .widget
                                                    .countType]['sliver']
                                            ? Colors.blueGrey
                                            : Colors.yellow,
                                      ),
                                    ),
                                    Text(
                                      this.widget.selfCount <
                                              badgeMapper[this.widget.countType]
                                                  ['sliver']
                                          ? ' 剩' +
                                              (badgeMapper[this
                                                              .widget
                                                              .countType]
                                                          ['sliver'] -
                                                      this.widget.selfCount)
                                                  .toString() +
                                              '次'
                                          : this.widget.selfCount <
                                                  badgeMapper[this
                                                      .widget
                                                      .countType]['gold']
                                              ? ' 剩' +
                                                  (badgeMapper[this
                                                          .widget
                                                          .countType]['gold'] -
                                                      badgeMapper[this
                                                          .widget
                                                          .countType]) +
                                                  '次'.toString()
                                              : '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Center(
                                  child: Text(
                                    '分數排行數據',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '您獲得: ${pointMapper[this.widget.countType]}分',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                for (var i = 0; i < 2; i++)
                                  Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 5,
                                          blurRadius: 7,
                                          offset: Offset(0,
                                              3), // changes position of shadow
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Center(
                                                    child: Icon(
                                                  FontAwesomeIcons.crown,
                                                  size: 36,
                                                  color: Colors.yellow,
                                                )),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0, top: 6),
                                                  child: Center(
                                                      child: Text(
                                                    (i + 1).toString(),
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: 15,
                                            ),
                                            Text(
                                              usersList[i]['name'],
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          usersList[i]['points'].toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.brown,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                SizedBox(
                                  height: 20,
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      primary: Colors.blue),
                                  child: Text(
                                    '確定',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, '/', (r) => false);
                                  },
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          ),
                  )));
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/auth.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final String condition =
        Provider.of<Auth>(context, listen: false).condition;
    return ListView(
      children: [
        Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.face,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Color(0XFFF5F6F9),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(
                      width: 20,
                    ),
                    Text(
                      Provider.of<Auth>(context, listen: false).name,
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Color(0XFFF5F6F9),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.email),
                    SizedBox(
                      width: 20,
                    ),
                    Text(
                      Provider.of<Auth>(context, listen: false).email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        (condition == 'self' || condition == 'self_social')
            ? BadgeTable()
            : Leaderboard(),
        SizedBox(
          height: 10,
        ),
        condition == 'self_social' ? Leaderboard() : Container(),
        SizedBox(
          height: 10,
        ),
      ],
    );
  }
}

class BadgeTable extends StatefulWidget {
  @override
  _BadgeTableState createState() => _BadgeTableState();
}

class _BadgeTableState extends State<BadgeTable> {
  bool isLoaded = false;
  final List<Badge> badges = [
    Badge(
      name: '主動蒐集資訊徽章',
      toSilver: 7,
      toGold: 21,
      countType: ['count_proactive'],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: '累積主動蒐集餐廳即時資訊的次數\n\n',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 7次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 21次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
    Badge(
      name: '幫助他人徽章',
      toSilver: 7,
      toGold: 21,
      countType: ['count_assigned'],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: '累積幫助他人蒐集餐廳即時資訊的次數\n\n',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 7次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 21次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
    Badge(
      name: '蒐集任務發起徽章',
      toSilver: 7,
      toGold: 21,
      countType: ['count_requester'],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: "累積發起\"我想知道某家餐廳資訊\"的次數\n\n",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 7次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 21次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
    Badge(
      name: '添加新餐廳徽章',
      toSilver: 3,
      toGold: 9,
      countType: ['count_add'],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: "累積在地圖上添加新餐廳的次數\n\n",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 3次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 9次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
    Badge(
      name: '上傳照片徽章',
      toSilver: 3,
      toGold: 9,
      countType: ['count_picture'],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: "累積上傳照片的次數\n\n",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 3次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 9次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
    Badge(
      name: '驗證他人資訊徽章',
      toSilver: 7,
      toGold: 21,
      countType: [
        'count_verify_add',
        'count_verify_assigned',
        'count_verify_proactive',
      ],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: "累積驗證他人所上傳資訊的次數\n\n",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 7次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 21次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
    Badge(
      name: '使用推薦功能徽章',
      toSilver: 14,
      toGold: 28,
      countType: ['count_recommend'],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: "累積使用推薦系統的次數\n\n",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 14次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 28次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
    Badge(
      name: '前往餐廳徽章',
      toSilver: 14,
      toGold: 28,
      countType: ['count_goto'],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: "累積前往推薦餐廳的次數\n\n",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 14次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 28次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
    Badge(
      name: '餐廳評分徽章',
      toSilver: 14,
      toGold: 28,
      countType: ['count_rating'],
      detail: RichText(
        text: TextSpan(
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: "累積為推薦餐廳評分的次數\n\n",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: '銀徽章: 14次\n',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              TextSpan(
                text: '金徽章: 28次',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ]),
      ),
    ),
  ];

  Future<void> getCounts() async {
    await Firebase.initializeApp();
    final String email = Provider.of<Auth>(context, listen: false).email;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    users.where('email', isEqualTo: email).get().then((value) {
      value.docs.forEach((element) {
        users.doc(element.id).get().then((value) {
          for (var badge in badges) {
            int count = 0;
            for (var i = 0; i < badge.countType.length; i++) {
              count += int.parse(value.get(badge.countType[i]));
            }
            badge.setNowCount(count);
          }
        }).whenComplete(() {
          setState(() {
            isLoaded = true;
          });
        });
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCounts().whenComplete(() {});
  }

  @override
  Widget build(BuildContext context) {
    return !isLoaded
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Container(
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              children: [
                Center(
                    child: Text(
                  '個人成就',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                )),
                SizedBox(
                  height: 20,
                ),
                GridView.count(
                  crossAxisCount: 3,
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    for (var badge in badges)
                      InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                    title: Text('徽章說明'),
                                    content: badge.detail,
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text('確認')),
                                    ],
                                  ));
                        },
                        child: Container(
                          child: Column(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: badge.nowCount < badge.toSilver
                                    ? Colors.brown
                                    : badge.nowCount < badge.toGold
                                        ? Colors.blueGrey
                                        : Colors.yellow[700],
                                size: 50,
                              ),
                              Text(
                                badge.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ],
            ),
          );
  }
}

class Badge {
  final String name;
  final int toSilver;
  final int toGold;
  final List countType;
  final RichText detail;
  int nowCount;

  Badge({
    this.name,
    this.toSilver,
    this.toGold,
    this.countType,
    this.detail,
  });

  void setNowCount(int count) {
    nowCount = count;
  }
}

class Leaderboard extends StatefulWidget {
  @override
  _LeaderboardState createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  bool isLoaded = false;
  List<LeaderBoardTile> lbList = [];
  List<dynamic> usersList = [];

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

  Future<void> getPointsAndRank() async {
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
            'email': value['email'],
            'name': value['name'],
            'points': points,
          };
          usersList.add(userMap);
        }).whenComplete(() {
          if (usersList.length == documents) {
            usersList.sort((a, b) => a['points'].compareTo(b['points']));
            usersList = usersList.reversed.toList();
            String email = Provider.of<Auth>(context, listen: false).email;
            final int rank =
                usersList.indexWhere((element) => element['email'] == email) +
                    1;
            if (usersList.length >= 5) {
              if (rank == 1 || rank == 2) {
                for (var i = 0; i < 5; i++) {
                  if (usersList[i]['email'] == email) {
                    lbList.add(LeaderBoardTile(
                      name: usersList[i]['name'],
                      points: usersList[i]['points'],
                      rank: rank,
                      color: Colors.orange,
                    ));
                  } else {
                    lbList.add(LeaderBoardTile(
                      name: usersList[i]['name'],
                      points: usersList[i]['points'],
                      rank: i + 1,
                      color: Colors.white,
                    ));
                  }
                }
              } else if (rank == usersList.length ||
                  rank == usersList.length - 1) {
                for (var i = usersList.length - 1;
                    i >= usersList.length - 5;
                    i--) {
                  if (usersList[i]['email'] == email) {
                    lbList.add(LeaderBoardTile(
                      name: usersList[i]['name'],
                      points: usersList[i]['points'],
                      rank: rank,
                      color: Colors.orange,
                    ));
                  } else {
                    lbList.add(LeaderBoardTile(
                      name: usersList[i]['name'],
                      points: usersList[i]['points'],
                      rank: i + 1,
                      color: Colors.white,
                    ));
                  }
                }
                lbList = lbList.reversed.toList();
              } else {
                for (var i = rank - 2; i <= rank + 2; i++) {
                  if (usersList[i]['email'] == email) {
                    lbList.add(LeaderBoardTile(
                      name: usersList[i]['name'],
                      points: usersList[i]['points'],
                      rank: rank,
                      color: Colors.orange,
                    ));
                  } else {
                    lbList.add(LeaderBoardTile(
                      name: usersList[i]['name'],
                      points: usersList[i]['points'],
                      rank: i + 1,
                      color: Colors.white,
                    ));
                  }
                }
              }
            } else {
              for (var i = 0; i < usersList.length; i++) {
                if (usersList[i]['email'] == email) {
                  lbList.add(LeaderBoardTile(
                    name: usersList[i]['name'],
                    points: usersList[i]['points'],
                    rank: rank,
                    color: Colors.orange,
                  ));
                } else {
                  lbList.add(LeaderBoardTile(
                    name: usersList[i]['name'],
                    points: usersList[i]['points'],
                    rank: i + 1,
                    color: Colors.white,
                  ));
                }
              }
            }
            setState(() {
              isLoaded = true;
            });
          }
        });
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPointsAndRank();
  }

  @override
  Widget build(BuildContext context) {
    return !isLoaded
        ? Center(child: CircularProgressIndicator())
        : Container(
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              children: [
                Center(
                    child: Text(
                  '排行榜',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                )),
                SizedBox(
                  height: 20,
                ),
                for (var tile in lbList)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: tile.color,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 0.0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Center(
                                        child: Icon(
                                      FontAwesomeIcons.crown,
                                      size: 36,
                                      color: Colors.yellow,
                                    )),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, top: 6),
                                      child: Center(
                                          child: Text(
                                        tile.rank.toString(),
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              Text(
                                tile.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 20),
                              )
                            ],
                          ),
                          Text(
                            tile.points.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.brown,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
  }
}

class LeaderBoardTile {
  final int points;
  final String name;
  final int rank;
  final Color color;

  LeaderBoardTile({this.name, this.points, this.rank, this.color});
}

import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../models/score_mapper.dart' as ScoreMapper;
import '../providers/auth.dart';
import '../widgets/gamification_dialog.dart';

class TaskProactiveScreen extends StatefulWidget {
  static const routeName = '/task_proactive';

  @override
  _TaskProactiveScreenState createState() => _TaskProactiveScreenState();
}

class _TaskProactiveScreenState extends State<TaskProactiveScreen> {
  final List contexts = ContextsListTileModel.getContext();

  Map<String, dynamic> contextSituations = {
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
  };

  Map<String, dynamic> scoreMapper = ScoreMapper.scoreMapper;
  String restaurantsName;
  String restaurantsId;
  String taskType;
  File _storedImage;
  bool takePic = false;
  bool urlLoad = true;
  String url = '';

  Future<void> getContextAndAdjust(
      {restaurantsId,
      contextArray,
      contextList,
      contextName,
      contextScore}) async {
    try {
      await Firebase.initializeApp();
      CollectionReference restaurants =
          FirebaseFirestore.instance.collection('restaurants');
      return restaurants.doc(restaurantsId).get().then((value) {
        List<dynamic> array = value.get(contextArray);
        if (array.length == 0) {
          restaurants.doc(restaurantsId).update({
            contextArray: FieldValue.arrayUnion(contextList),
            contextName: contextScore,
          });
        }
        restaurants.doc(restaurantsId).update({
          contextArray: FieldValue.arrayUnion(contextList),
        });
        if (contextName == 'crowdedness_dinein' ||
            contextName == 'crowdedness_takeout') {
          Map threeNumbers = {
            1: 0,
            0.5: 0,
            0.3: 0,
          };
          for (var m in array) {
            if (DateTime.now()
                    .difference(DateTime.parse(m['timestamp']))
                    .inHours >=
                2) {
              restaurants.doc(restaurantsId).update({
                contextArray: FieldValue.arrayRemove([m]),
              });
            } else {
              threeNumbers[m['score']] = threeNumbers[m['score']] + 1;
            }
          }
          var finalValue = 0;
          threeNumbers.forEach((key, value) {
            if (value > finalValue) {
              finalValue = value;
              contextScore = key;
            }
          });
          restaurants.doc(restaurantsId).update({
            contextName: contextScore,
          });
        } else if (contextName == 'safety') {
          Map threeNumbers = {
            1: 0,
            5: 0,
            10: 0,
          };
          for (var m in array) {
            if (DateTime.now()
                    .difference(DateTime.parse(m['timestamp']))
                    .inDays >=
                1) {
              restaurants.doc(restaurantsId).update({
                contextArray: FieldValue.arrayRemove([m]),
              });
            } else {
              threeNumbers[m['score']] = threeNumbers[m['score']] + 1;
            }
          }
          var finalValue = 0;
          threeNumbers.forEach((key, value) {
            if (value > finalValue) {
              finalValue = value;
              contextScore = key;
            }
          });
          restaurants.doc(restaurantsId).update({
            contextName: contextScore,
          });
        } else {
          Map twoNumbers = {
            1: 0,
            -1: 0,
          };
          for (var m in array) {
            if (DateTime.now()
                    .difference(DateTime.parse(m['timestamp']))
                    .inDays >=
                1) {
              restaurants.doc(restaurantsId).update({
                contextArray: FieldValue.arrayRemove([m]),
              });
            } else {
              twoNumbers[m['score']] = twoNumbers[m['score']] + 1;
            }
          }
          var finalValue = 0;
          twoNumbers.forEach((key, value) {
            if (value > finalValue) {
              finalValue = value;
              contextScore = key;
            }
          });
          restaurants.doc(restaurantsId).update({
            contextName: contextScore,
          });
        }
      });
    } catch (e, stacktrace) {
      print('Exception: ' + e.toString());
      print('Stacktrace: ' + stacktrace.toString());
    }
  }

  Future<void> addTask(Map contextMap, String owner, String restaurantsName) {
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks.add({
      'complete': 'false',
      'create_time': DateTime.now().toIso8601String(),
      'record': [],
      'solver': Provider.of<Auth>(context, listen: false).email,
      'owner': owner,
      'restaurants_name': restaurantsName,
      'contexts': contextMap,
      'task_type': 'solveAssigned',
      'url': url,
    });
  }

  Future<void> completeAssignedTask(
      {String owner, String timestamp, List logs}) async {
    await Firebase.initializeApp();
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks
        .where('requester', isEqualTo: owner)
        .where('create_time', isEqualTo: timestamp)
        .get()
        .then((value) {
      value.docs.forEach((element) {
        tasks.doc(element.id).update({
          'complete': 'true',
          'record': FieldValue.arrayUnion(logs),
        });
      });
    });
  }

  Future<void> takePicture() async {
    final picker = ImagePicker();
    final imageFile = await picker.getImage(
      source: ImageSource.camera,
      maxWidth: 600,
    );
    if (imageFile == null) {
      return;
    }
    setState(() {
      takePic = true;
      _storedImage = File(imageFile.path);
      urlLoad = false;
    });
  }

  Future<void> uploadPic() async {
    final fileName = path.basename(_storedImage.path);
    String email = Provider.of<Auth>(context, listen: false).email;
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyyMMddhhmmss');
    final String formatted = formatter.format(now);
    final String finalFileName = '$email$formatted$fileName';
    FirebaseStorage.instance
        .ref()
        .child('images')
        .child(finalFileName)
        .putFile(_storedImage)
        .then((taskSnapshot) {
      taskSnapshot.ref.getDownloadURL().then((value) {
        url = value;
        setState(() {
          urlLoad = true;
        });
        List<dynamic> picList = [
          {
            'url': value,
            'timestamp': DateFormat('yyyy-MM-dd hh:mm')
                .format(DateTime.now())
                .toString(),
          }
        ];
        CollectionReference restaurants =
            FirebaseFirestore.instance.collection('restaurants');
        restaurants
            .doc(restaurantsId)
            .update({'pics': FieldValue.arrayUnion(picList)});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    dynamic obj = ModalRoute.of(context).settings.arguments;
    restaurantsName = obj['restaurantsName'];
    restaurantsId = obj['restaurantsId'];
    taskType = obj['task_type'];

    return Scaffold(
      appBar: AppBar(
        title: Text('請勾選餐廳的狀態'),
      ),
      body: ListView(
        children: [
          SizedBox(height: 10),
          Center(
            child: Text(
              restaurantsName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              '可以勾選即時資訊',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.red,
                fontSize: 15,
              ),
            ),
          ),
          Center(
            child: Text(
              '或上傳照片(店面、菜單、疫情現況)',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.red,
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(height: 10),
          ListView.builder(
            physics: ScrollPhysics(),
            shrinkWrap: true,
            itemCount: contexts.length,
            itemBuilder: (context, index) {
              return Card(
                child: Container(
                  padding: new EdgeInsets.all(10.0),
                  child: ListTile(
                    title: Text(
                      contexts[index].title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: contexts[index].icon,
                    subtitle: ContextDropDown(
                      dropdownValue: contexts[index].dropdownValue,
                      itemList: contexts[index].contextSituations,
                      index: index,
                      context: contexts[index].context,
                      addList: (String ctx, String dropdownValue) {
                        contextSituations[ctx] =
                            scoreMapper[ctx][dropdownValue];
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ClipOval(
                child: Material(
                  color: Colors.blue, // Button color
                  child: InkWell(
                    splashColor: Colors.red, // Splash color
                    onTap: () async {
                      takePicture().whenComplete(() {
                        uploadPic().whenComplete(() {});
                      });
                    },
                    child: SizedBox(
                      width: 55,
                      height: 55,
                      child: Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 30,
              ),
              urlLoad
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(primary: Colors.blue),
                      child: Text('Go',
                          style: TextStyle(color: Colors.white, fontSize: 25)),
                      onPressed: () {
                        if (takePic) {
                          Provider.of<Auth>(context, listen: false)
                              .updateUserCount('count_picture');
                          List<dynamic> logs = [
                            {
                              'event': 'take_picture',
                              'timestamp': DateTime.now().toIso8601String(),
                            }
                          ];
                          Provider.of<Auth>(context, listen: false)
                              .updateUserLog(logs);
                        }
                        List contextKeys = [];
                        for (var k in contextSituations.keys) {
                          if (contextSituations[k] != 0) {
                            contextKeys.add(k);
                            List<dynamic> logs = [
                              {
                                'timestamp': DateTime.now().toIso8601String(),
                                'score': contextSituations[k],
                              }
                            ];
                            getContextAndAdjust(
                              restaurantsId: restaurantsId,
                              contextArray: k + '_log',
                              contextList: logs,
                              contextName: k,
                              contextScore: contextSituations[k],
                            );
                          }
                        }
                        if (taskType == 'proactive') {
                          Provider.of<Auth>(context, listen: false)
                              .updateUserCount('count_proactive')
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
                                              countType: 'count_proactive',
                                              selfCount: int.parse(
                                                  value['count_proactive']),
                                            ),
                                          ));
                                });
                              });
                            });
                          });
                          ;
                          List<dynamic> logs = [
                            {
                              'event': 'proactive',
                              'timestamp': DateTime.now().toIso8601String(),
                              'contexts': contextKeys,
                              'restaurants': restaurantsName,
                            }
                          ];
                          Provider.of<Auth>(context, listen: false)
                              .updateUserLog(logs);
                        }
                        if (taskType == 'assigned') {
                          addTask(
                              contextSituations, obj['owner'], restaurantsName);
                          List<dynamic> logs = [
                            {
                              'solver':
                                  Provider.of<Auth>(context, listen: false)
                                      .email,
                              'timestamp': DateTime.now().toIso8601String(),
                            }
                          ];
                          completeAssignedTask(
                            owner: obj['owner'],
                            timestamp: obj['timestamp'],
                            logs: logs,
                          );
                          Provider.of<Auth>(context, listen: false)
                              .updateUserCount('count_assigned')
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
                                              countType: 'count_assigned',
                                              selfCount: int.parse(
                                                  value['count_assigned']),
                                            ),
                                          ));
                                });
                              });
                            });
                          });
                          List<dynamic> userlogs = [
                            {
                              'event': 'assigned',
                              'timestamp': DateTime.now().toIso8601String(),
                              'contexts': contextKeys,
                              'restaurants': restaurantsName,
                            }
                          ];
                          Provider.of<Auth>(context, listen: false)
                              .updateUserLog(userlogs);
                        }
                      },
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(primary: Colors.grey),
                      child: Text('Go',
                          style: TextStyle(color: Colors.white, fontSize: 25)),
                      onPressed: () => {},
                    ),
            ],
          ),
          SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }
}

class ContextsListTileModel {
  final String title;
  final List<String> contextSituations;
  final String context;
  final Icon icon;
  final String dropdownValue;

  ContextsListTileModel({
    this.title,
    this.contextSituations,
    this.context,
    this.icon,
    this.dropdownValue,
  });

  static List<ContextsListTileModel> getContext() {
    return [
      ContextsListTileModel(
        title: '餐廳營業情況',
        icon: Icon(Icons.store),
        context: 'open',
        dropdownValue: '',
        contextSituations: [
          '營業中',
          '已關店',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳內人潮與座位情況',
        icon: Icon(Icons.airline_seat_recline_normal),
        context: 'crowdedness_dinein',
        dropdownValue: '',
        contextSituations: [
          '幾乎沒有客人',
          '有一些空位',
          '非常多人在餐廳內',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳內排隊情況',
        icon: Icon(Icons.group),
        context: 'crowdedness_takeout',
        dropdownValue: '',
        contextSituations: [
          '幾乎沒有客人',
          '有些人在排隊',
          '非常多人在排隊',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳內安全措施',
        icon: Icon(Icons.enhanced_encryption),
        context: 'safety',
        dropdownValue: '',
        contextSituations: [
          '實名制、簽名',
          '座位擺設安全距離',
          '座位間放置防疫隔板',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '疫情特殊餐點',
        icon: Icon(Icons.fastfood),
        context: 'covid_change',
        dropdownValue: '',
        contextSituations: [
          '沒有提供疫情特殊餐點',
          '有提供疫情特殊餐點',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳周圍停車情況',
        icon: Icon(Icons.time_to_leave),
        context: 'parking',
        dropdownValue: '',
        contextSituations: [
          '沒有停車位',
          '還有停車位',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳內WIFI情況',
        icon: Icon(Icons.wifi),
        context: 'wifi',
        dropdownValue: '',
        contextSituations: [
          '沒有WIFI',
          '有WIFI',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳內空調情況',
        icon: Icon(Icons.ac_unit),
        context: 'air_conditioning',
        dropdownValue: '',
        contextSituations: [
          '沒有冷氣',
          '有冷氣',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳內電視情況',
        icon: Icon(Icons.tv),
        context: 'tv',
        dropdownValue: '',
        contextSituations: [
          '沒有電視',
          '有電視',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳內音樂情況',
        icon: Icon(Icons.audiotrack),
        context: 'music',
        dropdownValue: '',
        contextSituations: [
          '沒有音樂',
          '有音樂',
          '',
        ],
      ),
      ContextsListTileModel(
        title: '餐廳優惠情況',
        icon: Icon(Icons.stars),
        context: 'promotion',
        dropdownValue: '',
        contextSituations: [
          '沒有特殊優惠',
          '有特殊優惠',
          '',
        ],
      ),
    ];
  }
}

class ContextDropDown extends StatefulWidget {
  String dropdownValue;
  final int index;
  final String context;
  final List<String> itemList;
  final Function(String, String) addList;

  ContextDropDown(
      {this.dropdownValue,
      this.itemList,
      this.index,
      this.addList,
      this.context});

  @override
  _ContextDropDownState createState() => _ContextDropDownState();
}

class _ContextDropDownState extends State<ContextDropDown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: this.widget.dropdownValue,
      items: this.widget.itemList.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.red,
            ),
          ),
        );
      }).toList(),
      onChanged: (String newValue) {
        setState(() {
          this.widget.dropdownValue = newValue;
          this.widget.addList(this.widget.context, this.widget.dropdownValue);
        });
      },
    );
  }
}

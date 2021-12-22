import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../providers/auth.dart';
import '../widgets/gamification_dialog.dart';

class TaskAddScreen extends StatefulWidget {
  static const routeName = '/task_add';

  @override
  _TaskAddScreenState createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  bool _validate = false;
  String cuisingFinalValue = '中式';
  String inoutFinalValue = '內用';
  String priceFinalValue = '150以下';

  Map<String, dynamic> cuisineType = {
    '俄羅斯式': 0,
    '午餐': 0,
    '台式': 0,
    '法式': 0,
    '義式': 0,
    '餐酒館/酒吧': 0,
    '咖啡': 0,
    '晚餐': 0,
    '小吃': 0,
    '中東式': 0,
    '東南亞': 0,
    '泰式': 0,
    '印式': 0,
    '飲料': 0,
    '墨式': 0,
    '夏威夷式': 0,
    '中式': 0,
    '德式': 0,
    '歐式': 0,
    '義式料理': 0,
    '韓式': 0,
    '日式': 0,
    '美式': 0,
    '日本': 0,
    '越式': 0,
    '港式': 0,
  };

  Map<String, dynamic> inoutType = {
    '外帶': 0,
    '內用': 0,
    '內用/外帶': 0,
  };

  Map<String, dynamic> priceType = {
    '150以下': 'm',
    '150-600': 'mm',
    '600-1200': 'mmm',
    '1200以上': 'mmmm',
  };

  Future<void> addrestaurants(Map resData) {
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    return restaurants.add({
      "id": resData['id'],
      "name": resData['name'],
      "address": resData['address'],
      "lng": resData['lng'],
      "lat": resData['lat'],
      "rating": resData['rating'],
      "price_segment": resData['price_segment'],
      "info": resData['info'],
      "cuisine_type": resData['cuisine_type'],
      "inout": resData['inout'],
      "checked": resData['checked'],
      "air_conditioning": resData['air_conditioning'],
      "air_conditioning_log": resData['air_conditioning_log'],
      "crowdedness_dinein": resData['crowdedness_dinein'],
      "crowdedness_dinein_log": resData['crowdedness_dinein_log'],
      "crowdedness_takeout": resData['crowdedness_takeout'],
      "crowdedness_takeout_log": resData['crowdedness_takeout_log'],
      "music": resData['music'],
      "music_log": resData['music_log'],
      "open": resData['open'],
      "open_log": resData['open_log'],
      "parking": resData['parking'],
      "parking_log": resData['parking_log'],
      "promotion": resData['promotion'],
      "promotion_log": resData['promotion_log'],
      "safety": resData['safety'],
      "safety_log": resData['safety_log'],
      "tv": resData['tv'],
      "tv_log": resData['tv_log'],
      "wifi": resData['wifi'],
      "wifi_log": resData['wifi_log'],
      // ignore: invalid_return_type_for_catch_error
    }).catchError((error) => print("Failed to add user: $error"));
  }

  Future<void> addTask(Map resData) {
    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
    return tasks.add({
      'complete': 'false',
      'create_time': DateTime.now().toIso8601String(),
      'record': [],
      'requester': Provider.of<Auth>(context, listen: false).email,
      'restaurants': json.encode(resData),
      'restaurantsId': resData['id'],
      'task_type': 'addMap',
    });
  }

  @override
  Widget build(BuildContext context) {
    dynamic obj = ModalRoute.of(context).settings.arguments;
    final location = obj['restaurantsLocation'];

    return Scaffold(
      appBar: AppBar(
        title: Text('新增餐廳!'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '餐廳名稱',
                      errorText: _validate ? '餐廳名稱不能為空' : null,
                    ),
                    controller: _titleController,
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('餐廳菜系'),
                      CuisineDropDown(
                        finalValue: (String choosenValue) {
                          cuisingFinalValue = choosenValue;
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('用餐選項'),
                      InoutDropdown(
                        finalValue: (String choosenValue) {
                          inoutFinalValue = choosenValue;
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('餐廳價格'),
                      PriceDropdown(
                        finalValue: (String choosenValue) {
                          priceFinalValue = choosenValue;
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  TextField(
                    maxLines: 8,
                    decoration: InputDecoration(labelText: '餐廳地址(選填)'),
                    controller: _detailController,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      style: TextButton.styleFrom(primary: Colors.blue),
                      child: Text(
                        'GO!',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () async {
                        setState(() {
                          _titleController.text.isEmpty
                              ? _validate = true
                              : _validate = false;
                        });
                        if (!_validate) {
                          await Firebase.initializeApp();
                          Provider.of<Auth>(context, listen: false)
                              .updateUserCount('count_add')
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
                                              countType: 'count_add',
                                              selfCount:
                                                  int.parse(value['count_add']),
                                            ),
                                          ));
                                });
                              });
                            });
                          });
                          List<dynamic> logs = [
                            {
                              'event': 'add_restaurants',
                              'timestamp': DateTime.now().toIso8601String(),
                              'restaurantsId': location.toString(),
                            }
                          ];
                          Provider.of<Auth>(context, listen: false)
                              .updateUserLog(logs);
                          Map resData = {};
                          cuisineType[cuisingFinalValue] = 1;
                          inoutType[inoutFinalValue] = 1;

                          resData['id'] = location.toString();
                          resData['name'] = _titleController.text;
                          resData['address'] = _detailController.text ?? '';
                          resData['lng'] = location.longitude.toString();
                          resData['lat'] = location.latitude.toString();
                          resData['rating'] = '';
                          resData['price_segment'] = priceType[priceFinalValue];
                          resData['info'] = '';
                          resData['cuisine_type'] = json.encode(cuisineType);
                          resData['inout'] = json.encode(inoutType);
                          resData['checked'] = '1';
                          resData['count_choosen'] = 0;
                          resData['count_explored'] = 0;
                          resData['air_conditioning'] = 0;
                          resData['air_conditioning_log'] = '';
                          resData['crowdedness_dinein'] = 0;
                          resData['crowdedness_dinein_log'] = '';
                          resData['crowdedness_takeout'] = 0;
                          resData['crowdedness_takeout_log'] = '';
                          resData['music'] = 0;
                          resData['music_log'] = '';
                          resData['open'] = 0;
                          resData['open_log'] = '';
                          resData['parking'] = 0;
                          resData['parking_log'] = '';
                          resData['promotion'] = 0;
                          resData['promotion_log'] = '';
                          resData['safety'] = 0;
                          resData['safety_log'] = '';
                          resData['tv'] = 0;
                          resData['tv_log'] = '';
                          resData['wifi'] = 0;
                          resData['wifi_log'] = '';
                          resData['pics'] = [];

                          addrestaurants(resData).then((value) {
                            addTask(resData);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ))
        ],
      ),
    );
  }
}

class CuisineDropDown extends StatefulWidget {
  final Function(String) finalValue;

  CuisineDropDown({this.finalValue});

  @override
  _CuisineDropDownState createState() => _CuisineDropDownState();
}

class _CuisineDropDownState extends State<CuisineDropDown> {
  String dropdownValue = '中式';

  String get choosenValue {
    return dropdownValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: dropdownValue,
      // items要改所有類別
      items: <String>[
        "俄羅斯式",
        "台式",
        "法式",
        "義式",
        "餐酒館/酒吧",
        "咖啡",
        "中東式",
        "東南亞",
        "泰式",
        "印式",
        "飲料",
        "墨式",
        "夏威夷式",
        "中式",
        "德式",
        "歐式",
        "韓式",
        "日式",
        "美式",
        "越式",
        "港式",
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String newValue) {
        setState(() {
          dropdownValue = newValue;
          this.widget.finalValue(dropdownValue);
        });
      },
    );
  }
}

class InoutDropdown extends StatefulWidget {
  final Function(String) finalValue;

  InoutDropdown({this.finalValue});

  @override
  _InoutDropdownState createState() => _InoutDropdownState();
}

class _InoutDropdownState extends State<InoutDropdown> {
  String dropdownValue = '內用';

  String get choosenValue {
    return dropdownValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: dropdownValue,
      items: <String>[
        '外帶',
        '內用',
        '內用/外帶',
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String newValue) {
        setState(() {
          dropdownValue = newValue;
          this.widget.finalValue(dropdownValue);
        });
      },
    );
  }
}

class PriceDropdown extends StatefulWidget {
  final Function(String) finalValue;

  PriceDropdown({this.finalValue});

  @override
  _PriceDropdownState createState() => _PriceDropdownState();
}

class _PriceDropdownState extends State<PriceDropdown> {
  String dropdownValue = '150以下';

  String get choosenValue {
    return dropdownValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: dropdownValue,
      items: <String>[
        '150以下',
        '150-600',
        '600-1200',
        '1200以上',
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String newValue) {
        setState(() {
          dropdownValue = newValue;
          this.widget.finalValue(dropdownValue);
        });
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import './recommendation_screen.dart';
import '../providers/auth.dart';

class RecommenderScreen extends StatefulWidget {
  static const routeName = '/recommender';

  @override
  _RecommenderScreenState createState() {
    return _RecommenderScreenState();
  }
}

class _RecommenderScreenState extends State<RecommenderScreen> {
  List<CheckBoxListTileModel> checkBoxListTileModel =
      CheckBoxListTileModel.getContext();

  // Arguments for next page
  List<String> contexts = [];
  List<String> attributes = ['無限制', '無限制'];
  List<String> crowdsPref = [];

  // Models for crowdedness checkbox
  CheckBoxListTileModel crowdednessModel = CheckBoxListTileModel(
    context: 'crowdedness_dinein',
    icon: Icon(Icons.airline_seat_recline_normal),
    title: "人潮與座位情況",
    isCheck: false,
  );
  CheckBoxListTileModel takeoutModel = CheckBoxListTileModel(
    context: 'crowdedness_takeout',
    icon: Icon(Icons.group),
    title: "排隊情況",
    isCheck: false,
  );
  CheckBoxListTileModel crowdednessLess = CheckBoxListTileModel(
    context: 'crowdedness_dinein_less',
    icon: Icon(Icons.person),
    title: "您偏好前往人少的餐廳",
    isCheck: true,
  );
  CheckBoxListTileModel crowdednessMore = CheckBoxListTileModel(
    context: 'crowdedness_dinein_more',
    icon: Icon(Icons.group),
    title: "您偏好前往人多的餐廳",
    isCheck: false,
  );
  CheckBoxListTileModel takeoutLess = CheckBoxListTileModel(
    context: 'crowdedness_takeout_less',
    icon: Icon(Icons.person),
    title: "您偏好前往不需要排隊的餐廳",
    isCheck: true,
  );
  CheckBoxListTileModel takeoutMore = CheckBoxListTileModel(
    context: 'crowdedness_takeout_more',
    icon: Icon(Icons.group),
    title: "您偏好前往有人在排隊的餐廳",
    isCheck: false,
  );

  // Control values
  bool showCrowdedness = false;
  bool showTakeout = false;
  String groupValueCrowdedness = '您偏好前往人少的餐廳';
  String groupValueTakeout = '您偏好前往不需要排隊的餐廳';
  String finalValueCrowdedness = 'crowdedness_dinein_less';
  String finalValueTakeout = 'crowdedness_takeout_less';
  bool isLoading = false;
  bool isReady = false;

  Future<void> warmDatabase() async {
    await Firebase.initializeApp();
    CollectionReference forLoading =
        FirebaseFirestore.instance.collection('forLoading');
    return forLoading.get();
  }

  @override
  Widget build(BuildContext context) {
    return (!isReady && !isLoading)
        ? Center(
            child: ClipOval(
              child: Material(
                color: Colors.red, // Button color
                child: InkWell(
                  splashColor: Colors.red, // Splash color
                  onTap: () {
                    setState(() {
                      isLoading = true;
                    });
                    warmDatabase().then((value) {
                      List<dynamic> logs = [
                        {
                          'event': 'press_to_start_recommend',
                          'timestamp': DateTime.now().toIso8601String(),
                        }
                      ];
                      Provider.of<Auth>(context, listen: false)
                          .updateUserLog(logs);
                      setState(() {
                        isReady = true;
                        isLoading = false;
                      });
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(20),
                    width: 120,
                    height: 120,
                    child: Center(
                      child: Text(
                        '點擊以開始推薦',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : (isLoading && !isReady)
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                children: [
                  Container(
                    height: 40,
                    color: Colors.deepOrange,
                    child: Center(
                      child: Text(
                        '請勾選您選擇餐廳時會參考的因素',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            activeColor: Colors.pink[300],
                            dense: true,
                            title: Text(crowdednessModel.title),
                            value: crowdednessModel.isCheck,
                            secondary: crowdednessModel.icon,
                            onChanged: (val) {
                              setState(() {
                                crowdednessModel.isCheck = val;
                                if (crowdednessModel.isCheck == true) {
                                  contexts.add(crowdednessModel.context);
                                  showCrowdedness = true;
                                } else {
                                  if (contexts
                                      .contains(crowdednessModel.context)) {
                                    contexts.remove(crowdednessModel.context);
                                    showCrowdedness = false;
                                  }
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  showCrowdedness
                      ? Card(
                          child: Container(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                RadioListTile(
                                  activeColor: Colors.pink[300],
                                  groupValue: groupValueCrowdedness,
                                  dense: true,
                                  title: Text(crowdednessLess.title),
                                  value: crowdednessLess.title,
                                  secondary: crowdednessLess.icon,
                                  onChanged: (value) => setState(() {
                                    groupValueCrowdedness = value;
                                    finalValueCrowdedness =
                                        crowdednessLess.context;
                                  }),
                                ),
                                RadioListTile(
                                  activeColor: Colors.pink[300],
                                  groupValue: groupValueCrowdedness,
                                  dense: true,
                                  title: Text(crowdednessMore.title),
                                  value: crowdednessMore.title,
                                  secondary: crowdednessMore.icon,
                                  onChanged: (value) => setState(() {
                                    groupValueCrowdedness = value;
                                    finalValueCrowdedness =
                                        crowdednessMore.context;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(),
                  Card(
                    child: Container(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            activeColor: Colors.pink[300],
                            dense: true,
                            title: Text(takeoutModel.title),
                            value: takeoutModel.isCheck,
                            secondary: takeoutModel.icon,
                            onChanged: (val) {
                              setState(() {
                                takeoutModel.isCheck = val;
                                if (takeoutModel.isCheck == true) {
                                  contexts.add(takeoutModel.context);
                                  showTakeout = true;
                                } else {
                                  if (contexts.contains(takeoutModel.context)) {
                                    contexts.remove(takeoutModel.context);
                                    showTakeout = false;
                                  }
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  showTakeout
                      ? Card(
                          child: Container(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                RadioListTile(
                                  activeColor: Colors.pink[300],
                                  groupValue: groupValueTakeout,
                                  dense: true,
                                  title: Text(takeoutLess.title),
                                  value: takeoutLess.title,
                                  secondary: takeoutLess.icon,
                                  onChanged: (value) => setState(() {
                                    groupValueTakeout = value;
                                    finalValueTakeout = takeoutLess.context;
                                  }),
                                ),
                                RadioListTile(
                                  activeColor: Colors.pink[300],
                                  groupValue: groupValueTakeout,
                                  dense: true,
                                  title: Text(takeoutMore.title),
                                  value: takeoutMore.title,
                                  secondary: takeoutMore.icon,
                                  onChanged: (value) => setState(() {
                                    groupValueTakeout = value;
                                    finalValueTakeout = takeoutMore.context;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(),
                  ListView.builder(
                    physics: ScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: checkBoxListTileModel.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Container(
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                activeColor: Colors.pink[300],
                                dense: true,
                                title: Text(checkBoxListTileModel[index].title),
                                value: checkBoxListTileModel[index].isCheck,
                                secondary: checkBoxListTileModel[index].icon,
                                onChanged: (bool val) {
                                  itemChange(val, index);
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                    ),
                    child: Center(
                      child: Text(
                        '請勾選您選擇餐廳時會參考的因素',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('餐廳距離'),
                        ContextDropDown(
                          index: 0,
                          dropdownValue: '無限制',
                          addList: (int index, String dropdownValue) {
                            attributes[index] = dropdownValue;
                          },
                          itemList: [
                            '500m內',
                            '1000m內',
                            '無限制',
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('餐廳價格'),
                        ContextDropDown(
                          index: 1,
                          dropdownValue: '無限制',
                          addList: (int index, String dropdownValue) {
                            attributes[index] = dropdownValue;
                          },
                          itemList: [
                            '150以下',
                            '150-600',
                            '600-1200',
                            '1200以上',
                            '無限制',
                          ],
                        ),
                      ],
                    ),
                  ]),
                  SizedBox(
                    height: 30,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      style: TextButton.styleFrom(primary: Colors.blue),
                      child: Text('Go', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        if (contexts.contains('crowdedness_dinein')) {
                          crowdsPref.add(finalValueCrowdedness);
                        }
                        if (contexts.contains('crowdedness_takeout')) {
                          crowdsPref.add(finalValueTakeout);
                        }
                        print('attributes包含$attributes');
                        print('contexts包含$contexts');
                        print('crowdsPref包含$crowdsPref');
                        List<dynamic> logs = [
                          {
                            'event': 'create_recommendation',
                            'timestamp': DateTime.now().toIso8601String(),
                            'attributes': attributes,
                            'contexts': contexts,
                            'crowdPref': crowdsPref
                          },
                        ];
                        Provider.of<Auth>(context, listen: false)
                            .updateUserLog(logs);
                        Provider.of<Auth>(context, listen: false)
                            .updateUserCount('count_recommend');
                        Navigator.of(context).pushNamed(
                          RecommendationScreen.routeName,
                          arguments: {
                            'attributes': attributes,
                            'contexts': contexts,
                            'crowdPref': crowdsPref
                          },
                        ).then((value) => setState(() {
                              checkBoxListTileModel =
                                  CheckBoxListTileModel.getContext();
                              contexts = [];
                              attributes = ['無限制', '無限制'];
                              crowdsPref = [];
                              groupValueCrowdedness = '您偏好前往人少的餐廳';
                              groupValueTakeout = '您偏好前往不需要排隊的餐廳';
                              showCrowdedness = false;
                              showTakeout = false;
                              crowdednessModel.isCheck = false;
                              takeoutModel.isCheck = false;
                              crowdednessLess.isCheck = true;
                              crowdednessMore.isCheck = false;
                              takeoutLess.isCheck = true;
                              takeoutMore.isCheck = false;
                            }));
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  )
                ],
              );
  }

  void itemChange(bool val, int index) {
    // 勾選同時將item加入contexts
    setState(() {
      checkBoxListTileModel[index].isCheck = val;
      if (checkBoxListTileModel[index].isCheck == true) {
        contexts.add(checkBoxListTileModel[index].context);
      } else {
        if (contexts.contains(checkBoxListTileModel[index].context)) {
          contexts.remove(checkBoxListTileModel[index].context);
        }
      }
    });
  }
}

class ContextDropDown extends StatefulWidget {
  String dropdownValue;
  final int index;
  final List<String> itemList;
  final Function(int, String) addList;

  ContextDropDown(
      {this.dropdownValue, this.itemList, this.index, this.addList});

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
          child: Text(value),
        );
      }).toList(),
      onChanged: (String newValue) {
        setState(() {
          this.widget.dropdownValue = newValue;
          this.widget.addList(this.widget.index, this.widget.dropdownValue);
        });
      },
    );
  }
}

class CheckBoxListTileModel {
  String context;
  Icon icon;
  String title;
  bool isCheck;

  CheckBoxListTileModel({this.context, this.icon, this.title, this.isCheck});

  void defaultValue(List<CheckBoxListTileModel> list) {
    for (var i = 0; i < list.length; i++) {
      list[i].isCheck = false;
    }
  }

  static List<CheckBoxListTileModel> getContext() {
    return <CheckBoxListTileModel>[
      /* CheckBoxListTileModel(
        context: 'crowdedness_dinein',
        icon: Icon(Icons.airline_seat_recline_normal),
        title: "餐廳內人潮與座位情況",
        isCheck: false,
      ),
      CheckBoxListTileModel(
        context: 'crowdedness_takeout',
        icon: Icon(Icons.group),
        title: "餐廳內排隊情況",
        isCheck: false,
      ),*/
      CheckBoxListTileModel(
        context: 'safety',
        icon: Icon(Icons.enhanced_encryption),
        title: "疫情安全措施",
        isCheck: false,
      ),
      CheckBoxListTileModel(
        context: 'covid_change',
        icon: Icon(Icons.fastfood),
        title: "疫情特殊餐點",
        isCheck: false,
      ),
      CheckBoxListTileModel(
        context: 'parking',
        icon: Icon(Icons.time_to_leave),
        title: "停車情況",
        isCheck: false,
      ),
      CheckBoxListTileModel(
        context: 'wifi',
        icon: Icon(Icons.wifi),
        title: "WIFI",
        isCheck: false,
      ),
      CheckBoxListTileModel(
        context: 'air_conditioning',
        icon: Icon(Icons.ac_unit),
        title: "空調",
        isCheck: false,
      ),
      CheckBoxListTileModel(
        context: 'tv',
        icon: Icon(Icons.tv),
        title: "有無電視",
        isCheck: false,
      ),
      CheckBoxListTileModel(
        context: 'music',
        icon: Icon(Icons.audiotrack),
        title: "有無音樂",
        isCheck: false,
      ),
      CheckBoxListTileModel(
        context: 'promotion',
        icon: Icon(Icons.stars),
        title: "有無特殊優惠",
        isCheck: false,
      ),
    ];
  }
}

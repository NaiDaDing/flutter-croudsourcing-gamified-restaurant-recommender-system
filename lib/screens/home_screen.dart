import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'profile_screen.dart';
import 'recommender_screen.dart';
import 'task_screen.dart';
import '../providers/auth.dart';
import '../widgets/app_drawer.dart';
import 'test_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Tab> gamiTabs = <Tab>[
    Tab(text: '任務頁面'),
    Tab(text: '餐廳推薦'),
    Tab(text: '個人資料'),
    // Tab(text: 'test!'),
  ];

  final List<Tab> normalTabs = <Tab>[
    Tab(text: '任務頁面'),
    Tab(text: '餐廳推薦'),
    // Tab(text: 'test!'),
  ];

  final List<Tab> adminTabs = <Tab>[
    Tab(text: '任務頁面'),
    Tab(text: '餐廳推薦'),
    Tab(text: '個人資料'),
    Tab(text: '測試!'),
  ];

  final gamiPages = <Widget>[
    TaskScreen(),
    RecommenderScreen(),
    ProfileScreen(),
    // TestScreen(),
  ];

  final normalPages = <Widget>[
    TaskScreen(),
    RecommenderScreen(),
    // TestScreen(),
  ];

  final adminPages = <Widget>[
    TaskScreen(),
    RecommenderScreen(),
    ProfileScreen(),
    TestScreen(),
  ];

  Future<void> warmDatabase() async {
    await Firebase.initializeApp();
    CollectionReference forLoading =
        FirebaseFirestore.instance.collection('forLoading');
    return forLoading.get();
  }

  initState() {
    super.initState();
    warmDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final condition = Provider.of<Auth>(context, listen: false).condition;
    final email = Provider.of<Auth>(context, listen: false).email;
    return DefaultTabController(
      length: condition == 'control'
          ? normalTabs.length
          : email != 'qq122618071@gmail.com'
              ? gamiTabs.length
              : adminTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Welcome!"),
          bottom: TabBar(
            tabs: condition == 'control'
                ? normalTabs
                : email != 'qq122618071@gmail.com'
                    ? gamiTabs
                    : adminTabs,
          ),
        ),
        drawer: AppDrawer(),
        body: TabBarView(
          children: condition == 'control'
              ? normalPages
              : email != 'qq122618071@gmail.com'
                  ? gamiPages
                  : adminPages,
        ),
      ),
    );
  }
}

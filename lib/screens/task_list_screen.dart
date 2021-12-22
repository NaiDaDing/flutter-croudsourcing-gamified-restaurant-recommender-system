import 'package:flutter/material.dart';

import './task_assigned_self_screen.dart';
import './task_assigned_assigned_screen.dart';
import './task_assigned_add_screen.dart';

class TaskListScreen extends StatefulWidget {
  static const routeName = '/task_list';

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, Object>> _pages = [
    {
      'page': TaskAssignedSelfScreen(),
      'title': '個人任務清單',
    },
    {
      'page': TaskAssignedAssignedScreen(),
      'title': '委託任務清單',
    },
    {
      'page': TaskAssignedAddScreen(),
      'title': '新餐廳確認頁面',
    },
  ];

  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  final List<Tab> myTabs = <Tab>[
    Tab(text: '個人任務清單'),
    Tab(text: '委託任務清單'),
    Tab(text: '新餐廳確認頁面'),
  ];

  final pages = <Widget>[
    TaskAssignedAssignedScreen(),
    TaskAssignedAddScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedPageIndex]['title']),
      ),
      body: _pages[_selectedPageIndex]['page'],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.black,
        currentIndex: _selectedPageIndex,
        items: [
          BottomNavigationBarItem(
            backgroundColor: Colors.black,
            icon: Icon(Icons.person),
            title: Text('個人訊息與任務'),
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.black,
            icon: Icon(Icons.category),
            title: Text('委託任務清單'),
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.black,
            icon: Icon(Icons.map),
            title: Text('新餐廳確認頁面'),
          ),
        ],
      ),
    );
  }
}

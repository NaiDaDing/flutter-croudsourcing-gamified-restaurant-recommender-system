import 'package:flutter/material.dart';

import './task_add_map_screen.dart';
import './task_list_screen.dart';
import './task_assigned_map_screen.dart';
import './task_proactive_map_screen.dart';

class TaskScreen extends StatelessWidget {
  static const routeName = '/task';

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.only(top: 50),
        children: <Widget>[
          // Four flatbuttons with icons
          Container(
            padding: EdgeInsets.all(15),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(TaskProactiveMapScreen.routeName);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0))),
              ),
              // padding: EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.engineering,
                    size: 30,
                    color: Colors.white,
                  ),
                  Text(
                    "蒐集即時餐廳資訊",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(15),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(TaskAssignedMapScreen.routeName);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.pink),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0))),
              ),
              // padding: EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.work,
                    size: 30,
                    color: Colors.white,
                  ),
                  Text(
                    "您想知道",
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    "哪間餐廳的資訊",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(15),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(TaskListScreen.routeName);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.amber),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0))),
              ),
              // padding: EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.list,
                    size: 30,
                    color: Colors.white,
                  ),
                  Text(
                    "任務清單",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(15),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(TaskAddMapScreen.routeName);
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.purple),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0))),
              ),
              // padding: EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.add,
                    size: 30,
                    color: Colors.white,
                  ),
                  Text(
                    "添加餐廳",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

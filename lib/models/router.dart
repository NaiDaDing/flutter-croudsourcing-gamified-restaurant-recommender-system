import 'package:flutter/material.dart';

import '../screens/auth_screen.dart';
import '../screens/check_add_map_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recommender_screen.dart';
import '../screens/task_screen.dart';
import '../screens/task_add_screen.dart';
import '../screens/task_add_map_screen.dart';
import '../screens/task_assigned_map_screen.dart';
import '../screens/task_assigned_add_screen.dart';
import '../screens/task_assigned_assigned_screen.dart';
import '../screens/task_list_screen.dart';
import '../screens/task_proactive_screen.dart';
import '../screens/task_proactive_map_screen.dart';
import '../screens/photo_screen.dart';

Map<String, WidgetBuilder> routes = {
  AuthScreen.routeName: (ctx) => AuthScreen(),
  CheckAddMapScreen.routeName: (ctx) => CheckAddMapScreen(),
  ProfileScreen.routeName: (ctx) => ProfileScreen(),
  RecommenderScreen.routeName: (ctx) => RecommenderScreen(),
  TaskScreen.routeName: (ctx) => TaskScreen(),
  TaskAddScreen.routeName: (ctx) => TaskAddScreen(),
  TaskAddMapScreen.routeName: (ctx) => TaskAddMapScreen(),
  TaskAssignedMapScreen.routeName: (ctx) => TaskAssignedMapScreen(),
  TaskAssignedAddScreen.routeName: (ctx) => TaskAssignedAddScreen(),
  TaskAssignedAssignedScreen.routeName: (ctx) => TaskAssignedAssignedScreen(),
  TaskListScreen.routeName: (ctx) => TaskListScreen(),
  TaskProactiveScreen.routeName: (ctx) => TaskProactiveScreen(),
  TaskProactiveMapScreen.routeName: (ctx) => TaskProactiveMapScreen(),
};

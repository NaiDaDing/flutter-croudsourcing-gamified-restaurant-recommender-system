import 'package:flutter/material.dart';

import '../main.dart' show restartHelper;

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: Text('Hello Friend!'),
            automaticallyImplyLeading: false,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('登出'),
            onTap: () {
              restartHelper.restartApp(context);
            },
          ),
        ],
      ),
    );
  }
}

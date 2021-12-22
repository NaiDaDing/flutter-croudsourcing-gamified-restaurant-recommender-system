import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../screens/home_screen.dart';
import '../models/router.dart' as router;
import '../providers/auth.dart';
import '../screens/auth_screen.dart';
import '../screens/recommendation_screen.dart';

void main() {
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => Auth()),
      ],
      child: Consumer<Auth>(
        builder: (ctx, auth, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: auth.isAuth
              ? HomeScreen()
              : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (ctx, authResultSnapshot) =>
                      authResultSnapshot.connectionState ==
                              ConnectionState.waiting
                          ? Container(
                              color: Colors.black,
                              child: Center(
                                child: Text(
                                  'Login....',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : AuthScreen()),
          routes: router.routes,
          onUnknownRoute: (RouteSettings settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) =>
                  Scaffold(body: Center(child: Text('Not Found'))),
            );
          },
          onGenerateRoute: (RouteSettings settings) {
            var recommendationRoute = <String, WidgetBuilder>{
              RecommendationScreen.routeName: (ctx) => RecommendationScreen(
                    obj: settings.arguments,
                  ),
            };
            WidgetBuilder builder = recommendationRoute[settings.name];
            return MaterialPageRoute(builder: (ctx) => builder(ctx));
          },
        ),
      ),
    );
  }
}

class restartHelper {
  static void restartApp(BuildContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    showDialog(
        context: ctx,
        builder: (ctx) => AlertDialog(
              title: Text('提示'),
              content: Text('確定要登出?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    prefs.clear().then((value) {
                      Navigator.of(ctx).pop();
                      Provider.of<Auth>(ctx, listen: false).logout();
                    });
                  },
                  child: Text('確定'),
                ),
              ],
            ));
  }
}

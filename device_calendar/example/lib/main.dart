import 'package:flutter/material.dart';

import 'common/app_routes.dart';
import 'presentation/pages/calendars.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(routes: {
      AppRoutes.calendars: (context) {
        return new CalendarsPage();
      }
    });
  }
}

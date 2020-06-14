import 'package:flutter/material.dart';

import 'common/app_routes.dart';
import 'presentation/pages/calendars.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        AppRoutes.calendars: (context) {
          return CalendarsPage(key: Key('calendarsPage'));
        }
      },
    );
  }
}

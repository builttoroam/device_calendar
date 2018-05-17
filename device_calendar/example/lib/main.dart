import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:device_calendar/models/calendar.dart';
import 'package:device_calendar/services/calendars.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  List<Calendar> _calendars = new List<Calendar>();
  CalendarsService _calendarsService = new CalendarsService();

  @override
  initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    String platformVersion;
    List<Calendar> calendars;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await DeviceCalendar.platformVersion;
      calendars = await _calendarsService.retrieveCalendars();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _calendars = calendars;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Plugin example app'),
          ),
          body: new Column(
            children: <Widget>[
              new Center(
                child: new Text('Running on: $_platformVersion\n'),
              ),
              new Expanded(
                flex: 1,
                child: new ListView.builder(
                  itemCount: _calendars.length,
                  itemBuilder: (BuildContext context, int index) {
                    return new Text(_calendars[index].name);
                  },
                ),
              )
            ],
          )),
    );
  }
}

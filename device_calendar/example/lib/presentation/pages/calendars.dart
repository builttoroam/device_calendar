import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'calendar_events.dart';

class CalendarsPage extends StatefulWidget {
  @override
  _CalendarsPageState createState() {
    return new _CalendarsPageState();
  }
}

class _CalendarsPageState extends State<CalendarsPage> {
  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Calendar> _calendars;

  _CalendarsPageState() {
    _deviceCalendarPlugin = new DeviceCalendarPlugin();
  }

  @override
  initState() {
    super.initState();
    _retrieveCalendars();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Calendars'),
      ),
      body: new Column(
        children: <Widget>[
          new Expanded(
            flex: 1,
            child: new ListView.builder(
              itemCount: _calendars?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                return new GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, new MaterialPageRoute(
                          builder: (BuildContext context) {
                        return new CalendarEventsPage(_calendars[index]);
                      }));
                    },
                    child: new Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: new Row(
                          children: <Widget>[
                            new Expanded(
                              flex: 1,
                              child: new Text(
                                _calendars[index].name,
                                style: new TextStyle(fontSize: 25.0),
                              ),
                            ),
                            new Icon(_calendars[index].isReadOnly
                                ? Icons.lock
                                : Icons.lock_open)
                          ],
                        )));
              },
            ),
          )
        ],
      ),
    );
  }

  void _retrieveCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      setState(() {
        _calendars = calendarsResult?.data;
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }
}

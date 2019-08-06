import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'calendar_events.dart';

class CalendarsPage extends StatefulWidget {
  @override
  _CalendarsPageState createState() {
    return _CalendarsPageState();
  }
}

class _CalendarsPageState extends State<CalendarsPage> {
  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Calendar> _calendars;

  _CalendarsPageState() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  @override
  initState() {
    super.initState();
    _retrieveCalendars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendars'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _calendars?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (BuildContext context) {
                        return CalendarEventsPage(_calendars[index]);
                      }));
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Text(
                                _calendars[index].name,
                                style: TextStyle(fontSize: 25.0),
                              ),
                            ),
                            Icon(_calendars[index].isReadOnly
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

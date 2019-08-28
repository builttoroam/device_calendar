import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'calendar_events.dart';

class CalendarsPage extends StatefulWidget {
  CalendarsPage({Key key}) : super(key: key);

  @override
  _CalendarsPageState createState() {
    return _CalendarsPageState();
  }
}

class _CalendarsPageState extends State<CalendarsPage> {
  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Calendar> _calendars;
  List<Calendar> get _writableCalendars =>
      _calendars?.where((c) => !c.isReadOnly)?.toList() ?? List<Calendar>();

  List<Calendar> get _readOnlyCalendars =>
      _calendars?.where((c) => c.isReadOnly)?.toList() ?? List<Calendar>();

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
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'WARNING: some aspects of saving events are hardcoded in this example app. As such we recommend you do not modify existing events as this may result in loss of information',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _calendars?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                    key: Key(_calendars[index].isReadOnly
                        ? 'readOnlyCalendar${_readOnlyCalendars.indexWhere((c) => c.id == _calendars[index].id)}'
                        : 'writableCalendar${_writableCalendars.indexWhere((c) => c.id == _calendars[index].id)}'),
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (BuildContext context) {
                        return CalendarEventsPage(_calendars[index],
                            key: Key('calendarEventsPage'));
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
                                style: Theme.of(context).textTheme.subhead,
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

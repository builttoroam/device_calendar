import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

class CalendarEventsPage extends StatefulWidget {
  final Calendar _calendar;

  CalendarEventsPage(this._calendar);

  @override
  _CalendarEventsPageState createState() {
    return new _CalendarEventsPageState(_calendar);
  }
}

class _CalendarEventsPageState extends State<CalendarEventsPage> {
  final Calendar _calendar;

  List<String> _calendarEvents;

  _CalendarEventsPageState(this._calendar);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: new Text('${_calendar.name} events')),
        body: new Column(
          children: <Widget>[
            new Expanded(
                flex: 1,
                child: new ListView.builder(
                  itemCount: _calendarEvents?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    return new Text(_calendarEvents[index]);
                  },
                ))
          ],
        ));
  }
}

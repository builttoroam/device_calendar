import 'dart:async';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import '../event_item.dart';
import 'calendar_event.dart';

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
  BuildContext _scaffoldContext;

  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Event> _calendarEvents;
  bool _isLoading = true;

  _CalendarEventsPageState(this._calendar) {
    _deviceCalendarPlugin = new DeviceCalendarPlugin();
  }

  @override
  initState() {
    super.initState();
    _retrieveCalendarEvents();
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyEvents = _calendarEvents?.isNotEmpty ?? false;
    Widget body = hasAnyEvents
        ? new Stack(
            children: <Widget>[
              new Column(
                children: <Widget>[
                  new Expanded(
                    flex: 1,
                    child: new ListView.builder(
                      itemCount: _calendarEvents?.length ?? 0,
                      itemBuilder: (BuildContext context, int index) {
                        return new EventItem(
                            _calendarEvents[index],
                            _deviceCalendarPlugin,
                            _onLoading,
                            _onDeletedFinished,
                            _onTapped);
                      },
                    ),
                  )
                ],
              ),
              new Offstage(
                  offstage: !_isLoading,
                  child: new Container(
                      decoration: new BoxDecoration(
                          color: new Color.fromARGB(155, 192, 192, 192)),
                      child:
                          new Center(child: new CircularProgressIndicator())))
            ],
          )
        : new Center(child: new Text('No events found'));
    return new Scaffold(
      appBar: new AppBar(title: new Text('${_calendar.name} events')),
      body: new Builder(builder: (BuildContext context) {
        _scaffoldContext = context;
        return body;
      }),
      floatingActionButton: new FloatingActionButton(
        onPressed: () async {
          final refreshEvents = await Navigator.push(context,
              new MaterialPageRoute(builder: (BuildContext context) {
            return new CalendarEventPage(_calendar);
          }));
          if (refreshEvents) {
            _retrieveCalendarEvents();
          }
        },
        child: new Icon(Icons.add),
      ),
    );
  }

  void _onLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  Future _onDeletedFinished(bool deleteSucceeded) async {
    if (deleteSucceeded) {
      await _retrieveCalendarEvents();
    } else {
      Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(
            content: new Text('Oops, we ran into an issue deleting the event'),
            backgroundColor: Colors.red,
            duration: new Duration(seconds: 5),
          ));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future _onTapped(Event event) async {
    final refreshEvents = await Navigator.push(context,
        new MaterialPageRoute(builder: (BuildContext context) {
      return new CalendarEventPage(_calendar, event);
    }));
    if (refreshEvents != null && refreshEvents) {
      _retrieveCalendarEvents();
    }
  }

  Future _retrieveCalendarEvents() async {
    final startDate = new DateTime.now().add(new Duration(days: -30));
    final endDate = new DateTime.now().add(new Duration(days: 30));
    var calendarEventsResult = await _deviceCalendarPlugin.retrieveEvents(
        _calendar.id,
        new RetrieveEventsParams(startDate: startDate, endDate: endDate));
    setState(() {
      _calendarEvents = calendarEventsResult?.data;
      _isLoading = false;
    });
  }
}

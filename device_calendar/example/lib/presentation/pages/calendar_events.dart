import 'dart:async';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import '../event_item.dart';

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
    return new Scaffold(
      appBar: new AppBar(title: new Text('${_calendar.name} events')),
      body: hasAnyEvents
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
                                _calendar,
                                _calendarEvents[index],
                                _deviceCalendarPlugin, () {
                              setState(() {
                                _isLoading = true;
                              });
                            }, (deleteSuceedeed) async {
                              if (deleteSuceedeed) {
                                await _retrieveCalendarEvents();
                              } else {
                                Scaffold.of(context).showSnackBar(new SnackBar(
                                      content: new Text(
                                          'Oops, we ran into an issue deleting the event'),
                                      backgroundColor: Colors.red,
                                      duration: new Duration(seconds: 5),
                                    ));
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            });
                          },
                        ))
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
          : new Center(child: new Text('No events found')),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {},
        child: new Icon(Icons.add),
      ),
    );
  }

  Future _retrieveCalendarEvents() async {
    var calendarEvents = await _deviceCalendarPlugin.retrieveEvents(_calendar);
    setState(() {
      _calendarEvents = calendarEvents;
      _isLoading = false;
    });
  }
}

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

  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Event> _calendarEvents;

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
          ? new Column(
              children: <Widget>[
                new Expanded(
                    flex: 1,
                    child: new ListView.builder(
                      itemCount: _calendarEvents?.length ?? 0,
                      itemBuilder: (BuildContext context, int index) {
                        return new Card(
                          child: new Column(
                            children: <Widget>[
                              new Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: new FlutterLogo(),
                              ),
                              new ListTile(
                                title: new Text(_calendarEvents[index].title),
                              ),
                              new ButtonTheme.bar(
                                  child: new ButtonBar(
                                children: <Widget>[
                                  new IconButton(
                                    onPressed: () {},
                                    icon: new Icon(Icons.edit),
                                  ),
                                  new IconButton(
                                    onPressed: () {},
                                    icon: new Icon(Icons.delete),
                                  ),
                                ],
                              ))
                            ],
                          ),
                        );
                      },
                    ))
              ],
            )
          : new Center(child: new Text('No events found')),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {},
        child: new Icon(Icons.add),
      ),
    );
  }

  void _retrieveCalendarEvents() async {
    var calendarEvents = await _deviceCalendarPlugin.retrieveEvents(_calendar);
    setState(() {
      _calendarEvents = calendarEvents;
    });
  }
}

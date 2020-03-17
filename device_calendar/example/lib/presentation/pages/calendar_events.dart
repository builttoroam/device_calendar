import 'dart:async';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import '../event_item.dart';
import '../recurring_event_dialog.dart';
import 'calendar_event.dart';

class CalendarEventsPage extends StatefulWidget {
  final Calendar _calendar;

  CalendarEventsPage(this._calendar, {Key key}) : super(key: key);

  @override
  _CalendarEventsPageState createState() {
    return _CalendarEventsPageState(_calendar);
  }
}

class _CalendarEventsPageState extends State<CalendarEventsPage> {
  final Calendar _calendar;
  final GlobalKey<ScaffoldState> _scaffoldstate = GlobalKey<ScaffoldState>();

  DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Event> _calendarEvents;
  bool _isLoading = true;

  _CalendarEventsPageState(this._calendar) {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  @override
  initState() {
    super.initState();
    _retrieveCalendarEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldstate,
      appBar: AppBar(title: Text('${_calendar.name} events')),
      body: (_calendarEvents?.isNotEmpty ?? false)
          ? Stack(
              children: [
                ListView.builder(
                  itemCount: _calendarEvents?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    return EventItem(
                        _calendarEvents[index],
                        _deviceCalendarPlugin,
                        _onLoading,
                        _onDeletedFinished,
                        _onTapped,
                        _calendar.isReadOnly);
                  },
                ),
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(),
                  )
              ],
            )
          : Center(child: Text('No events found')),
      floatingActionButton: _getAddEventButton(context)
    );
  }

  Widget _getAddEventButton(BuildContext context) {
    if (!_calendar.isReadOnly) {
      return FloatingActionButton(
        key: Key('addEventButton'),
        onPressed: () async {
          final refreshEvents = await Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return CalendarEventPage(_calendar);
          }));
          if (refreshEvents == true) {
            await _retrieveCalendarEvents();
          }
        },
        child: Icon(Icons.add),
      );
    }
    else {
      return null;
    }
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
        _scaffoldstate.currentState.showSnackBar(SnackBar(
        content: Text('Oops, we ran into an issue deleting the event'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future _onTapped(Event event) async {
    final refreshEvents = await Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return CalendarEventPage(_calendar, event: event,
        deleteRecurringEventDialog: RecurringEventDialog(
          _deviceCalendarPlugin,
          event,
          true,
          _onLoading,
          _onDeletedFinished,
        ),
        editRecurringEventDialog: RecurringEventDialog(
          _deviceCalendarPlugin,
          event,
          false,
          _onLoading,
          _onDeletedFinished,
        ),
      );
    }));
    if (refreshEvents != null && refreshEvents) {
      await _retrieveCalendarEvents();
    }
  }

  Future _retrieveCalendarEvents() async {
    final startDate = DateTime.now().add(Duration(days: -30));
    final endDate = DateTime.now().add(Duration(days: 30));
    var calendarEventsResult = await _deviceCalendarPlugin.retrieveEvents(
        _calendar.id,
        RetrieveEventsParams(startDate: startDate, endDate: endDate));
    setState(() {
      _calendarEvents = calendarEventsResult?.data;
      _isLoading = false;
    });
  }
}

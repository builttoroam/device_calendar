import 'dart:async';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import '../event_item.dart';
import '../recurring_event_dialog.dart';
import 'calendar_event.dart';

class CalendarEventsPage extends StatefulWidget {
  final Calendar _calendar;

  const CalendarEventsPage(this._calendar, {Key? key}) : super(key: key);

  @override
  _CalendarEventsPageState createState() {
    return _CalendarEventsPageState(_calendar);
  }
}

class _CalendarEventsPageState extends State<CalendarEventsPage> {
  final Calendar _calendar;
  final GlobalKey<ScaffoldState> _scaffoldstate = GlobalKey<ScaffoldState>();

  late DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Event> _calendarEvents = [];
  List<EventColor>? _eventColors;
  bool _isLoading = true;

  _CalendarEventsPageState(this._calendar) {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  @override
  void initState() {
    super.initState();
    _retrieveEventColors();
    _retrieveCalendarEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldstate,
        appBar: AppBar(
          title: Text('${_calendar.name} events'),
          actions: [_getDeleteButton()],
        ),
        body: (_calendarEvents.isNotEmpty || _isLoading)
            ? Stack(
                children: [
                  ListView.builder(
                    itemCount: _calendarEvents.length,
                    itemBuilder: (BuildContext context, int index) {
                      return EventItem(
                          _calendarEvents[index],
                          _deviceCalendarPlugin,
                          _onLoading,
                          _onDeletedFinished,
                          _onTapped,
                          _calendar.isReadOnly != null &&
                              _calendar.isReadOnly as bool);
                    },
                  ),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                ],
              )
            : const Center(child: Text('No events found')),
        floatingActionButton: _getAddEventButton(context));
  }

  Widget? _getAddEventButton(BuildContext context) {
    if (_calendar.isReadOnly == false || _calendar.isReadOnly == null) {
      return FloatingActionButton(
        key: const Key('addEventButton'),
        onPressed: () async {
          final refreshEvents = await Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return CalendarEventPage(_calendar, null, null, _eventColors);
          }));
          if (refreshEvents == true) {
            await _retrieveCalendarEvents();
          }
        },
        child: const Icon(Icons.add),
      );
    } else {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
      return CalendarEventPage(
        _calendar,
        event,
        RecurringEventDialog(
          _deviceCalendarPlugin,
          event,
          _onLoading,
          _onDeletedFinished,
        ),
          _eventColors
      );
    }));
    if (refreshEvents != null && refreshEvents) {
      await _retrieveCalendarEvents();
    }
  }

  Future _retrieveCalendarEvents() async {
    final startDate = DateTime.now().add(const Duration(days: -30));
    final endDate = DateTime.now().add(const Duration(days: 365 * 10));
    var calendarEventsResult = await _deviceCalendarPlugin.retrieveEvents(
        _calendar.id,
        RetrieveEventsParams(startDate: startDate, endDate: endDate));
    setState(() {
      _calendarEvents = calendarEventsResult.data ?? [];
      _isLoading = false;
    });
  }

  void _retrieveEventColors() async {
    _eventColors = await _deviceCalendarPlugin.retrieveEventColors(_calendar);
  }

  Widget _getDeleteButton() {
    return IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          await _showDeleteDialog();
        });
  }

  Future<void> _showDeleteDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('This will delete this calendar'),
                Text('Are you sure?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                var returnValue =
                    await _deviceCalendarPlugin.deleteCalendar(_calendar.id!);
                debugPrint(
                    'returnValue: ${returnValue.data}, ${returnValue.errors}');
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Delete!'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

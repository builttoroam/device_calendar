import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../date_time_picker.dart';

class CalendarEventPage extends StatefulWidget {
  final Calendar _calendar;
  final Event _event;

  CalendarEventPage(this._calendar, [this._event]);

  @override
  _CalendarEventPageState createState() {
    return new _CalendarEventPageState(_calendar, _event);
  }
}

class _CalendarEventPageState extends State<CalendarEventPage> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final Calendar _calendar;

  Event _event;
  DeviceCalendarPlugin _deviceCalendarPlugin;

  DateTime _startDate;
  TimeOfDay _startTime;

  DateTime _endDate;
  TimeOfDay _endTime;

  bool _autovalidate = false;

  _CalendarEventPageState(this._calendar, this._event) {
    _deviceCalendarPlugin = new DeviceCalendarPlugin();
    if (this._event == null) {
      _startDate = new DateTime.now();
      _endDate = new DateTime.now().add(new Duration(hours: 1));
      _event = new Event(this._calendar.id, start: _startDate, end: _endDate);
    } else {
      _startDate = _event.start;
      _endDate = _event.end;
    }

    _startTime =
        new TimeOfDay(hour: _startDate.hour, minute: _startDate.minute);
    _endTime = new TimeOfDay(hour: _endDate.hour, minute: _endDate.minute);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text(_event.eventId?.isEmpty ?? true
              ? 'Create new event'
              : 'Edit event ${_event.title}'),
        ),
        body: new SingleChildScrollView(
          child: new Column(
            children: <Widget>[
              new Form(
                autovalidate: _autovalidate,
                key: _formKey,
                child: new Column(
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        new Expanded(
                            flex: 1,
                            child: new Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: new TextFormField(
                                initialValue: _event.title,
                                decoration: const InputDecoration(
                                    labelText: 'Title',
                                    hintText: 'Meeting with Gloria...'),
                                validator: _validateTitle,
                                onSaved: (String value) {
                                  _event.title = value;
                                },
                              ),
                            )),
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        new Expanded(
                            flex: 1,
                            child: new Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: new TextFormField(
                                initialValue: _event.description,
                                decoration: const InputDecoration(
                                    labelText: 'Description',
                                    hintText: 'Remember to buy flowers...'),
                                onSaved: (String value) {
                                  _event.description = value;
                                },
                              ),
                            )),
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        new Expanded(
                            flex: 1,
                            child: new Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: new DateTimePicker(
                                    labelText: 'From',
                                    selectedDate: _startDate,
                                    selectedTime: _startTime,
                                    selectDate: (DateTime date) {
                                      setState(() {
                                        _startDate = date;
                                        _event.start = _combineDateWithTime(
                                            _startDate, _startTime);
                                      });
                                    },
                                    selectTime: (TimeOfDay time) {
                                      setState(() {
                                        _startTime = time;
                                        _event.start = _combineDateWithTime(
                                            _startDate, _startTime);
                                      });
                                    })))
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        new Expanded(
                            flex: 1,
                            child: new Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: new DateTimePicker(
                                    labelText: 'To',
                                    selectedDate: _endDate,
                                    selectedTime: _endTime,
                                    selectDate: (DateTime date) {
                                      setState(() {
                                        _endDate = date;
                                        _event.end = _combineDateWithTime(
                                            _endDate, _endTime);
                                      });
                                    },
                                    selectTime: (TimeOfDay time) {
                                      setState(() {
                                        _endTime = time;
                                        _event.end = _combineDateWithTime(
                                            _endDate, _endTime);
                                      });
                                    })))
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        floatingActionButton: new FloatingActionButton(
          onPressed: () async {
            final FormState form = _formKey.currentState;
            if (!form.validate()) {
              _autovalidate = true; // Start validating on every change.
              showInSnackBar('Please fix the errors in red before submitting.');
            } else {
              form.save();
              var createEventResult =
                  await _deviceCalendarPlugin.createOrUpdateEvent(_event);
              if (createEventResult.isSuccess) {
                Navigator.pop(context, true);
              } else {
                showInSnackBar(createEventResult.errorMessages.join(' | '));
              }
            }
          },
          child: new Icon(Icons.check),
        ));
  }

  String _validateTitle(String value) {
    if (value.isEmpty) {
      return 'Name is required.';
    }

    return null;
  }

  DateTime _combineDateWithTime(DateTime date, TimeOfDay time) {
    final dateWithoutTime =
        DateTime.parse(new DateFormat("y-MM-dd 00:00:00").format(_startDate));
    return dateWithoutTime
        .add(new Duration(hours: time.hour, minutes: time.minute));
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }
}

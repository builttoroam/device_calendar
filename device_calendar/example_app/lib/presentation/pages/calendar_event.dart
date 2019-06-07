import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../date_time_picker.dart';

enum RecurrenceRuleEndType { MaxOccurrences, SpecifiedEndDate }

class CalendarEventPage extends StatefulWidget {
  final Calendar _calendar;
  final Event _event;

  CalendarEventPage(this._calendar, [this._event]);

  @override
  _CalendarEventPageState createState() {
    return _CalendarEventPageState(_calendar, _event);
  }
}

class _CalendarEventPageState extends State<CalendarEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Calendar _calendar;

  Event _event;
  DeviceCalendarPlugin _deviceCalendarPlugin;

  DateTime _startDate;
  TimeOfDay _startTime;

  DateTime _endDate;
  TimeOfDay _endTime;

  bool _autovalidate = false;
  bool _isRecurringEvent = false;
  RecurrenceRuleEndType _recurrenceRuleEndType;

  int _totalOccurrences;
  int _interval;
  DateTime _recurrenceEndDate;
  TimeOfDay _recurrenceEndTime;

  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.Daily;

  _CalendarEventPageState(this._calendar, this._event) {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
    if (this._event == null) {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(Duration(hours: 1));
      _event = Event(this._calendar.id, start: _startDate, end: _endDate);
      _recurrenceEndDate = _endDate;
    } else {
      _startDate = _event.start;
      _endDate = _event.end;
      _isRecurringEvent = _event.recurrenceRule != null;
      if(_isRecurringEvent) {
        _totalOccurrences = _event.recurrenceRule.totalOccurrences;
        _interval = _event.recurrenceRule.interval;
      }
    }

    _startTime = TimeOfDay(hour: _startDate.hour, minute: _startDate.minute);
    _endTime = TimeOfDay(hour: _endDate.hour, minute: _endDate.minute);
    if(_recurrenceEndDate != null) {
    _recurrenceEndTime = TimeOfDay(
        hour: _recurrenceEndDate.hour, minute: _recurrenceEndDate.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_event.eventId?.isEmpty ?? true
              ? 'Create new event'
              : 'Edit event ${_event.title}'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Form(
                autovalidate: _autovalidate,
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        initialValue: _event.title,
                        decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'Meeting with Gloria...'),
                        validator: _validateTitle,
                        onSaved: (String value) {
                          _event.title = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        initialValue: _event.description,
                        decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Remember to buy flowers...'),
                        onSaved: (String value) {
                          _event.description = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: DateTimePicker(
                        labelText: 'From',
                        selectedDate: _startDate,
                        selectedTime: _startTime,
                        selectDate: (DateTime date) {
                          setState(() {
                            _startDate = date;
                            _event.start =
                                _combineDateWithTime(_startDate, _startTime);
                          });
                        },
                        selectTime: (TimeOfDay time) {
                          setState(
                            () {
                              _startTime = time;
                              _event.start =
                                  _combineDateWithTime(_startDate, _startTime);
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: DateTimePicker(
                        labelText: 'To',
                        selectedDate: _endDate,
                        selectedTime: _endTime,
                        selectDate: (DateTime date) {
                          setState(
                            () {
                              _endDate = date;
                              _event.end =
                                  _combineDateWithTime(_endDate, _endTime);
                            },
                          );
                        },
                        selectTime: (TimeOfDay time) {
                          setState(
                            () {
                              _endTime = time;
                              _event.end =
                                  _combineDateWithTime(_endDate, _endTime);
                            },
                          );
                        },
                      ),
                    ),
                    CheckboxListTile(
                      value: _isRecurringEvent,
                      title: Text('Is recurring'),
                      onChanged: (isChecked) {
                        setState(() {
                          _isRecurringEvent = isChecked;
                        });
                      },
                    ),
                    if (_isRecurringEvent)
                      Column(
                        children: [
                          ListTile(
                            leading: Text('Frequency'),
                            trailing: DropdownButton<RecurrenceFrequency>(
                              onChanged: (selectedFrequency) {
                                setState(() {
                                  _recurrenceFrequency = selectedFrequency;
                                });
                              },
                              value: _recurrenceFrequency,
                              items: RecurrenceFrequency.values
                                  .map(
                                    (f) => DropdownMenuItem(
                                          value: f,
                                          child: _recurrenceFrequencyToText(f),
                                        ),
                                  )
                                  .toList(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Interval between events',
                                  hintText: '1'),
                              keyboardType: TextInputType.number,
                              validator: _validateInterval,
                              onSaved: (String value) {
                                _interval = int.tryParse(value);
                              },
                            ),
                          ),
                          ListTile(
                            leading: Text('Event ends'),
                            trailing: DropdownButton<RecurrenceRuleEndType>(
                              onChanged: (value) {
                                setState(() {
                                  _recurrenceRuleEndType = value;
                                });
                              },
                              value: _recurrenceRuleEndType,
                              items: RecurrenceRuleEndType.values
                                  .map(
                                    (f) => DropdownMenuItem(
                                          value: f,
                                          child:
                                              _recurrenceRuleEndTypeToText(f),
                                        ),
                                  )
                                  .toList(),
                            ),
                          ),
                          if (_recurrenceRuleEndType ==
                              RecurrenceRuleEndType.MaxOccurrences)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'Max occurrences',
                                    hintText: '1'),
                                keyboardType: TextInputType.number,
                                validator: _validateTotalOccurrences,
                                onSaved: (String value) {
                                  _totalOccurrences = int.tryParse(value);
                                },
                              ),
                            ),
                          if (_recurrenceRuleEndType ==
                              RecurrenceRuleEndType.SpecifiedEndDate)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: DateTimePicker(
                                labelText: 'Date',
                                selectedDate: _recurrenceEndDate,
                                selectedTime: _recurrenceEndTime,
                                selectDate: (DateTime date) {
                                  setState(() {
                                    _recurrenceEndDate = date;
                                  });
                                },
                                selectTime: (TimeOfDay time) {
                                  setState(() {
                                    _recurrenceEndTime = time;
                                  });
                                },
                              ),
                            ),
                        ],
                      )
                  ],
                ),
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final FormState form = _formKey.currentState;
            if (!form.validate()) {
              _autovalidate = true; // Start validating on every change.
              showInSnackBar('Please fix the errors in red before submitting.');
            } else {
              form.save();
              if (_isRecurringEvent) {
                _event.recurrenceRule = RecurrenceRule(_recurrenceFrequency,
                    interval: _interval,
                    totalOccurrences: _totalOccurrences,
                    endDate: _recurrenceRuleEndType == RecurrenceRuleEndType.SpecifiedEndDate ? _combineDateWithTime(
                        _recurrenceEndDate, _recurrenceEndTime) : null);
              }
              var createEventResult =
                  await _deviceCalendarPlugin.createOrUpdateEvent(_event);
              if (createEventResult.isSuccess) {
                Navigator.pop(context, true);
              } else {
                showInSnackBar(createEventResult.errorMessages.join(' | '));
              }
            }
          },
          child: Icon(Icons.check),
        ));
  }

  Text _recurrenceFrequencyToText(RecurrenceFrequency recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return Text('Daily');
      case RecurrenceFrequency.Weekly:
        return Text('Weekly');
      case RecurrenceFrequency.Monthly:
        return Text('Monthly');
      case RecurrenceFrequency.Yearly:
        return Text('Yearly');
      default:
        return Text('');
    }
  }

  Text _recurrenceRuleEndTypeToText(RecurrenceRuleEndType endType) {
    switch (endType) {
      case RecurrenceRuleEndType.MaxOccurrences:
        return Text('After a set number of times');
      case RecurrenceRuleEndType.SpecifiedEndDate:
        return Text('Continues until a specified date');
      default:
        return Text('');
    }
  }

  String _validateTotalOccurrences(String value) {
    if (!value.isEmpty && int.tryParse(value) == null) {
      return 'Total occurrences needs to be a valid number';
    }
    return null;
  }

  String _validateInterval(String value) {
    if (!value.isEmpty && int.tryParse(value) == null) {
      return 'Interval needs to be a valid number';
    }
    return null;
  }

  String _validateTitle(String value) {
    if (value.isEmpty) {
      return 'Name is required.';
    }

    return null;
  }

  DateTime _combineDateWithTime(DateTime date, TimeOfDay time) {
    if (date == null && time == null) {
      return null;
    }
    final dateWithoutTime =
        DateTime.parse(DateFormat("y-MM-dd 00:00:00").format(date));
    return dateWithoutTime
        .add(Duration(hours: time.hour, minutes: time.minute));
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(value)));
  }
}

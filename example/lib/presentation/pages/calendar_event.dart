import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import '../date_time_picker.dart';
import '../recurring_event_dialog.dart';
import 'event_attendee.dart';
import 'event_reminders.dart';

enum RecurrenceRuleEndType { Indefinite, MaxOccurrences, SpecifiedEndDate }

class CalendarEventPage extends StatefulWidget {
  late final Calendar _calendar;
  final Event? _event;
  final RecurringEventDialog? _recurringEventDialog;

  CalendarEventPage(this._calendar, [this._event, this._recurringEventDialog]);

  @override
  _CalendarEventPageState createState() {
    return _CalendarEventPageState(_calendar, _event, _recurringEventDialog);
  }
}

class _CalendarEventPageState extends State<CalendarEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Calendar _calendar;

  Event? _event;
  late DeviceCalendarPlugin _deviceCalendarPlugin;
  final RecurringEventDialog? _recurringEventDialog;

  TZDateTime? _startDate;
  TimeOfDay? _startTime;

  TZDateTime? _endDate;
  TimeOfDay? _endTime;

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  DayOfWeekGroup? _dayOfWeekGroup = DayOfWeekGroup.None;

  bool _isRecurringEvent = false;
  bool _isByDayOfMonth = false;
  RecurrenceRuleEndType? _recurrenceRuleEndType;
  int? _totalOccurrences;
  int? _interval;
  late DateTime _recurrenceEndDate;
  RecurrenceFrequency? _recurrenceFrequency = RecurrenceFrequency.Daily;
  List<DayOfWeek> _daysOfWeek = [];
  int? _dayOfMonth;
  final List<int> _validDaysOfMonth = [];
  MonthOfYear? _monthOfYear;
  WeekNumber? _weekOfMonth;
  DayOfWeek? _selectedDayOfWeek = DayOfWeek.Monday;
  Availability _availability = Availability.Busy;
  EventStatus? _eventStatus;

  List<Attendee> _attendees = [];
  List<Reminder> _reminders = [];
  String _timezone = 'Etc/UTC';

  _CalendarEventPageState(
      this._calendar, this._event, this._recurringEventDialog) {
    getCurentLocation();
  }

  void getCurentLocation() async {
    try {
      _timezone = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      print('Could not get the local timezone');
    }

    _deviceCalendarPlugin = DeviceCalendarPlugin();

    _attendees = <Attendee>[];
    _reminders = <Reminder>[];
    _recurrenceRuleEndType = RecurrenceRuleEndType.Indefinite;

    if (_event == null) {
      print('calendar_event _timezone ------------------------- $_timezone');
      var currentLocation = timeZoneDatabase.locations[_timezone];
      if (currentLocation != null) {
        _startDate = TZDateTime.now(currentLocation);
        _endDate =
            TZDateTime.now(currentLocation).add(const Duration(hours: 1));
      } else {
        var fallbackLocation = timeZoneDatabase.locations['Etc/UTC'];
        _startDate = TZDateTime.now(fallbackLocation!);
        _endDate =
            TZDateTime.now(fallbackLocation).add(const Duration(hours: 1));
      }
      _event = Event(_calendar.id, start: _startDate, end: _endDate);

      print('DeviceCalendarPlugin calendar id is: ${_calendar.id}');

      _recurrenceEndDate = _endDate as DateTime;
      _dayOfMonth = 1;
      _monthOfYear = MonthOfYear.January;
      _weekOfMonth = WeekNumber.First;
      _availability = Availability.Busy;
      _eventStatus = EventStatus.None;
    } else {
      _startDate = _event!.start!;
      _endDate = _event!.end!;
      _isRecurringEvent = _event!.recurrenceRule != null;

      if (_event!.attendees!.isNotEmpty) {
        _attendees.addAll(_event!.attendees! as Iterable<Attendee>);
      }

      if (_event!.reminders!.isNotEmpty) {
        _reminders.addAll(_event!.reminders!);
      }

      if (_isRecurringEvent) {
        _interval = _event!.recurrenceRule!.interval!;
        _totalOccurrences = _event!.recurrenceRule!.totalOccurrences;
        _recurrenceFrequency = _event!.recurrenceRule!.recurrenceFrequency;

        if (_totalOccurrences != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.MaxOccurrences;
        }

        if (_event!.recurrenceRule!.endDate != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.SpecifiedEndDate;
          _recurrenceEndDate = _event!.recurrenceRule!.endDate!;
        }

        _isByDayOfMonth = _event?.recurrenceRule?.weekOfMonth == null;
        _daysOfWeek = _event?.recurrenceRule?.daysOfWeek ?? <DayOfWeek>[];
        _monthOfYear =
            _event?.recurrenceRule?.monthOfYear ?? MonthOfYear.January;
        _weekOfMonth = _event?.recurrenceRule?.weekOfMonth ?? WeekNumber.First;
        _selectedDayOfWeek =
            _daysOfWeek.isNotEmpty ? _daysOfWeek.first : DayOfWeek.Monday;
        _dayOfMonth = _event?.recurrenceRule?.dayOfMonth ?? 1;

        if (_daysOfWeek.isNotEmpty) {
          _updateDaysOfWeekGroup();
        }
      }

      _availability = _event!.availability;
      _eventStatus = _event!.status;
    }

    _startTime = TimeOfDay(hour: _startDate!.hour, minute: _startDate!.minute);
    _endTime = TimeOfDay(hour: _endDate!.hour, minute: _endDate!.minute);

    // Getting days of the current month (or a selected month for the yearly recurrence) as a default
    _getValidDaysOfMonth(_recurrenceFrequency);
    setState(() {});
  }

  void printAttendeeDetails(Attendee attendee) {
    print(
        'attendee name: ${attendee.name}, email address: ${attendee.emailAddress}, type: ${attendee.role?.enumToString}');
    print(
        'ios specifics - status: ${attendee.iosAttendeeDetails?.attendanceStatus}, type: ${attendee.iosAttendeeDetails?.attendanceStatus?.enumToString}');
    print(
        'android specifics - status ${attendee.androidAttendeeDetails?.attendanceStatus}, type: ${attendee.androidAttendeeDetails?.attendanceStatus?.enumToString}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_event?.eventId?.isEmpty ?? true
            ? 'Create event'
            : _calendar.isReadOnly == true
                ? 'View event ${_event?.title}'
                : 'Edit event ${_event?.title}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: _calendar.isReadOnly ?? false,
            child: Column(
              children: [
                Form(
                  autovalidateMode: _autovalidate,
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextFormField(
                          key: const Key('titleField'),
                          initialValue: _event?.title,
                          decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Meeting with Gloria...'),
                          validator: _validateTitle,
                          onSaved: (String? value) {
                            _event?.title = value;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextFormField(
                          initialValue: _event?.description,
                          decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Remember to buy flowers...'),
                          onSaved: (String? value) {
                            _event?.description = value;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextFormField(
                          initialValue: _event?.location,
                          decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'Sydney, Australia'),
                          onSaved: (String? value) {
                            _event?.location = value;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextFormField(
                          initialValue: _event?.url?.data?.contentText ?? '',
                          decoration: const InputDecoration(
                              labelText: 'URL', hintText: 'https://google.com'),
                          onSaved: (String? value) {
                            if (value != null) {
                              var uri = Uri.dataFromString(value);
                              _event?.url = uri;
                            }
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Text(
                          'Availability',
                          style: TextStyle(fontSize: 16),
                        ),
                        trailing: DropdownButton<Availability>(
                          value: _availability,
                          onChanged: (Availability? newValue) {
                            setState(() {
                              if (newValue != null) {
                                _availability = newValue;
                                _event?.availability = newValue;
                              }
                            });
                          },
                          items: Availability.values
                              .map<DropdownMenuItem<Availability>>(
                                  (Availability value) {
                            return DropdownMenuItem<Availability>(
                              value: value,
                              child: Text(value.enumToString),
                            );
                          }).toList(),
                        ),
                      ),
                      if (Platform.isAndroid)
                        ListTile(
                          leading: const Text(
                            'Status',
                            style: TextStyle(fontSize: 16),
                          ),
                          trailing: DropdownButton<EventStatus>(
                            value: _eventStatus,
                            onChanged: (EventStatus? newValue) {
                              setState(() {
                                if (newValue != null) {
                                  _eventStatus = newValue;
                                  _event?.status = newValue;
                                }
                              });
                            },
                            items: EventStatus.values
                                .map<DropdownMenuItem<EventStatus>>(
                                    (EventStatus value) {
                              return DropdownMenuItem<EventStatus>(
                                value: value,
                                child: Text(value.enumToString),
                              );
                            }).toList(),
                          ),
                        ),
                      SwitchListTile(
                        value: _event?.allDay ?? false,
                        onChanged: (value) =>
                            setState(() => _event?.allDay = value),
                        title: const Text('All Day'),
                      ),
                      if (_startDate != null)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: DateTimePicker(
                            labelText: 'From',
                            enableTime: _event?.allDay == false,
                            selectedDate: _startDate,
                            selectedTime: _startTime,
                            selectDate: (DateTime date) {
                              setState(() {
                                var currentLocation =
                                    timeZoneDatabase.locations[_timezone];
                                if (currentLocation != null) {
                                  _startDate =
                                      TZDateTime.from(date, currentLocation);
                                  _event?.start = _combineDateWithTime(
                                      _startDate, _startTime);
                                }
                              });
                            },
                            selectTime: (TimeOfDay time) {
                              setState(
                                () {
                                  _startTime = time;
                                  _event?.start = _combineDateWithTime(
                                      _startDate, _startTime);
                                },
                              );
                            },
                          ),
                        ),
                      if ((_event?.allDay == false) && Platform.isAndroid)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            initialValue: _event?.start?.location.name,
                            decoration: const InputDecoration(
                                labelText: 'Start date time zone',
                                hintText: 'Australia/Sydney'),
                            onSaved: (String? value) {
                              _event?.updateStartLocation(value);
                            },
                          ),
                        ),
                      // Only add the 'To' Date for non-allDay events on all
                      // platforms except Android (which allows multiple-day allDay events)
                      if (_event?.allDay == false || Platform.isAndroid)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: DateTimePicker(
                            labelText: 'To',
                            selectedDate: _endDate,
                            selectedTime: _endTime,
                            enableTime: _event?.allDay == false,
                            selectDate: (DateTime date) {
                              setState(
                                () {
                                  var currentLocation =
                                      timeZoneDatabase.locations[_timezone];
                                  if (currentLocation != null) {
                                    _endDate =
                                        TZDateTime.from(date, currentLocation);
                                    _event?.end = _combineDateWithTime(
                                        _endDate, _endTime);
                                  }
                                },
                              );
                            },
                            selectTime: (TimeOfDay time) {
                              setState(
                                () {
                                  _endTime = time;
                                  _event?.end =
                                      _combineDateWithTime(_endDate, _endTime);
                                },
                              );
                            },
                          ),
                        ),
                      if (_event?.allDay == false && Platform.isAndroid)
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            initialValue: _event?.end?.location.name,
                            decoration: const InputDecoration(
                                labelText: 'End date time zone',
                                hintText: 'Australia/Sydney'),
                            onSaved: (String? value) =>
                                _event?.updateEndLocation(value),
                          ),
                        ),
                      ListTile(
                        onTap: _calendar.isReadOnly == false
                            ? () async {
                                var result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const EventAttendeePage()));
                                if (result != null) {
                                  setState(() {
                                    _attendees.add(result);
                                  });
                                }
                              }
                            : null,
                        leading: const Icon(Icons.people),
                        title: Text(_calendar.isReadOnly == false
                            ? 'Add Attendees'
                            : 'Attendees'),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _attendees.length,
                        itemBuilder: (context, index) {
                          return Container(
                            color: (_attendees[index].isOrganiser)
                                ? MediaQuery.of(context).platformBrightness ==
                                        Brightness.dark
                                    ? Colors.black26
                                    : Colors.greenAccent[100]
                                : Colors.transparent,
                            child: ListTile(
                              onTap: () async {
                                var result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => EventAttendeePage(
                                            attendee: _attendees[index],
                                            eventId: _event?.eventId)));
                                if (result != null) {
                                  return setState(() {
                                    _attendees[index] = result;
                                  });
                                }
                              },
                              title: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                    '${_attendees[index].name} (${_attendees[index].emailAddress})'),
                              ),
                              subtitle: Wrap(
                                spacing: 10,
                                direction: Axis.horizontal,
                                alignment: WrapAlignment.end,
                                children: <Widget>[
                                  Visibility(
                                    visible: _attendees[index]
                                            .androidAttendeeDetails !=
                                        null,
                                    child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        padding: const EdgeInsets.all(3.0),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.blueAccent)),
                                        child: Text(
                                            'Android: ${_attendees[index].androidAttendeeDetails?.attendanceStatus?.enumToString}')),
                                  ),
                                  Visibility(
                                    visible:
                                        _attendees[index].iosAttendeeDetails !=
                                            null,
                                    child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        padding: const EdgeInsets.all(3.0),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.blueAccent)),
                                        child: Text(
                                            'iOS: ${_attendees[index].iosAttendeeDetails?.attendanceStatus?.enumToString}')),
                                  ),
                                  Visibility(
                                      visible: _attendees[index].isCurrentUser,
                                      child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10.0),
                                          padding: const EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.blueAccent)),
                                          child: const Text('current user'))),
                                  Visibility(
                                      visible: _attendees[index].isOrganiser,
                                      child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10.0),
                                          padding: const EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.blueAccent)),
                                          child: const Text('Organiser'))),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    padding: const EdgeInsets.all(3.0),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.blueAccent)),
                                    child: Text(
                                        '${_attendees[index].role?.enumToString}'),
                                  ),
                                  IconButton(
                                    padding: const EdgeInsets.all(0),
                                    onPressed: () {
                                      setState(() {
                                        _attendees.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.redAccent,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () async {
                          var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EventRemindersPage(_reminders)));
                          if (result == null) {
                            return;
                          }
                          _reminders = result;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10.0,
                              children: [
                                const Icon(Icons.alarm),
                                if (_reminders.isEmpty)
                                  Text(_calendar.isReadOnly == false
                                      ? 'Add reminders'
                                      : 'Reminders'),
                                for (var reminder in _reminders)
                                  Text('${reminder.minutes} minutes before; ')
                              ],
                            ),
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        value: _isRecurringEvent,
                        title: const Text('Is recurring'),
                        onChanged: (isChecked) {
                          setState(() {
                            _isRecurringEvent = isChecked ?? false;
                          });
                        },
                      ),
                      if (_isRecurringEvent) ...[
                        ListTile(
                          leading: const Text('Select a Recurrence Type'),
                          trailing: DropdownButton<RecurrenceFrequency>(
                            onChanged: (selectedFrequency) {
                              setState(() {
                                _recurrenceFrequency = selectedFrequency;
                                _getValidDaysOfMonth(_recurrenceFrequency);
                              });
                            },
                            value: _recurrenceFrequency,
                            items: RecurrenceFrequency.values
                                .map((frequency) => DropdownMenuItem(
                                      value: frequency,
                                      child:
                                          _recurrenceFrequencyToText(frequency),
                                    ))
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                          child: Row(
                            children: <Widget>[
                              const Text('Repeat Every '),
                              Flexible(
                                child: TextFormField(
                                  initialValue: _interval?.toString() ?? '1',
                                  decoration:
                                      const InputDecoration(hintText: '1'),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2)
                                  ],
                                  validator: _validateInterval,
                                  textAlign: TextAlign.right,
                                  onSaved: (String? value) {
                                    if (value != null) {
                                      _interval = int.tryParse(value);
                                    }
                                  },
                                ),
                              ),
                              _recurrenceFrequencyToIntervalText(
                                  _recurrenceFrequency),
                            ],
                          ),
                        ),
                        if (_recurrenceFrequency ==
                            RecurrenceFrequency.Weekly) ...[
                          Column(
                            children: [
                              ...DayOfWeek.values.map((day) {
                                return CheckboxListTile(
                                  title: Text(day.enumToString),
                                  value: _daysOfWeek.any((dow) => dow == day),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _daysOfWeek.add(day);
                                      } else {
                                        _daysOfWeek.remove(day);
                                      }
                                      _updateDaysOfWeekGroup(selectedDay: day);
                                    });
                                  },
                                );
                              }),
                              const Divider(color: Colors.black),
                              ...DayOfWeekGroup.values.map((group) {
                                return RadioListTile(
                                    title: Text(group.enumToString),
                                    value: group,
                                    groupValue: _dayOfWeekGroup,
                                    onChanged: (selected) {
                                      setState(() {
                                        _dayOfWeekGroup =
                                            selected as DayOfWeekGroup;
                                        _updateDaysOfWeek();
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.trailing);
                              }),
                            ],
                          )
                        ],
                        if (_recurrenceFrequency ==
                                RecurrenceFrequency.Monthly ||
                            _recurrenceFrequency ==
                                RecurrenceFrequency.Yearly) ...[
                          SwitchListTile(
                            value: _isByDayOfMonth,
                            onChanged: (value) =>
                                setState(() => _isByDayOfMonth = value),
                            title: const Text('By day of the month'),
                          )
                        ],
                        if (_recurrenceFrequency ==
                                RecurrenceFrequency.Yearly &&
                            _isByDayOfMonth) ...[
                          ListTile(
                            leading: const Text('Month of the year'),
                            trailing: DropdownButton<MonthOfYear>(
                              onChanged: (value) {
                                setState(() {
                                  _monthOfYear = value;
                                  _getValidDaysOfMonth(_recurrenceFrequency);
                                });
                              },
                              value: _monthOfYear,
                              items: MonthOfYear.values
                                  .map((month) => DropdownMenuItem(
                                        value: month,
                                        child: Text(month.enumToString),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                        if (_isByDayOfMonth &&
                            (_recurrenceFrequency ==
                                    RecurrenceFrequency.Monthly ||
                                _recurrenceFrequency ==
                                    RecurrenceFrequency.Yearly)) ...[
                          ListTile(
                            leading: const Text('Day of the month'),
                            trailing: DropdownButton<int>(
                              onChanged: (value) {
                                setState(() {
                                  _dayOfMonth = value;
                                });
                              },
                              value: _dayOfMonth,
                              items: _validDaysOfMonth
                                  .map((day) => DropdownMenuItem(
                                        value: day,
                                        child: Text(day.toString()),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                        if (!_isByDayOfMonth &&
                            (_recurrenceFrequency ==
                                    RecurrenceFrequency.Monthly ||
                                _recurrenceFrequency ==
                                    RecurrenceFrequency.Yearly)) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: _recurrenceFrequencyToText(
                                                _recurrenceFrequency)
                                            .data !=
                                        null
                                    ? Text(_recurrenceFrequencyToText(
                                                _recurrenceFrequency)
                                            .data! +
                                        ' on the ')
                                    : const Text('')),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: DropdownButton<WeekNumber>(
                                    onChanged: (value) {
                                      setState(() {
                                        _weekOfMonth = value;
                                      });
                                    },
                                    value: _weekOfMonth ?? WeekNumber.First,
                                    items: WeekNumber.values
                                        .map((weekNum) => DropdownMenuItem(
                                              value: weekNum,
                                              child: Text(weekNum.enumToString),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                Flexible(
                                  child: DropdownButton<DayOfWeek>(
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDayOfWeek = value;
                                      });
                                    },
                                    value: _selectedDayOfWeek != null
                                        ? DayOfWeek
                                            .values[_selectedDayOfWeek!.index]
                                        : DayOfWeek.values[0],
                                    items: DayOfWeek.values
                                        .map((day) => DropdownMenuItem(
                                              value: day,
                                              child: Text(day.enumToString),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                if (_recurrenceFrequency ==
                                    RecurrenceFrequency.Yearly) ...[
                                  const Text('of'),
                                  Flexible(
                                    child: DropdownButton<MonthOfYear>(
                                      onChanged: (value) {
                                        setState(() {
                                          _monthOfYear = value;
                                        });
                                      },
                                      value: _monthOfYear,
                                      items: MonthOfYear.values
                                          .map((month) => DropdownMenuItem(
                                                value: month,
                                                child: Text(month.enumToString),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                        ListTile(
                          leading: const Text('Event ends'),
                          trailing: DropdownButton<RecurrenceRuleEndType>(
                            onChanged: (value) {
                              setState(() {
                                _recurrenceRuleEndType = value;
                              });
                            },
                            value: _recurrenceRuleEndType,
                            items: RecurrenceRuleEndType.values
                                .map((frequency) => DropdownMenuItem(
                                      value: frequency,
                                      child: _recurrenceRuleEndTypeToText(
                                          frequency),
                                    ))
                                .toList(),
                          ),
                        ),
                        if (_recurrenceRuleEndType ==
                            RecurrenceRuleEndType.MaxOccurrences)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                            child: Row(
                              children: <Widget>[
                                const Text('For the next '),
                                Flexible(
                                  child: TextFormField(
                                    initialValue:
                                        _totalOccurrences?.toString() ?? '1',
                                    decoration:
                                        const InputDecoration(hintText: '1'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    validator: _validateTotalOccurrences,
                                    textAlign: TextAlign.right,
                                    onSaved: (String? value) {
                                      if (value != null) {
                                        _totalOccurrences = int.tryParse(value);
                                      }
                                    },
                                  ),
                                ),
                                const Text(' occurrences'),
                              ],
                            ),
                          ),
                        if (_recurrenceRuleEndType ==
                            RecurrenceRuleEndType.SpecifiedEndDate)
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DateTimePicker(
                              labelText: 'Date',
                              enableTime: false,
                              selectedDate: _recurrenceEndDate,
                              selectDate: (DateTime date) {
                                setState(() {
                                  _recurrenceEndDate = date;
                                });
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (_calendar.isReadOnly == false &&
                    (_event?.eventId?.isNotEmpty ?? false)) ...[
                  ElevatedButton(
                    key: const Key('deleteEventButton'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      bool? result = true;
                      if (!_isRecurringEvent) {
                        await _deviceCalendarPlugin.deleteEvent(
                            _calendar.id, _event?.eventId);
                      } else {
                        result = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return _recurringEventDialog != null
                                  ? _recurringEventDialog as Widget
                                  : const SizedBox();
                            });
                      }

                      if (result == true) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Visibility(
        visible: _calendar.isReadOnly == false,
        child: FloatingActionButton(
          key: const Key('saveEventButton'),
          onPressed: () async {
            final form = _formKey.currentState;
            if (form?.validate() == false) {
              _autovalidate =
                  AutovalidateMode.always; // Start validating on every change.
              showInSnackBar('Please fix the errors in red before submitting.');
            } else {
              form?.save();
              if (_isRecurringEvent) {
                if (!_isByDayOfMonth &&
                    (_recurrenceFrequency == RecurrenceFrequency.Monthly ||
                        _recurrenceFrequency == RecurrenceFrequency.Yearly)) {
                  // Setting day of the week parameters for WeekNumber to avoid clashing with the weekly recurrence values
                  _daysOfWeek.clear();
                  if (_selectedDayOfWeek != null) {
                    _daysOfWeek.add(_selectedDayOfWeek as DayOfWeek);
                  }
                } else {
                  _weekOfMonth = null;
                }

                _event?.recurrenceRule = RecurrenceRule(_recurrenceFrequency,
                    interval: _interval,
                    totalOccurrences: (_recurrenceRuleEndType ==
                            RecurrenceRuleEndType.MaxOccurrences)
                        ? _totalOccurrences
                        : null,
                    endDate: _recurrenceRuleEndType ==
                            RecurrenceRuleEndType.SpecifiedEndDate
                        ? _recurrenceEndDate
                        : null,
                    daysOfWeek: _daysOfWeek,
                    dayOfMonth: _dayOfMonth,
                    monthOfYear: _monthOfYear,
                    weekOfMonth: _weekOfMonth);
              }
              _event?.attendees = _attendees;
              _event?.reminders = _reminders;
              _event?.availability = _availability;
              _event?.status = _eventStatus;
              var createEventResult =
                  await _deviceCalendarPlugin.createOrUpdateEvent(_event);
              if (createEventResult?.isSuccess == true) {
                Navigator.pop(context, true);
              } else {
                showInSnackBar(createEventResult?.errors
                    .map((err) => '[${err.errorCode}] ${err.errorMessage}')
                    .join(' | ') as String);
              }
            }
          },
          child: const Icon(Icons.check),
        ),
      ),
    );
  }

  Text _recurrenceFrequencyToText(RecurrenceFrequency? recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return const Text('Daily');
      case RecurrenceFrequency.Weekly:
        return const Text('Weekly');
      case RecurrenceFrequency.Monthly:
        return const Text('Monthly');
      case RecurrenceFrequency.Yearly:
        return const Text('Yearly');
      default:
        return const Text('');
    }
  }

  Text _recurrenceFrequencyToIntervalText(
      RecurrenceFrequency? recurrenceFrequency) {
    switch (recurrenceFrequency) {
      case RecurrenceFrequency.Daily:
        return const Text(' Day(s)');
      case RecurrenceFrequency.Weekly:
        return const Text(' Week(s) on');
      case RecurrenceFrequency.Monthly:
        return const Text(' Month(s)');
      case RecurrenceFrequency.Yearly:
        return const Text(' Year(s)');
      default:
        return const Text('');
    }
  }

  Text _recurrenceRuleEndTypeToText(RecurrenceRuleEndType endType) {
    switch (endType) {
      case RecurrenceRuleEndType.Indefinite:
        return const Text('Indefinitely');
      case RecurrenceRuleEndType.MaxOccurrences:
        return const Text('After a set number of times');
      case RecurrenceRuleEndType.SpecifiedEndDate:
        return const Text('Continues until a specified date');
      default:
        return const Text('');
    }
  }

  // Get total days of a month
  void _getValidDaysOfMonth(RecurrenceFrequency? frequency) {
    _validDaysOfMonth.clear();
    var totalDays = 0;

    // Year frequency: Get total days of the selected month
    if (frequency == RecurrenceFrequency.Yearly) {
      totalDays = DateTime(DateTime.now().year,
              _monthOfYear?.value != null ? _monthOfYear!.value + 1 : 1, 0)
          .day;
    } else {
      // Otherwise, get total days of the current month
      var now = DateTime.now();
      totalDays = DateTime(now.year, now.month + 1, 0).day;
    }

    for (var i = 1; i <= totalDays; i++) {
      _validDaysOfMonth.add(i);
    }
  }

  void _updateDaysOfWeek() {
    if (_dayOfWeekGroup == null) return;
    var days = _dayOfWeekGroup!.getDays;

    switch (_dayOfWeekGroup) {
      case DayOfWeekGroup.Weekday:
      case DayOfWeekGroup.Weekend:
      case DayOfWeekGroup.AllDays:
        _daysOfWeek.clear();
        _daysOfWeek.addAll(days.where((a) => _daysOfWeek.every((b) => a != b)));
        break;
      case DayOfWeekGroup.None:
        _daysOfWeek.clear();
        break;
      default:
        _daysOfWeek.clear();
    }
  }

  void _updateDaysOfWeekGroup({DayOfWeek? selectedDay}) {
    var deepEquality = const DeepCollectionEquality.unordered().equals;

    // If _daysOfWeek contains nothing
    if (_daysOfWeek.isEmpty && _dayOfWeekGroup != DayOfWeekGroup.None) {
      _dayOfWeekGroup = DayOfWeekGroup.None;
    }
    // If _daysOfWeek contains Monday to Friday
    else if (deepEquality(_daysOfWeek, DayOfWeekGroup.Weekday.getDays) &&
        _dayOfWeekGroup != DayOfWeekGroup.Weekday) {
      _dayOfWeekGroup = DayOfWeekGroup.Weekday;
    }
    // If _daysOfWeek contains Saturday and Sunday
    else if (deepEquality(_daysOfWeek, DayOfWeekGroup.Weekend.getDays) &&
        _dayOfWeekGroup != DayOfWeekGroup.Weekend) {
      _dayOfWeekGroup = DayOfWeekGroup.Weekend;
    }
    // If _daysOfWeek contains all days
    else if (deepEquality(_daysOfWeek, DayOfWeekGroup.AllDays.getDays) &&
        _dayOfWeekGroup != DayOfWeekGroup.AllDays) {
      _dayOfWeekGroup = DayOfWeekGroup.AllDays;
    }
    // Otherwise null
    else {
      _dayOfWeekGroup = null;
    }
  }

  String? _validateTotalOccurrences(String? value) {
    if (value == null) return null;
    if (value.isNotEmpty && int.tryParse(value) == null) {
      return 'Total occurrences needs to be a valid number';
    }
    return null;
  }

  String? _validateInterval(String? value) {
    if (value == null) return null;
    if (value.isNotEmpty && int.tryParse(value) == null) {
      return 'Interval needs to be a valid number';
    }
    return null;
  }

  String? _validateTitle(String? value) {
    if (value == null) return null;
    if (value.isEmpty) {
      return 'Name is required.';
    }

    return null;
  }

  TZDateTime? _combineDateWithTime(TZDateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    var currentLocation = timeZoneDatabase.locations[_timezone];

    final dateWithoutTime = TZDateTime.from(
        DateTime.parse(DateFormat('y-MM-dd 00:00:00').format(date)),
        currentLocation!);

    if (time == null) return dateWithoutTime;
    if (Platform.isAndroid && _event?.allDay == true) return dateWithoutTime;

    return dateWithoutTime
        .add(Duration(hours: time.hour, minutes: time.minute));
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

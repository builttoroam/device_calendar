import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../date_time_picker.dart';
import '../recurring_event_dialog.dart';
import 'event_attendee.dart';
import 'event_reminders.dart';
import 'package:timezone/timezone.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

enum RecurrenceRuleEndType { Indefinite, MaxOccurrences, SpecifiedEndDate }

class CalendarEventPage extends StatefulWidget {
  final Calendar _calendar;
  final Event? _event;
  final RecurringEventDialog? _recurringEventDialog;

  const CalendarEventPage(this._calendar,
      [this._event, this._recurringEventDialog, Key? key])
      : super(key: key);

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
  late TimeOfDay _startTime;

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
  RecurrenceFrequency? _recurrenceFrequency = RecurrenceFrequency.daily;
  Set<ByWeekDayEntry> _daysOfWeek = {};
  Set<int> _dayOfMonth = {0};
  final List<int> _validDaysOfMonth = [];
  Set<int> _monthOfYear = {};
  Set<int> _weekOfMonth = {};
  DayOfWeek? _selectedDayOfWeek = DayOfWeek.Monday;
  Availability _availability = Availability.Busy;

  List<Attendee> _attendees = [];
  List<Reminder> _reminders = [];
  String _timezone = 'Etc/UTC';

  _CalendarEventPageState(
      this._calendar, this._event, this._recurringEventDialog) {
    getCurentLocation();
  }

  void getCurentLocation() async {
    try {
      _timezone = await FlutterNativeTimezone.getLocalTimezone();
    } catch (e) {
      debugPrint('Could not get the local timezone');
    }

    _deviceCalendarPlugin = DeviceCalendarPlugin();

    _attendees = <Attendee>[];
    _reminders = <Reminder>[];
    _recurrenceRuleEndType = RecurrenceRuleEndType.Indefinite;

    if (_event == null) {
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
      _recurrenceEndDate = _endDate as DateTime;
      _dayOfMonth = {};
      _monthOfYear = {};
      _weekOfMonth = {};
      _availability = Availability.Busy;
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
        _totalOccurrences = _event!.recurrenceRule!.count;
        _recurrenceFrequency = _event!.recurrenceRule!.recurrenceFrequency;

        if (_totalOccurrences != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.MaxOccurrences;
        }

        if (_event!.recurrenceRule!.until != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.SpecifiedEndDate;
          _recurrenceEndDate = _event!.recurrenceRule!.until!;
        }

        _isByDayOfMonth = _event?.recurrenceRule?.byMonthDays == null;
        _daysOfWeek = _event?.recurrenceRule?.byWeekDays ?? <ByWeekDayEntry>{};
        _monthOfYear = _event?.recurrenceRule?.byMonths ?? {};
        _weekOfMonth = _event?.recurrenceRule?.byWeeks ?? {};
        _selectedDayOfWeek = _daysOfWeek.isNotEmpty
            ? DayOfWeek.values[_daysOfWeek.first.day]
            : DayOfWeek.Monday;

        if (_daysOfWeek.isNotEmpty) {
          _updateDaysOfWeekGroup();
        }
      }

      _availability = _event!.availability;
    }

    _startTime = TimeOfDay(hour: _startDate!.hour, minute: _startDate!.minute);
    _endTime = TimeOfDay(hour: _endDate!.hour, minute: _endDate!.minute);

    // Getting days of the current month (or a selected month for the yearly recurrence) as a default
    _getValidDaysOfMonth(_recurrenceFrequency);
    setState(() {});
  }

  void printAttendeeDetails(Attendee attendee) {
    debugPrint(
        'attendee name: ${attendee.name}, email address: ${attendee.emailAddress}, type: ${attendee.role?.enumToString}');
    debugPrint(
        'ios specifics - status: ${attendee.iosAttendeeDetails?.attendanceStatus}, type: ${attendee.iosAttendeeDetails?.attendanceStatus?.enumToString}');
    debugPrint(
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
                      if (_event?.allDay == false) ...[
                        if (Platform.isAndroid)
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
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: DateTimePicker(
                            labelText: 'To',
                            selectedDate: _endDate,
                            selectedTime: _endTime,
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
                      ],
                      GestureDetector(
                        onTap: () async {
                          var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EventAttendeePage()));
                          if (result == null) return;
                          _attendees.add(result);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10.0,
                              children: [
                                const Icon(Icons.people),
                                Text(_calendar.isReadOnly == false
                                    ? 'Add Attendees'
                                    : 'Attendees')
                              ],
                            ),
                          ),
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _attendees.length,
                        itemBuilder: (context, index) {
                          return Container(
                            color: _attendees[index].isOrganiser
                                ? Colors.greenAccent[100]
                                : Colors.transparent,
                            child: ListTile(
                              title: GestureDetector(
                                onTap: () async {
                                  var result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EventAttendeePage(
                                                  attendee:
                                                      _attendees[index])));
                                  if (result == null) return;
                                  _attendees[index] = result;
                                },
                                child:
                                    Text('${_attendees[index].emailAddress}'),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    margin: const EdgeInsets.all(10.0),
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
                            items: [
                              // RecurrenceFrequency.secondly,
                              // RecurrenceFrequency.minutely,
                              // RecurrenceFrequency.hourly,
                              RecurrenceFrequency.daily,
                              RecurrenceFrequency.weekly,
                              RecurrenceFrequency.monthly,
                              RecurrenceFrequency.yearly,
                            ]
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
                            RecurrenceFrequency.weekly) ...[
                          Column(
                            children: [
                              ...DayOfWeek.values.map((day) {
                                return CheckboxListTile(
                                  title: Text(day.enumToString),
                                  value: _daysOfWeek.any((dow) =>
                                      dow == ByWeekDayEntry(day.index + 1)),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _daysOfWeek
                                            .add(ByWeekDayEntry(day.index + 1));
                                      } else {
                                        _daysOfWeek.remove(
                                            ByWeekDayEntry(day.index + 1));
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
                                RecurrenceFrequency.monthly ||
                            _recurrenceFrequency ==
                                RecurrenceFrequency.yearly) ...[
                          SwitchListTile(
                            value: _isByDayOfMonth,
                            onChanged: (value) =>
                                setState(() => _isByDayOfMonth = value),
                            title: const Text('By day of the month'),
                          )
                        ],
                        if (_recurrenceFrequency ==
                                RecurrenceFrequency.yearly &&
                            _isByDayOfMonth) ...[
                          ListTile(
                            leading: const Text('Month of the year'),
                            trailing: DropdownButton<MonthOfYear>(
                              onChanged: (value) {
                                setState(() {
                                  if (value?.index != null) {
                                    debugPrint(
                                        "Selected Month = ${value?.index}");
                                    int month = value!.index + 1;
                                    _monthOfYear = {month};
                                  }
                                  // _monthOfYear = {value?.index ?? 1};
                                  _getValidDaysOfMonth(_recurrenceFrequency);
                                });
                              },
                              value: MonthOfYear.values.toList()[
                                  _monthOfYear.isEmpty
                                      ? 0
                                      : _monthOfYear.first - 1],
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
                                    RecurrenceFrequency.monthly ||
                                _recurrenceFrequency ==
                                    RecurrenceFrequency.yearly)) ...[
                          ListTile(
                            leading: const Text('Day of the month'),
                            trailing: DropdownButton<int>(
                              onChanged: (value) {
                                setState(() {
                                  if (value != null) {
                                    _dayOfMonth = {value};
                                  }
                                });
                              },
                              value: /*_dayOfMonth.isEmpty ? 1 : */ _dayOfMonth
                                      .firstOrNull ??
                                  1,
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
                                    RecurrenceFrequency.monthly ||
                                _recurrenceFrequency ==
                                    RecurrenceFrequency.yearly)) ...[
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
                                        _weekOfMonth = {value?.index ?? 1};
                                      });
                                    },
                                    value: WeekNumber.values.toList()[
                                        _weekOfMonth.isNotEmpty
                                            ? _weekOfMonth.first
                                            : 0],
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
                                    RecurrenceFrequency.yearly) ...[
                                  const Text('of'),
                                  Flexible(
                                    child: DropdownButton<MonthOfYear>(
                                      onChanged: (value) {
                                        setState(() {
                                          if (value?.index != null) {
                                            int month = value!.index;
                                            _monthOfYear = {month};
                                          }
                                        });
                                      },
                                      value: MonthOfYear.values.toList()[
                                          _monthOfYear.isNotEmpty
                                              ? _monthOfYear.first
                                              : 0],
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
                      ...[
                        //TODO: on iPhone (e.g. 8) this seems neccesary to be able to access UI below the FAB
                        const SizedBox(height: 75),
                      ]
                    ],
                  ),
                ),
                if (_calendar.isReadOnly == false &&
                    (_event?.eventId?.isNotEmpty ?? false)) ...[
                  ElevatedButton(
                    key: const Key('deleteEventButton'),
                    style: ElevatedButton.styleFrom(
                        primary: Colors.red, onPrimary: Colors.white),
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
                                  : const SizedBox.shrink();
                            });
                      }

                      if (result == true) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ],
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
              showInSnackBar(
                  context, 'Please fix the errors in red before submitting.');
            } else {
              form?.save();
              if (_isRecurringEvent) {
                if (!_isByDayOfMonth &&
                    (_recurrenceFrequency == RecurrenceFrequency.monthly ||
                        _recurrenceFrequency == RecurrenceFrequency.yearly)) {
                  _daysOfWeek.clear();
                  if (_selectedDayOfWeek != null) {
                    int? weekNo = _weekOfMonth.firstOrNull;
                    if (weekNo != null) {
                      weekNo += 1;
                    }
                    _weekOfMonth.clear();
                    int? monthOfYear = _monthOfYear.firstOrNull;
                    if (monthOfYear != null) {
                      _monthOfYear = {monthOfYear += 1};
                    }

                    _daysOfWeek.add(
                        ByWeekDayEntry(_selectedDayOfWeek!.index + 1, weekNo));

                    if (_recurrenceFrequency == RecurrenceFrequency.yearly) {
                      _dayOfMonth.clear();
                    }
                  }
                }
                var finalRecRule = RecurrenceRule(
                    recurrenceFrequency: _recurrenceFrequency!,
                    interval: _interval,
                    count: (_recurrenceRuleEndType ==
                            RecurrenceRuleEndType.MaxOccurrences)
                        ? _totalOccurrences
                        : null,
                    until: _recurrenceRuleEndType ==
                            RecurrenceRuleEndType.SpecifiedEndDate
                        ? _recurrenceEndDate.toUtc()
                        : null,
                    byWeekDays: _daysOfWeek,
                    byMonthDays: _dayOfMonth,
                    byMonths: _monthOfYear,
                    byWeeks: _weekOfMonth);
                _event?.recurrenceRule = finalRecRule;

                var dateInstances =
                    finalRecRule.getInstances(start: DateTime.now().toUtc());

                var realStartDate =
                    _recurrenceFrequency == RecurrenceFrequency.daily
                        ? DateTime.now()
                        : dateInstances.firstOrNull;

                if (realStartDate != null) {
                  var currentLocation = timeZoneDatabase.locations[_timezone];
                  var fallbackLocation = timeZoneDatabase.locations['Etc/UTC'];
                  _event?.start = TZDateTime.from(
                      DateTime(
                          realStartDate.year,
                          realStartDate.month,
                          realStartDate.day,
                          _event?.start?.hour ?? 0,
                          _event?.start?.minute ?? 0),
                      currentLocation ?? fallbackLocation!);
                  _event?.end = TZDateTime.from(
                      DateTime(
                          realStartDate.year,
                          realStartDate.month,
                          realStartDate.day,
                          _event?.end?.hour ?? 0,
                          _event?.end?.minute ?? 0),
                      currentLocation ?? fallbackLocation!);
                }
              }

              _event?.attendees = _attendees;
              _event?.reminders = _reminders;
              _event?.availability = _availability;
              var createEventResult =
                  await _deviceCalendarPlugin.createOrUpdateEvent(_event);
              if (createEventResult?.isSuccess == true) {
                Navigator.pop(context, true);
              } else {
                showInSnackBar(
                    context,
                    createEventResult?.errors
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
    if (recurrenceFrequency == RecurrenceFrequency.daily) {
      return const Text('Daily');
    } else if (recurrenceFrequency == RecurrenceFrequency.weekly) {
      return const Text('Weekly');
    } else if (recurrenceFrequency == RecurrenceFrequency.monthly) {
      return const Text('Monthly');
    } else if (recurrenceFrequency == RecurrenceFrequency.yearly) {
      return const Text('Yearly');
    } else {
      return const Text('');
    }
  }

  Text _recurrenceFrequencyToIntervalText(
      RecurrenceFrequency? recurrenceFrequency) {
    if (recurrenceFrequency == RecurrenceFrequency.daily) {
      return const Text(' Day(s)');
    } else if (recurrenceFrequency == RecurrenceFrequency.weekly) {
      return const Text(' Week(s) on');
    } else if (recurrenceFrequency == RecurrenceFrequency.monthly) {
      return const Text(' Month(s)');
    } else if (recurrenceFrequency == RecurrenceFrequency.yearly) {
      return const Text(' Year(s)');
    } else {
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
    if (frequency == RecurrenceFrequency.yearly) {
      totalDays = DateTime(DateTime.now().year,
              _monthOfYear.isNotEmpty ? _monthOfYear.first : 1, 0)
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
    switch (_dayOfWeekGroup) {
      case DayOfWeekGroup.Weekday:
        _daysOfWeek.clear();
        _daysOfWeek.addAll([
          ByWeekDayEntry(1),
          ByWeekDayEntry(2),
          ByWeekDayEntry(3),
          ByWeekDayEntry(4),
          ByWeekDayEntry(5),
        ]);
        break;
      case DayOfWeekGroup.Weekend:
        _daysOfWeek.clear();
        _daysOfWeek.addAll([
          ByWeekDayEntry(6),
          ByWeekDayEntry(7),
        ]);
        break;
      case DayOfWeekGroup.AllDays:
        _daysOfWeek.clear();
        _daysOfWeek.addAll([
          ByWeekDayEntry(1),
          ByWeekDayEntry(2),
          ByWeekDayEntry(3),
          ByWeekDayEntry(4),
          ByWeekDayEntry(5),
          ByWeekDayEntry(6),
          ByWeekDayEntry(7),
        ]);
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

    return dateWithoutTime
        .add(Duration(hours: time.hour, minutes: time.minute));
  }

  void showInSnackBar(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

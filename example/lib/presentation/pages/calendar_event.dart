import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import '../color_picker_dialog.dart';
import '../date_time_picker.dart';
import '../recurring_event_dialog.dart';
import 'event_attendee.dart';
import 'event_reminders.dart';

enum RecurrenceRuleEndType { Indefinite, MaxOccurrences, SpecifiedEndDate }

class CalendarEventPage extends StatefulWidget {
  final Calendar _calendar;
  final Event? _event;
  final RecurringEventDialog? _recurringEventDialog;
  final List<EventColor>? _eventColors;

  const CalendarEventPage(this._calendar,
      [this._event, this._recurringEventDialog, this._eventColors, Key? key])
      : super(key: key);

  @override
  _CalendarEventPageState createState() {
    return _CalendarEventPageState(_calendar, _event, _recurringEventDialog, _eventColors);
  }
}

class _CalendarEventPageState extends State<CalendarEventPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Calendar _calendar;

  Event? _event;
  late final DeviceCalendarPlugin _deviceCalendarPlugin;
  final RecurringEventDialog? _recurringEventDialog;

  DateTime get nowDate => DateTime.now();

  // TimeOfDay get nowTime => TimeOfDay(hour: nowDate.hour, minute: nowDate.hour);

  TZDateTime? _startDate;
  TimeOfDay? _startTime;

  TZDateTime? _endDate;
  TimeOfDay? _endTime;

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  DayOfWeekGroup _dayOfWeekGroup = DayOfWeekGroup.None;

  RecurrenceRuleEndType _recurrenceRuleEndType =
      RecurrenceRuleEndType.Indefinite;
  RecurrenceRule? _rrule;

  final List<int> _validDaysOfMonth = [];

  Availability _availability = Availability.Busy;
  EventStatus? _eventStatus;
  List<Attendee>? _attendees;
  List<Reminder>? _reminders;
  List<EventColor>? _eventColors;
  String _timezone = 'Etc/UTC';

  _CalendarEventPageState(
      this._calendar, this._event, this._recurringEventDialog, this._eventColors) {
    getCurentLocation();
  }

  void getCurentLocation() async {
    try {
      _timezone = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      debugPrint('Could not get the local timezone');
    }

    _deviceCalendarPlugin = DeviceCalendarPlugin();

    final event = _event;
    if (event == null) {
      debugPrint(
          'calendar_event _timezone ------------------------- $_timezone');
      final currentLocation = timeZoneDatabase.locations[_timezone];
      if (currentLocation != null) {
        final now = TZDateTime.now(currentLocation);
        _startDate = now;
        _startTime = TimeOfDay(hour: now.hour, minute: now.minute);
        final oneHourLater = now.add(const Duration(hours: 1));
        _endDate = oneHourLater;
        _endTime =
            TimeOfDay(hour: oneHourLater.hour, minute: oneHourLater.minute);
      } else {
        var fallbackLocation = timeZoneDatabase.locations['Etc/UTC'];
        final now = TZDateTime.now(fallbackLocation!);
        _startDate = now;
        _startTime = TimeOfDay(hour: now.hour, minute: now.minute);
        final oneHourLater = now.add(const Duration(hours: 1));
        _endDate = oneHourLater;
        _endTime =
            TimeOfDay(hour: oneHourLater.hour, minute: oneHourLater.minute);
      }
      _event = Event(_calendar.id,
          start: _startDate, end: _endDate, availability: _availability);

      debugPrint('DeviceCalendarPlugin calendar id is: ${_calendar.id}');

      _eventStatus = EventStatus.None;
    } else {
      final start = event.start;
      final end = event.end;
      if (start != null && end != null) {
        _startDate = start;
        _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
        _endDate = end;
        _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
      }

      final attendees = event.attendees;
      if (attendees != null && attendees.isNotEmpty) {
        _attendees = <Attendee>[];
        _attendees?.addAll(attendees as Iterable<Attendee>);
      }

      final reminders = event.reminders;
      if (reminders != null && reminders.isNotEmpty) {
        _reminders = <Reminder>[];
        _reminders?.addAll(reminders);
      }

      final rrule = event.recurrenceRule;
      if (rrule != null) {
        // debugPrint('OLD_RRULE: ${rrule.toString()}');
        _rrule = rrule;
        if (rrule.count != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.MaxOccurrences;
        }
        if (rrule.until != null) {
          _recurrenceRuleEndType = RecurrenceRuleEndType.SpecifiedEndDate;
        }
      }

      _availability = event.availability;
      _eventStatus = event.status;
    }

    // Getting days of the current month (or a selected month for the yearly recurrence) as a default
    _getValidDaysOfMonth(_rrule?.frequency);
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
                      if (_eventColors?.isNotEmpty ?? false)
                        ListTile(
                          leading: const Text(
                            'EventColor',
                            style: TextStyle(fontSize: 16),
                          ),
                          trailing: widget._event?.color == null ? const Text("not set") :  Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(widget._event?.color ?? 0),
                              )),
                          onTap: () async {
                            if (_eventColors != null) {
                              final colors = _eventColors?.map((eventColor) => Color(eventColor.color)).toList();
                              final newColor = await ColorPickerDialog.selectColorDialog(colors ?? [], context);
                              setState(() {
                                _event?.updateEventColor(_eventColors?.firstWhereOrNull((eventColor) => Color(eventColor.color).value == newColor?.value));
                              });
                            }
                          },
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
                                  _attendees ??= [];
                                  setState(() {
                                    _attendees?.add(result);
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
                        itemCount: _attendees?.length ?? 0,
                        itemBuilder: (context, index) {
                          return Container(
                            color: (_attendees?[index].isOrganiser ?? false)
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
                                            attendee: _attendees?[index],
                                            eventId: _event?.eventId)));
                                if (result != null) {
                                  return setState(() {
                                    _attendees?[index] = result;
                                  });
                                }
                              },
                              title: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                    '${_attendees?[index].name} (${_attendees?[index].emailAddress})'),
                              ),
                              subtitle: Wrap(
                                spacing: 10,
                                direction: Axis.horizontal,
                                alignment: WrapAlignment.end,
                                children: <Widget>[
                                  Visibility(
                                    visible: _attendees?[index]
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
                                            'Android: ${_attendees?[index].androidAttendeeDetails?.attendanceStatus?.enumToString}')),
                                  ),
                                  Visibility(
                                    visible:
                                        _attendees?[index].iosAttendeeDetails !=
                                            null,
                                    child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        padding: const EdgeInsets.all(3.0),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.blueAccent)),
                                        child: Text(
                                            'iOS: ${_attendees?[index].iosAttendeeDetails?.attendanceStatus?.enumToString}')),
                                  ),
                                  Visibility(
                                      visible:
                                          _attendees?[index].isCurrentUser ??
                                              false,
                                      child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10.0),
                                          padding: const EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.blueAccent)),
                                          child: const Text('current user'))),
                                  Visibility(
                                      visible: _attendees?[index].isOrganiser ??
                                          false,
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
                                        '${_attendees?[index].role?.enumToString}'),
                                  ),
                                  IconButton(
                                    padding: const EdgeInsets.all(0),
                                    onPressed: () {
                                      setState(() {
                                        _attendees?.removeAt(index);
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
                                      EventRemindersPage(_reminders ?? [])));
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
                                if (_reminders?.isEmpty ?? true)
                                  Text(_calendar.isReadOnly == false
                                      ? 'Add reminders'
                                      : 'Reminders'),
                                for (var reminder in _reminders ?? [])
                                  Text('${reminder.minutes} minutes before; ')
                              ],
                            ),
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        value: _rrule != null,
                        title: const Text('Is recurring'),
                        onChanged: (isChecked) {
                          if (isChecked != null) {
                            setState(() {
                              if (isChecked) {
                                _rrule =
                                    RecurrenceRule(frequency: Frequency.daily);
                              } else {
                                _rrule = null;
                              }
                            });
                          }
                        },
                      ),
                      if (_rrule != null) ...[
                        ListTile(
                          leading: const Text('Select a Recurrence Type'),
                          trailing: DropdownButton<Frequency>(
                            onChanged: (selectedFrequency) {
                              setState(() {
                                _onFrequencyChange(
                                    selectedFrequency ?? Frequency.daily);
                                _getValidDaysOfMonth(selectedFrequency);
                              });
                            },
                            value: _rrule?.frequency,
                            items: [
                              // Frequency.secondly,
                              // Frequency.minutely,
                              // Frequency.hourly,
                              Frequency.daily,
                              Frequency.weekly,
                              Frequency.monthly,
                              Frequency.yearly,
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
                                  initialValue: '${_rrule?.interval ?? 1}',
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
                                      _rrule = _rrule?.copyWith(
                                          interval: int.tryParse(value));
                                    }
                                  },
                                ),
                              ),
                              _recurrenceFrequencyToIntervalText(
                                  _rrule?.frequency),
                            ],
                          ),
                        ),
                        if (_rrule?.frequency == Frequency.weekly) ...[
                          Column(
                            children: [
                              ...DayOfWeek.values.map((day) {
                                return CheckboxListTile(
                                  title: Text(day.enumToString),
                                  value: _rrule?.byWeekDays
                                      .contains(ByWeekDayEntry(day.index + 1)),
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _rrule?.byWeekDays
                                            .add(ByWeekDayEntry(day.index + 1));
                                      } else {
                                        _rrule?.byWeekDays.remove(
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
                                    onChanged: (DayOfWeekGroup? selected) {
                                      if (selected != null) {
                                        setState(() {
                                          _dayOfWeekGroup = selected;
                                          _updateDaysOfWeek();
                                        });
                                      }
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.trailing);
                              }),
                            ],
                          )
                        ],
                        if (_rrule?.frequency == Frequency.monthly ||
                            _rrule?.frequency == Frequency.yearly) ...[
                          SwitchListTile(
                            value: _rrule?.hasByMonthDays ?? false,
                            onChanged: (value) {
                              setState(() {
                                if (value) {
                                  _rrule = _rrule?.copyWith(
                                      byMonthDays: [1], byWeekDays: []);
                                } else {
                                  _rrule = _rrule?.copyWith(
                                      byMonthDays: [],
                                      byWeekDays: [ByWeekDayEntry(1, 1)]);
                                }
                              });
                            },
                            title: const Text('By day of the month'),
                          )
                        ],
                        if (_rrule?.frequency == Frequency.yearly &&
                            (_rrule?.hasByMonthDays ?? false)) ...[
                          ListTile(
                            leading: const Text('Month of the year'),
                            trailing: DropdownButton<MonthOfYear>(
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _rrule = _rrule
                                        ?.copyWith(byMonths: [value.index + 1]);
                                    _getValidDaysOfMonth(_rrule?.frequency);
                                  });
                                }
                              },
                              value: MonthOfYear.values.toList()[
                                  (_rrule?.hasByMonths ?? false)
                                      ? _rrule!.byMonths.first - 1
                                      : 0],
                              items: MonthOfYear.values
                                  .map((month) => DropdownMenuItem(
                                        value: month,
                                        child: Text(month.enumToString),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                        if ((_rrule?.hasByMonthDays ?? false) &&
                            (_rrule?.frequency == Frequency.monthly ||
                                _rrule?.frequency == Frequency.yearly)) ...[
                          ListTile(
                            leading: const Text('Day of the month'),
                            trailing: DropdownButton<int>(
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _rrule =
                                        _rrule?.copyWith(byMonthDays: [value]);
                                  });
                                }
                              },
                              value: (_rrule?.hasByMonthDays ?? false)
                                  ? _rrule!.byMonthDays.first
                                  : 1,
                              items: _validDaysOfMonth
                                  .map((day) => DropdownMenuItem(
                                        value: day,
                                        child: Text(day.toString()),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                        if (!(_rrule?.hasByMonthDays ?? false) &&
                            (_rrule?.frequency == Frequency.monthly ||
                                _rrule?.frequency == Frequency.yearly)) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: _recurrenceFrequencyToText(
                                                _rrule?.frequency)
                                            .data !=
                                        null
                                    ? Text(
                                        '${_recurrenceFrequencyToText(_rrule?.frequency).data!} on the ')
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
                                      if (value != null) {
                                        final weekDay =
                                            _rrule?.byWeekDays.first.day ?? 1;
                                        setState(() {
                                          _rrule = _rrule?.copyWith(
                                              byWeekDays: [
                                                ByWeekDayEntry(
                                                    weekDay, value.index + 1)
                                              ]);
                                        });
                                      }
                                    },
                                    value: WeekNumber.values.toList()[
                                        (_rrule?.hasByWeekDays ?? false)
                                            ? _weekNumFromWeekDayOccurence(
                                                _rrule!.byWeekDays)
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
                                      if (value != null) {
                                        final weekNo = _rrule
                                                ?.byWeekDays.first.occurrence ??
                                            1;
                                        setState(() {
                                          _rrule = _rrule?.copyWith(
                                              byWeekDays: [
                                                ByWeekDayEntry(
                                                    value.index + 1, weekNo)
                                              ]);
                                        });
                                      }
                                    },
                                    value: (_rrule?.hasByWeekDays ?? false) &&
                                            _rrule?.byWeekDays.first
                                                    .occurrence !=
                                                null
                                        ? DayOfWeek.values[
                                            _rrule!.byWeekDays.first.day - 1]
                                        : DayOfWeek.values[0],
                                    items: DayOfWeek.values
                                        .map((day) => DropdownMenuItem(
                                              value: day,
                                              child: Text(day.enumToString),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                if (_rrule?.frequency == Frequency.yearly) ...[
                                  const Text('of'),
                                  Flexible(
                                    child: DropdownButton<MonthOfYear>(
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _rrule = _rrule?.copyWith(
                                                byMonths: [value.index + 1]);
                                          });
                                        }
                                      },
                                      value: MonthOfYear.values.toList()[
                                          (_rrule?.hasByMonths ?? false)
                                              ? _rrule!.byMonths.first - 1
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
                                if (value != null) {
                                  _recurrenceRuleEndType = value;
                                }
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
                                    initialValue: '${_rrule?.count ?? 1}',
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
                                        _rrule = _rrule?.copyWith(
                                            count: int.tryParse(value));
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
                              selectedDate: _rrule?.until ?? DateTime.now(),
                              selectDate: (DateTime date) {
                                setState(() {
                                  _rrule = _rrule?.copyWith(
                                      until: DateTime(
                                              date.year,
                                              date.month,
                                              date.day,
                                              _endTime?.hour ?? nowDate.hour,
                                              _endTime?.minute ??
                                                  nowDate.minute)
                                          .toUtc());
                                });
                              },
                            ),
                          ),
                      ],
                      ...[
                        // TODO: on iPhone (e.g. 8) this seems neccesary to be able to access UI below the FAB
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
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red),
                    onPressed: () async {
                      bool? result = true;
                      if (!(_rrule != null)) {
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
              return;
            } else {
              form?.save();
              _adjustStartEnd();
              _event?.recurrenceRule = _rrule;
              // debugPrint('FINAL_RRULE: ${_rrule.toString()}');
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
              showInSnackBar(
                  context,
                  createEventResult?.errors
                      .map((err) => '[${err.errorCode}] ${err.errorMessage}')
                      .join(' | ') as String);
            }
          },
          child: const Icon(Icons.check),
        ),
      ),
    );
  }

  Text _recurrenceFrequencyToText(Frequency? recurrenceFrequency) {
    if (recurrenceFrequency == Frequency.daily) {
      return const Text('Daily');
    } else if (recurrenceFrequency == Frequency.weekly) {
      return const Text('Weekly');
    } else if (recurrenceFrequency == Frequency.monthly) {
      return const Text('Monthly');
    } else if (recurrenceFrequency == Frequency.yearly) {
      return const Text('Yearly');
    } else {
      return const Text('');
    }
  }

  Text _recurrenceFrequencyToIntervalText(Frequency? recurrenceFrequency) {
    if (recurrenceFrequency == Frequency.daily) {
      return const Text(' Day(s)');
    } else if (recurrenceFrequency == Frequency.weekly) {
      return const Text(' Week(s) on');
    } else if (recurrenceFrequency == Frequency.monthly) {
      return const Text(' Month(s)');
    } else if (recurrenceFrequency == Frequency.yearly) {
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
  void _getValidDaysOfMonth(Frequency? frequency) {
    _validDaysOfMonth.clear();
    var totalDays = 0;

    // Year frequency: Get total days of the selected month
    if (frequency == Frequency.yearly) {
      totalDays = DateTime(DateTime.now().year,
              (_rrule?.hasByMonths ?? false) ? _rrule!.byMonths.first : 1, 0)
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
    switch (_dayOfWeekGroup) {
      case DayOfWeekGroup.Weekday:
        _rrule = _rrule?.copyWith(byWeekDays: [
          ByWeekDayEntry(1),
          ByWeekDayEntry(2),
          ByWeekDayEntry(3),
          ByWeekDayEntry(4),
          ByWeekDayEntry(5),
        ]);
        break;
      case DayOfWeekGroup.Weekend:
        _rrule = _rrule?.copyWith(byWeekDays: [
          ByWeekDayEntry(6),
          ByWeekDayEntry(7),
        ]);
        break;
      case DayOfWeekGroup.AllDays:
        _rrule = _rrule?.copyWith(byWeekDays: [
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
      default:
        _rrule?.byWeekDays.clear();
        break;
    }
    // () => setState(() => {});
  }

  void _updateDaysOfWeekGroup({DayOfWeek? selectedDay}) {
    final byWeekDays = _rrule?.byWeekDays;
    if (byWeekDays != null) {
      if (byWeekDays.length == 7 &&
          byWeekDays.every((p0) =>
              p0.day == 1 ||
              p0.day == 2 ||
              p0.day == 3 ||
              p0.day == 4 ||
              p0.day == 5 ||
              p0.day == 6 ||
              p0.day == 7)) {
        _dayOfWeekGroup = DayOfWeekGroup.AllDays;
      } else if (byWeekDays.length == 5 &&
          byWeekDays.every((p0) =>
              p0.day == 1 ||
              p0.day == 2 ||
              p0.day == 3 ||
              p0.day == 4 ||
              p0.day == 5) &&
          byWeekDays.none((p0) => p0.day == 6 || p0.day == 7)) {
        _dayOfWeekGroup = DayOfWeekGroup.Weekday;
      } else if (byWeekDays.length == 2 &&
          byWeekDays.every((p0) => p0.day == 6 || p0.day == 7) &&
          byWeekDays.none((p0) =>
              p0.day == 1 ||
              p0.day == 2 ||
              p0.day == 3 ||
              p0.day == 4 ||
              p0.day == 5)) {
        _dayOfWeekGroup = DayOfWeekGroup.Weekend;
      } else {
        _dayOfWeekGroup = DayOfWeekGroup.None;
      }
    }
  }

  int _weekNumFromWeekDayOccurence(List<ByWeekDayEntry> weekdays) {
    final weekNum = weekdays.first.occurrence;
    if (weekNum != null) {
      return weekNum - 1;
    } else {
      return 0;
    }
  }

  void _onFrequencyChange(Frequency freq) {
    final rrule = _rrule;
    if (rrule != null) {
      final hasByWeekDays = rrule.hasByWeekDays;
      final hasByMonthDays = rrule.hasByMonthDays;
      final hasByMonths = rrule.hasByMonths;
      if (freq == Frequency.daily || freq == Frequency.weekly) {
        if (hasByWeekDays) {
          rrule.byWeekDays.clear();
        }
        if (hasByMonths) {
          rrule.byMonths.clear();
        }
        _rrule = rrule.copyWith(frequency: freq);
      }
      if (freq == Frequency.monthly) {
        if (hasByMonths) {
          rrule.byMonths.clear();
        }
        if (!hasByWeekDays && !hasByMonthDays) {
          _rrule = rrule
              .copyWith(frequency: freq, byWeekDays: [ByWeekDayEntry(1, 1)]);
        } else {
          _rrule = rrule.copyWith(frequency: freq);
        }
      }
      if (freq == Frequency.yearly) {
        if (!hasByWeekDays || !hasByMonths) {
          _rrule = rrule.copyWith(
              frequency: freq,
              byWeekDays: [ByWeekDayEntry(1, 1)],
              byMonths: [1]);
        } else {
          _rrule = rrule.copyWith(frequency: freq);
        }
      }
    }
  }

  /// In order to avoid an event instance to appear outside of the recurrence
  /// rrule, the start and end date have to be adjusted to match the first
  /// instance.
  void _adjustStartEnd() {
    final start = _event?.start;
    final end = _event?.end;
    final rrule = _rrule;
    if (start != null && end != null && rrule != null) {
      final allDay = _event?.allDay ?? false;
      final duration = end.difference(start);
      final instances = rrule.getAllInstances(
          start: allDay
              ? DateTime.utc(start.year, start.month, start.day)
              : DateTime(start.year, start.month, start.day, start.hour,
                      start.minute)
                  .toUtc(),
          before: rrule.count == null && rrule.until == null
              ? DateTime(start.year + 2, start.month, start.day, start.hour,
                      start.minute)
                  .toUtc()
              : null);
      if (instances.isNotEmpty) {
        var newStart = TZDateTime.from(instances.first, start.location);
        var newEnd = newStart.add(duration);
        _event?.start = newStart;
        _event?.end = newEnd;
      }
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

  void showInSnackBar(BuildContext context, String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

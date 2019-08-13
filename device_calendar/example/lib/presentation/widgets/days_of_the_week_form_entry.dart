import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';

class DaysOfTheWeekFormEntry extends StatefulWidget {
  final List<DayOfTheWeek> daysOfTheWeek;
  const DaysOfTheWeekFormEntry({@required this.daysOfTheWeek, Key key})
      : super(key: key);

  @override
  _DaysOfTheWeekFormEntryState createState() => _DaysOfTheWeekFormEntryState();
}

class _DaysOfTheWeekFormEntryState extends State<DaysOfTheWeekFormEntry> {
  Text _dayOfWeekToText(DayOfTheWeek dayOfWeek) {
    switch (dayOfWeek) {
      case DayOfTheWeek.Sunday:
        return Text('Sunday');
      case DayOfTheWeek.Monday:
        return Text('Monday');
      case DayOfTheWeek.Tuesday:
        return Text('Tuesday');
      case DayOfTheWeek.Wednesday:
        return Text('Wednesday');
      case DayOfTheWeek.Thursday:
        return Text('Thursday');
      case DayOfTheWeek.Friday:
        return Text('Friday');
      case DayOfTheWeek.Saturday:
        return Text('Saturday');
      default:
        return Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Text('Days of the week'),
        ),
        ...DayOfTheWeek.values.map(
          (d) {
            return CheckboxListTile(
              title: _dayOfWeekToText(d),
              value: widget.daysOfTheWeek?.any((dow) => dow == d) ?? false,
              onChanged: (selected) {
                setState(
                  () {
                    if (selected) {
                      widget.daysOfTheWeek.add(d);
                    } else {
                      widget.daysOfTheWeek.remove(d);
                    }
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

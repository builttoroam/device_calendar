# Examples

Most of the APIs are covered in [calendar_event.dart](https://github.com/builttoroam/device_calendar/blob/master/example/lib/presentation/pages/calendar_event.dart) or [calendar_events.dart](https://github.com/builttoroam/device_calendar/blob/master/example/lib/presentation/pages/calendar_events.dart) files in the example app.
You'll be able to get a reference of how the APIs are used.

For a full API reference, the documentation can be found at [pub.dev](https://pub.dev/documentation/device_calendar/latest/device_calendar/device_calendar-library.html).

## DayOfWeekGroup Enum

`DayOfWeekGroup` enum allows to explicitly choose and return a list of `DayOfWeek` enum values by using an extension `getDays`:

* `DayOfWeekGroup.Weekday.getDays` will return:

    ```dart
    [DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday];
    ```

* `DayOfWeekGroup.Weekend.getDays` will return:

    ```dart
    [DayOfWeek.Saturday, DayOfWeek.Sunday];
    ```

* `DayOfWeekGroup.Alldays.getDays` will return:

    ```dart
    [DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, DayOfWeek.Thursday, DayOfWeek.Friday, DayOfWeek.Saturday, DayOfWeek.Sunday];
    ```

## Attendee Examples

Examples below present on how to initialise an `Attendee` model in Dart:

* A required attendee:

    ```dart
    Attendee(
        name: 'Test User 1',
        emailAddress: 'test1@example.com',
        role: AttendeeRole.Required);
    ```

* An optional attendee:

    ```dart
    Attendee(
        name: 'Test User 2',
        emailAddress: 'test2@example.com',
        role: AttendeeRole.Optional);
    ```

## Reminder Examples

Examples below present on how to initialise a `Reminder` model in Dart:

* 30 minutes

    ```dart
    Reminder(minutes: 30);
    ```

* 1 day

    ```dart
    Reminder(minutes: 1440);
    ```

## Recurrence Rule Examples

Examples below present sample parameters of recurrence rules received by each platform and required properties for the `RecurrenceRule` model in Dart.\
**Please note**: Receiving monthly and yearly recurrence parameters are slightly different for the two platforms.

You can find more standard examples at [iCalendar.org](https://icalendar.org/iCalendar-RFC-5545/3-8-5-3-recurrence-rule.html).

### **Daily Rule**

Daily every 5 days and end after 3 occurrences

* Recurrence parameter example (Android and iOS):\
`FREQ=DAILY;INTERVAL=5;COUNT=3`
* Dart example:

    ```dart
    RecurrenceRule(
        RecurrenceFrequency.Daily,
        interval: 5,
        totalOccurrences: 3);
    ```

### **Weekly Rule**

Weekly on Monday, Tuesday and Saturday every 2 weeks and end on 31 Jan 2020

* Recurrence parameter example (Android and iOS):\
`FREQ=WEEKLY;BYDAY=MO,TU,SA;INTERVAL=2;UNTIL=20200130T130000Z`
* Dart example:

    ```dart
    RecurrenceRule(
        RecurrenceFrequency.Weekly,
        interval: 2,
        endDate: DateTime(2020, 1, 31),
        daysOfWeek: [ DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Saturday ]);
    ```

### **Monthly/Yearly SetPosition (Week Number) Rule**

Monthly on third Thursday

* Recurrence parameter example (Android):\
`FREQ=MONTHLY;INTERVAL=1;BYDAY=3TH`
* Recurrence parameter example (iOS):\
`FREQ=MONTHLY;INTERVAL=1;BYDAY=TH;BYSETPOS=3`
* Dart example:

    ```dart
    RecurrenceRule(
        RecurrenceFrequency.Monthly,
        interval: 1,
        daysOfWeek: [ DayOfWeek.Thursday ],
        weekOfMonth: WeekNumber.Third);
    ```

Monthly on last Thursday

* Recurrence parameter example (Android and iOS):\
`FREQ=MONTHLY;INTERVAL=1;BYDAY=-1TH`
* Dart example:

    ```dart
    RecurrenceRule(
        RecurrenceFrequency.Monthly,
        interval: 1,
        daysOfWeek: [ DayOfWeek.Thursday ],
        weekOfMonth: WeekNumber.Last);
    ```

Yearly on third Thursday of January

* Recurrence parameter example (Android and iOS):\
`FREQ=YEARLY;INTERVAL=1;BYMONTH=1;BYDAY=3TH`
* Dart example:

    ```dart
    RecurrenceRule(
        RecurrenceFrequency.Yearly,
        interval: 1,
        monthOfYear: MonthOfYear.January,
        weekOfMonth: WeekNumber.Third);
    ```

Yearly on last Thursday of January

* Recurrence parameter example (Android and iOS):\
`FREQ=YEARLY;INTERVAL=1;BYMONTH=1;BYDAY=-1TH`
* Dart example:

    ```dart
    RecurrenceRule(
        RecurrenceFrequency.Yearly,
        interval: 1,
        monthOfYear: MonthOfYear.January,
        weekOfMonth: WeekNumber.Last);
    ```

### **Monthly/Yearly By Day of a Month Rule**

Monthly on 8th

* Recurrence parameter example (Android and iOS):\
`FREQ=YEARLY;INTERVAL=1;BYMONTHDAY=8`
* Dart example:

    ```dart
    RecurrenceRule(
        RecurrenceFrequency.Monthly,
        interval: 1,
        dayOfMonth: 8);
    ```

Yearly on 8th of February

* Recurrence parameter example (Android):\
`FREQ=YEARLY;INTERVAL=1;BYMONTHDAY=8;BYMONTH=2`
* Recurrence parameter example (iOS):\
`FREQ=YEARLY;INTERVAL=1`
* Dart example:

    ```dart
    RecurrenceRule(
        RecurrenceFrequency.Yearly,
        interval: 1,
        monthOfYear: MonthOfYear.February,
        dayOfMonth: 8);
    ```

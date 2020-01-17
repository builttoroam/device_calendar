# device_calendar_example

Demonstrates how to use the device_calendar plugin.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

## Recurrence Rule Parameters

Examples below present sample parameters of recurrence rules received by each platform and required properties for the `RecurrenceRule` model in Dart.\
Please note that receiving monthly and yearly recurrence parameters are slightly different for the two platforms.\
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

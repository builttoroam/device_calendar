# device_calendar_example

Demonstrates how to use the device_calendar plugin.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

## Recurrence Rule Parameters

Examples below present sample parameters for the recurrence rule received by each platform.\
Please note that receiving monthly and yearly recurrence parameters are slightly different for the two platforms.\
You can find more standard examples at [iCalendar.org](https://icalendar.org/iCalendar-RFC-5545/3-8-5-3-recurrence-rule.html).

### **Daliy Rule**

Daliy every 5 days and end after 3 occurrences (Android and iOS)\
`FREQ=DAILY;INTERVAL=5;COUNT=3`

### **Weekly Rule**

Weekly on Monday, Tuesday and Saturday every 2 weeks and end on 31 Jan 2020 (Android and iOS)\
`FREQ=WEEKLY;BYDAY=MO,TU,SA;INTERVAL=2;UNTIL=20200130T130000Z`

### **Monthly/Yearly SetPosition (Week Number) Rule**

Monthly on third Thursday (Android)\
`FREQ=MONTHLY;INTERVAL=1;BYDAY=3TH`

Monthly on third Thursday (iOS)\
`FREQ=MONTHLY;INTERVAL=1;BYDAY=TH;BYSETPOS=3`

Monthly on last Thursday (Android and iOS)\
`FREQ=MONTHLY;INTERVAL=1;BYDAY=-1TH`

Yearly on third Thursday of January (Android and iOS)\
`FREQ=YEARLY;INTERVAL=1;BYMONTH=1;BYDAY=3TH`

Yearly on last Thursday of January (Android and iOS)\
`FREQ=YEARLY;INTERVAL=1;BYMONTH=1;BYDAY=-1TH`

### **Monthly/Yearly By Day of a Month Rule**

Monthly on 8th (Android and iOS)\
`FREQ=YEARLY;INTERVAL=1;BYMONTHDAY=8`

Yearly on 8th of February (Android)\
`FREQ=YEARLY;INTERVAL=1;BYMONTHDAY=8;BYMONTH=2`

Yearly on 8th of February (iOS)\
`FREQ=YEARLY;INTERVAL=1`

import 'package:device_calendar/src/common/day_of_week.dart';

import '../common/error_messages.dart';
import '../common/recurrence_frequency.dart';

class RecurrenceRule {
  int totalOccurrences;

  /// The interval between instances of a recurring event
  int interval;

  /// The date a series of recurring events should end
  DateTime endDate;

  /// The frequency of recurring events
  RecurrenceFrequency recurrenceFrequency;

  /// The days of the week that this event occurs on. Only applicable to rules with a weekly, monthly or yearly frequency
  List<DayOfTheWeek> daysOfTheWeek;

  /// The days of the month that this event occurs on. Only applicable to recurrence rules with a monthly frequency
  List<int> daysOfTheMonth;

  /// The months of the year that the event occurs on. Only applicable to recurrence rules with a yearly frequency
  List<int> monthsOfTheYear;

  final String _totalOccurrencesKey = 'totalOccurrences';
  final String _recurrenceFrequencyKey = 'recurrenceFrequency';
  final String _intervalKey = 'interval';
  final String _endDateKey = 'endDate';
  final String _daysOfTheWeekKey = 'daysOfTheWeek';
  final String _daysOfTheMonthKey = 'daysOfTheMonth';
  final String _monthsOfTheYearKey = 'monthsOfTheYear';

  RecurrenceRule(this.recurrenceFrequency,
      {this.totalOccurrences,
      this.interval,
      this.endDate,
      this.daysOfTheWeek,
      this.daysOfTheMonth,
      this.monthsOfTheYear})
      : assert(!(endDate != null && totalOccurrences != null),
            'Cannot specify both an end date and total occurrences for a recurring event'),
        assert(
            (daysOfTheWeek?.isEmpty ?? true) ||
                ((daysOfTheWeek?.isNotEmpty ?? false) &&
                    (recurrenceFrequency == RecurrenceFrequency.Weekly ||
                        recurrenceFrequency == RecurrenceFrequency.Monthly ||
                        recurrenceFrequency == RecurrenceFrequency.Yearly)),
            'Days of the week can only be specified for recurrence rules with a weekly, monthly or yearly frequency'),
        assert(
            (daysOfTheMonth?.isEmpty ?? true) ||
                ((daysOfTheMonth?.isNotEmpty ?? false) &&
                    recurrenceFrequency == RecurrenceFrequency.Monthly &&
                    (daysOfTheMonth.any((d) => d >= 1 || d <= 31) ||
                        (daysOfTheMonth.any((d) => d >= -31 && d <= -1)))),
            'Days of the month must be between 1 and 31 or -1 and -31 inclusive and can only be specified for recurrence rules with a monthly frequency'),
        assert(
            (monthsOfTheYear?.isEmpty ?? true) ||
                ((monthsOfTheYear?.isNotEmpty ?? false) &&
                    recurrenceFrequency == RecurrenceFrequency.Yearly &&
                    monthsOfTheYear.any((d) => d >= 1 || d <= 12)),
            'Months of the year must be between 1 and 12 inclusive and can only be specified for recurrence rules with a yearly frequency');

  RecurrenceRule.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    int recurrenceFrequencyIndex = json[_recurrenceFrequencyKey];
    if (recurrenceFrequencyIndex == null &&
        recurrenceFrequencyIndex >= RecurrenceFrequency.values.length) {
      throw ArgumentError(ErrorMessages.invalidRecurrencyFrequency);
    }

    recurrenceFrequency = RecurrenceFrequency.values[recurrenceFrequencyIndex];
    totalOccurrences = json[_totalOccurrencesKey];
    interval = json[_intervalKey];
    int endDateMillisecondsSinceEpoch = json[_endDateKey];
    if (endDateMillisecondsSinceEpoch != null) {
      endDate =
          DateTime.fromMillisecondsSinceEpoch(endDateMillisecondsSinceEpoch);
    }
    List<Object> daysOfTheWeekIndices = json[_daysOfTheWeekKey];
    if (daysOfTheWeekIndices != null && daysOfTheWeekIndices is! List<int>) {
      daysOfTheWeek = daysOfTheWeekIndices
          .cast<int>()
          .map((index) => DayOfTheWeek.values[index])
          .toList();
    }
    List<Object> daysOfTheMonthObj = json[_daysOfTheMonthKey];
    if (daysOfTheMonthObj != null && daysOfTheMonthObj is! List<int>) {
      daysOfTheMonth = daysOfTheMonthObj.cast<int>().toList();
    }
    List<Object> monthsOfTheYearObj = json[_monthsOfTheYearKey];
    if (monthsOfTheYearObj != null && monthsOfTheYearObj is! List<int>) {
      monthsOfTheYear = monthsOfTheYearObj.cast<int>().toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data[_recurrenceFrequencyKey] = recurrenceFrequency.index;
    if (interval != null) {
      data[_intervalKey] = interval;
    }
    if (totalOccurrences != null) {
      data[_totalOccurrencesKey] = totalOccurrences;
    }
    if (endDate != null) {
      data[_endDateKey] = endDate.millisecondsSinceEpoch;
    }
    if (daysOfTheWeek != null) {
      data[_daysOfTheWeekKey] = daysOfTheWeek.map((d) => d.index).toList();
    }
    if (daysOfTheMonth != null) {
      data[_daysOfTheMonthKey] = daysOfTheMonth;
    }
    if (monthsOfTheYear != null) {
      data[_monthsOfTheYearKey] = monthsOfTheYear;
    }
    return data;
  }
}

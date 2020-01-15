import 'package:device_calendar/src/common/calendar_enums.dart';

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

  /// The days of the week that this event occurs on. Only applicable to recurrence rules with a weekly, monthly or yearly frequency
  List<DayOfTheWeek> daysOfTheWeek;

  /// The days of the month that this event occurs on. Only applicable to recurrence rules with a monthly or yearly frequency
  List<int> daysOfTheMonth;

  /// The months of the year that the event occurs on. Only applicable to recurrence rules with a yearly frequency
  List<int> monthsOfTheYear;

  /// Filters which recurrences to include in the recurrence rule’s frequency. Only applicable when _isByDayOfMonth is false
  List<int> setPositions;

  final String _totalOccurrencesKey = 'totalOccurrences';
  final String _recurrenceFrequencyKey = 'recurrenceFrequency';
  final String _intervalKey = 'interval';
  final String _endDateKey = 'endDate';
  final String _daysOfTheWeekKey = 'daysOfTheWeek';
  final String _daysOfTheMonthKey = 'daysOfTheMonth';
  final String _monthsOfTheYearKey = 'monthsOfTheYear';
  final String _setPositionsKey = 'setPositions';

  RecurrenceRule(this.recurrenceFrequency,
      {this.totalOccurrences,
      this.interval,
      this.endDate,
      this.daysOfTheWeek,
      this.daysOfTheMonth,
      this.monthsOfTheYear,
      this.setPositions})
      : assert(!(endDate != null && totalOccurrences != null),
          'Cannot specify both an end date and total occurrences for a recurring event');

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
          .map((index) => index.getWeekEnumValue)
          .toList();
    }
    daysOfTheMonth = convertToIntList(json[_daysOfTheMonthKey]);
    monthsOfTheYear = convertToIntList(json[_monthsOfTheYearKey]);
    setPositions = convertToIntList(json[_setPositionsKey]);
  }

  List<int> convertToIntList(List<Object> objList) {
    if (objList != null && objList is! List<int>) {
      return objList.cast<int>().toList();
    }
    return null;
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
      data[_daysOfTheWeekKey] = daysOfTheWeek.map((d) => d.value).toList();
    }
    if (monthsOfTheYear != null) {
      data[_monthsOfTheYearKey] = monthsOfTheYear;
    }

    if (setPositions?.isEmpty == false && (recurrenceFrequency == RecurrenceFrequency.Monthly || recurrenceFrequency == RecurrenceFrequency.Yearly)) {
      data[_setPositionsKey] = setPositions;
    }
    else { // Days of the month should not be added to the recurrence parameter when SetPos is used
      if (daysOfTheMonth != null) {
        data[_daysOfTheMonthKey] = daysOfTheMonth;
      }
    }
    return data;
  }
}

part of device_calendar;

class RecurrenceRule {
  int totalOccurrences;
  int interval;
  DateTime endDate;
  RecurrencyFrequency recurrenceFrequency;
  final String _totalOccurrencesKey = 'totalOccurrences';
  final String _recurrenceFrequencyKey = 'recurrenceFrequency';
  final String _intervalKey = 'interval';
  final String _endDateKey = 'endDate';

  RecurrenceRule(
    this.recurrenceFrequency, {
    this.totalOccurrences,
    this.interval,
    this.endDate,
  });

  RecurrenceRule.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw new ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    int recurrenceFrequencyIndex = json[_recurrenceFrequencyKey];
    if (recurrenceFrequencyIndex == null &&
        recurrenceFrequencyIndex >= RecurrencyFrequency.values.length) {
      throw new ArgumentError(ErrorMessages.invalidRecurrencyFrequency);
    }

    recurrenceFrequency = RecurrencyFrequency.values[recurrenceFrequencyIndex];
    totalOccurrences = json[_totalOccurrencesKey];
    interval = json[_intervalKey];
    int endDateMillisecondsSinceEpoch = json[_endDateKey];
    if (endDateMillisecondsSinceEpoch != null) {
      endDate =
          DateTime.fromMillisecondsSinceEpoch(endDateMillisecondsSinceEpoch);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data[_recurrenceFrequencyKey] = recurrenceFrequency.index;
    data[_intervalKey] = interval;
    data[_totalOccurrencesKey] = totalOccurrences;
    data[_endDateKey] = endDate.millisecondsSinceEpoch;
    return data;
  }
}

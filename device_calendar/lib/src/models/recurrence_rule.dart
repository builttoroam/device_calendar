import '../common/error_messages.dart';
import '../common/recurrence_frequency.dart';

class RecurrenceRule {
  int totalOccurrences;
  int interval;
  DateTime endDate;
  RecurrenceFrequency recurrenceFrequency;
  final String _totalOccurrencesKey = 'totalOccurrences';
  final String _recurrenceFrequencyKey = 'recurrenceFrequency';
  final String _intervalKey = 'interval';
  final String _endDateKey = 'endDate';

  RecurrenceRule(
    this.recurrenceFrequency, {
    this.totalOccurrences,
    this.interval,
    this.endDate,
  }) : assert(!(endDate != null && totalOccurrences != null), 'Cannot specify both an end date and total occurrences for a recurring event');

  RecurrenceRule.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw new ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    int recurrenceFrequencyIndex = json[_recurrenceFrequencyKey];
    if (recurrenceFrequencyIndex == null &&
        recurrenceFrequencyIndex >= RecurrenceFrequency.values.length) {
      throw new ArgumentError(ErrorMessages.invalidRecurrencyFrequency);
    }

    recurrenceFrequency = RecurrenceFrequency.values[recurrenceFrequencyIndex];
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
    if (interval != null) {
      data[_intervalKey] = interval;
    }
    if (totalOccurrences != null) {
      data[_totalOccurrencesKey] = totalOccurrences;
    }
    if (endDate != null) {
      data[_endDateKey] = endDate?.millisecondsSinceEpoch;
    }
    return data;
  }
}

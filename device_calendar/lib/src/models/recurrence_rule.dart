part of device_calendar;

class RecurrenceRule {
  int totalOccurrences;
  int interval;
  DateTime endDate;
  RecurrencyFrequency recurrenceFrequency;

  RecurrenceRule({
    @required this.recurrenceFrequency,
    this.totalOccurrences,
    this.interval,
    this.endDate,
  });

  RecurrenceRule.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw new ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    totalOccurrences = json['totalOccurrences'];
    interval = json['interval'];
    int endDateMillisecondsSinceEpoch = json['endDate'];
    if (endDateMillisecondsSinceEpoch != null) {
      endDate =
          DateTime.fromMillisecondsSinceEpoch(endDateMillisecondsSinceEpoch);
    }
    int recurrenceFrequencyIndex = json['recurrenceFrequency'];
    if (recurrenceFrequencyIndex != null) {}
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    return data;
  }
}

import 'package:flutter/foundation.dart';

class Reminder {
  /// The time when the reminder should be triggered expressed in terms of minutes before the start of the event
  int? minutes;

  //2.4.24 We allow minus values for reminders, because all day event reminders on that day are set with "minus minutes" (eg. -300)
  Reminder({@required this.minutes}) : assert(minutes != null, 'Minutes must not be null');

  Reminder.fromJson(Map<String, dynamic> json) {
    minutes = json['minutes'] as int;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'minutes': minutes};
  }
}

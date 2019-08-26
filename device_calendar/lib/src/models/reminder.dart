import 'package:flutter/foundation.dart';

class Reminder {
  int minutes;

  Reminder({@required this.minutes});

  Reminder.fromJson(Map<String, dynamic> json) {
    minutes = json['minutes'] as int;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'minutes': minutes};
  }
}

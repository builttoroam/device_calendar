import 'package:device_calendar/src/models/platform_specifics/android/attendance_status.dart';
import 'package:flutter/foundation.dart';

import '../../../common/error_messages.dart';

class AndroidAttendeeDetails {
  AndroidAttendanceStatus _attendanceStatus;

  /// Indicates if the attendee is required for this event
  bool isRequired;

  /// The attendee's status for the event. This is read-only
  AndroidAttendanceStatus get attendanceStatus => _attendanceStatus;

  AndroidAttendeeDetails({@required this.isRequired});

  AndroidAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    isRequired = json['isRequired'];
    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      _attendanceStatus =
          AndroidAttendanceStatus.values[json['attendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'isRequired': isRequired};
  }
}

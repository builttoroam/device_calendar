import 'package:flutter/foundation.dart';

import '../../../common/calendar_enums.dart';
import '../../../common/error_messages.dart';
import 'attendance_status.dart';

class AndroidAttendeeDetails {
  AndroidAttendanceStatus _attendanceStatus;

  /// An attendee type: None, Optional, Required or Resource
  AttendeeType attendeeType;

  /// The attendee's status for the event. This is read-only
  AndroidAttendanceStatus get attendanceStatus => _attendanceStatus;

  AndroidAttendeeDetails({@required this.attendeeType});

  AndroidAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    attendeeType = AttendeeType.values[json['attendeeType']];

    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      _attendanceStatus = AndroidAttendanceStatus.values[json['attendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{ 'attendeeType': attendeeType.index };
  }
}

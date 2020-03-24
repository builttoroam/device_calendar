import 'package:flutter/foundation.dart';

import '../../../common/calendar_enums.dart';
import '../../../common/error_messages.dart';
import 'attendance_status.dart';

class AndroidAttendeeDetails {
  AndroidAttendanceStatus _attendanceStatus;

  /// An attendee role: None, Optional, Required or Resource
  AttendeeRole role;

  /// The attendee's status for the event. This is read-only
  AndroidAttendanceStatus get attendanceStatus => _attendanceStatus;

  AndroidAttendeeDetails({@required this.role});

  AndroidAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    role = AttendeeRole.values[json['role']];

    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      _attendanceStatus =
          AndroidAttendanceStatus.values[json['attendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'role': role?.index};
  }
}

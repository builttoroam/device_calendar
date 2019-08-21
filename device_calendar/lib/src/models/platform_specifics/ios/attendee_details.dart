import 'package:device_calendar/src/models/platform_specifics/ios/attendance_status.dart';

import '../../../common/error_messages.dart';
import 'role.dart';

class IosAttendeeDetails {
  // The attendee's role at an event
  Role role;

  IosAttendanceStatus attendanceStatus;

  IosAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    if (json['role'] != null && json['role'] is int) {
      role = Role.values[json['role']];
    }
    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      attendanceStatus = IosAttendanceStatus.values[json['attendanceStatus']];
    }
  }
}

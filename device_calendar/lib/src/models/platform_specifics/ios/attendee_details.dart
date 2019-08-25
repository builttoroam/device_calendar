import 'package:device_calendar/src/models/platform_specifics/ios/attendance_status.dart';

import '../../../common/error_messages.dart';
import 'role.dart';

class IosAttendeeDetails {
  IosAttendanceStatus _attendanceStatus;
  // The attendee's role at an event
  Role role;

  /// The attendee's status for the event. This is read-only
  IosAttendanceStatus get attendanceStatus => _attendanceStatus;

  IosAttendeeDetails(this.role);

  IosAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    if (json['role'] != null && json['role'] is int) {
      role = Role.values[json['role']];
    }
    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      _attendanceStatus = IosAttendanceStatus.values[json['attendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role?.index,
    };
  }
}

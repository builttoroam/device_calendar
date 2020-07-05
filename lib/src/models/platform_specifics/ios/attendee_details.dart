import '../../../common/calendar_enums.dart';
import '../../../common/error_messages.dart';
import 'attendance_status.dart';

class IosAttendeeDetails {
  IosAttendanceStatus _attendanceStatus;

  /// An attendee role: None, Optional, Required or Resource
  AttendeeRole role;

  /// The attendee's status for the event. This is read-only
  IosAttendanceStatus get attendanceStatus => _attendanceStatus;

  IosAttendeeDetails({this.role});

  IosAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    role = AttendeeRole.values[json['role']];

    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      _attendanceStatus = IosAttendanceStatus.values[json['attendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'role': role?.index};
  }
}

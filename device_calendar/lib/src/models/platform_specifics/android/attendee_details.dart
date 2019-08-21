import 'package:device_calendar/src/models/platform_specifics/android/attendance_status.dart';

import '../../../common/error_messages.dart';

class AndroidAttendeeDetails {
  /// Indicates if the attendee is required for this event
  bool isRequired;

  AndroidAttendanceStatus attendanceStatus;

  AndroidAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    isRequired = json['isRequired'];
    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      attendanceStatus =
          AndroidAttendanceStatus.values[json['attendanceStatus']];
    }
  }
}

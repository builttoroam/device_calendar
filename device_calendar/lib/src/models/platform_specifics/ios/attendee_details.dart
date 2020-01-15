import '../../../common/calendar_enums.dart';
import '../../../common/error_messages.dart';
import 'attendance_status.dart';

class IosAttendeeDetails {
  IosAttendanceStatus _attendanceStatus;
  
  /// An attendee type: None, Optional, Required or Resource
  AttendeeType attendeeType;

  /// The attendee's status for the event. This is read-only
  IosAttendanceStatus get attendanceStatus => _attendanceStatus;

  IosAttendeeDetails({this.attendeeType});

  IosAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    attendeeType = AttendeeType.values[json['attendeeType']];

    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      _attendanceStatus = IosAttendanceStatus.values[json['attendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{ 'attendeeType': attendeeType.index };
  }
}

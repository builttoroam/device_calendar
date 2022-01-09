import '../../../common/error_messages.dart';
import 'attendance_status.dart';

class AndroidAttendeeDetails {
  AndroidAttendanceStatus? attendanceStatus;

  AndroidAttendeeDetails({this.attendanceStatus});

  AndroidAttendeeDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      attendanceStatus =
          AndroidAttendanceStatus.values[json['attendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'attendanceStatus': attendanceStatus?.index};
  }
}

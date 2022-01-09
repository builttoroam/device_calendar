import '../../../common/error_messages.dart';
import 'attendance_status.dart';

class IosAttendeeDetails {
  IosAttendanceStatus? attendanceStatus;
  IosAttendeeDetails({this.attendanceStatus});

  IosAttendeeDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    if (json['attendanceStatus'] != null && json['attendanceStatus'] is int) {
      attendanceStatus = IosAttendanceStatus.values[json['attendanceStatus']];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'attendanceStatus': attendanceStatus?.index};
  }
}

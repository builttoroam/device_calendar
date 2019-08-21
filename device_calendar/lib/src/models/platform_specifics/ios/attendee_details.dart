import '../../../common/error_messages.dart';
import 'role.dart';

class IosAttendeeDetails {
  // The attendee's role at an event
  Role role;

  IosAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    if (json['role'] != null && json['role'] is int) {
      role = Role.values[json['role']];
    }
  }
}

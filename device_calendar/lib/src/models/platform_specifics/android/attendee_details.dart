import '../../../common/error_messages.dart';

class AndroidAttendeeDetails {
  /// Indicates if the attendee is required for this event
  bool isRequired;

  AndroidAttendeeDetails.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    isRequired = json['isRequired'];
  }
}

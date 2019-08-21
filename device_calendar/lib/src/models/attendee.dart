import 'package:platform/platform.dart';

import '../common/error_messages.dart';
import 'platform_specifics/android/attendee_details.dart';
import 'platform_specifics/ios/attendee_details.dart';

/// A person attending an event
class Attendee {
  /// The name of the attendee
  String name;

  ///  The email address of the attendee
  String emailAddress;

  /// Details about the attendee that are specific to iOS.
  /// When reading details for an existing event, this will only be populated on iOS devices.
  IosAttendeeDetails iosAttendeeDetails;

  /// Details about the attendee that are specific to Android.
  /// When reading details for an existing event, this will only be populated on Android devices.
  AndroidAttendeeDetails androidAttendeeDetails;

  Attendee({this.name, this.emailAddress});

  Attendee.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    name = json['name'];
    emailAddress = json['emailAddress'];
    final platform = LocalPlatform();
    if (platform.isAndroid) {
      androidAttendeeDetails = AndroidAttendeeDetails.fromJson(json);
    }

    if (platform.isIOS) {
      iosAttendeeDetails = IosAttendeeDetails.fromJson(json);
    }
  }

  /*Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['name'] = this.name;
    return data;
  }*/
}

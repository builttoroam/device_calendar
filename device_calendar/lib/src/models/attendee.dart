import 'dart:io' show Platform;

import '../common/error_messages.dart';
import 'platform_specifics/android/attendee_details.dart';
import 'platform_specifics/ios/attendee_details.dart';

/// A person attending an event
class Attendee {
  /// The name of the attendee. Currently has no effect when saving attendees on iOS.
  String name;

  ///  The email address of the attendee
  String emailAddress;

  /// Details about the attendee that are specific to iOS. Currently has no effect when saving attendees on iOS.
  /// When reading details for an existing event, this will only be populated on iOS devices.
  IosAttendeeDetails iosAttendeeDetails;

  /// Details about the attendee that are specific to Android.
  /// When reading details for an existing event, this will only be populated on Android devices.
  AndroidAttendeeDetails androidAttendeeDetails;

  Attendee(
      {this.name,
      this.emailAddress,
      this.iosAttendeeDetails,
      this.androidAttendeeDetails});

  Attendee.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    name = json['name'];
    emailAddress = json['emailAddress'];
    if (Platform.isAndroid) {
      androidAttendeeDetails = AndroidAttendeeDetails.fromJson(json);
    }

    if (Platform.isIOS) {
      iosAttendeeDetails = IosAttendeeDetails.fromJson(json);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['name'] = name;
    data['emailAddress'] = emailAddress;
    if (Platform.isIOS && iosAttendeeDetails != null) {
      data.addEntries(iosAttendeeDetails.toJson().entries);
    }
    if (Platform.isAndroid && androidAttendeeDetails != null) {
      data.addEntries(androidAttendeeDetails.toJson().entries);
    }
    return data;
  }
}

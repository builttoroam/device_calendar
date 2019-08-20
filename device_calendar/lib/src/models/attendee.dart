import '../common/error_messages.dart';

/// A person attending an event
class Attendee {
  /// The name of the attendee
  String name;

  ///  The email address of the attendee
  String emailAddress;

  Attendee({this.name, this.emailAddress});

  Attendee.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    name = json['name'];
    emailAddress = json['emailAddress'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['name'] = this.name;
    return data;
  }
}

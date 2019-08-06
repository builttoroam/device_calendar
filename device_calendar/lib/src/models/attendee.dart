import '../common/error_messages.dart';

/// A person attending an event
class Attendee {
  /// The name of the attendee
  String name;

  Attendee(this.name);

  Attendee.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['name'] = this.name;
    return data;
  }
}

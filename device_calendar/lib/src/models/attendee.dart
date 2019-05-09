part of device_calendar;

/// A person attending an event
class Attendee {
  /// The name of the attendee
  String name;
  String email;
  bool attendanceRequired;
  int eventId;
  int id;

  Attendee(this.name, {this.email, this.attendanceRequired, this.eventId, this.id});

  Attendee.fromJson(Map<String, dynamic> json) {

    if (json == null) {
      throw new ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    name = json['name'];
    email = json['email'];
    attendanceRequired = json['attendanceRequired'] ?? false;
    eventId = json['eventId'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['attendanceRequired'] = this.attendanceRequired;
    data['eventId'] = this.eventId;
    data['id'] = this.id;

    return data;
  }
}

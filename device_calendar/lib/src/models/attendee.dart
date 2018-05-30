part of device_calendar;

class Attendee {
  String name;

  Attendee(this.name);

  Attendee.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw new ArgumentError(Constants.fromJsonMapIsNull);
    }

    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    return data;
  }
}

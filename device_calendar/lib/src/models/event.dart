part of device_calendar;

class Event {
  String id;
  String title;

  DateTime start;
  DateTime end;

  Event.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw new ArgumentError(Constants.fromJsonMapIsNull);
    }

    id = json['id'];
    title = json['title'];
    start = json['start'];
    end = json['end'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['start'] = this.start;
    data['end'] = this.end;

    return data;
  }
}

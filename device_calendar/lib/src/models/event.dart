part of device_calendar;

class Event {
  String title;

  DateTime start;
  DateTime end;

  Event.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      return;
    }

    title = json['title'];
    start = json['start'];
    end = json['end'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['start'] = this.start;
    data['end'] = this.end;

    return data;
  }
}

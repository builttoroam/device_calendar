part of device_calendar;

class Calendar {
  String id;
  String name;

  bool isReadyOnly;

  Calendar({this.id, this.name, this.isReadyOnly});

  Calendar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isReadyOnly = json['isReadyOnly'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['isReadyOnly'] = this.isReadyOnly;
    return data;
  }
}

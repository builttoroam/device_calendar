part of device_calendar;

class Location {
  double latitude;
  double longitude;

  Location(this.latitude, this.longitude);

  Location.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw new ArgumentError(Constants.fromJsonMapIsNull);
    }

    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

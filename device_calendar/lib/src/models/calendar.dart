/// A calendar on the user's device
class Calendar {
  /// Read-only. The unique identifier for this calendar
  String id;

  /// The name of this calendar
  String name;

  /// Read-only. If the calendar is read-only
  bool isReadOnly;

  /// Read-only. If the calendar is the default
  bool isDefault;

  /// Color of the calendar
  int color;

  Calendar({this.id, this.name, this.isReadOnly, this.isDefault, this.color});

  Calendar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isReadOnly = json['isReadOnly'];
    isDefault = json['isDefault'];
    color = json['color'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'isReadOnly': isReadOnly,
      'isDefault': isDefault,
      'color': color
    };

    return data;
  }
}

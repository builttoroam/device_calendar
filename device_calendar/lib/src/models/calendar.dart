/// A calendar on the user's device
class Calendar {
  /// The unique identifier for this calendar
  String id;

  /// The name of this calendar
  String name;

  /// If the calendar is read-only
  bool isReadOnly;

  /// If the calendar is the default
  bool isDefault;

  Calendar({this.id, this.name, this.isReadOnly, this.isDefault});

  Calendar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isReadOnly = json['isReadOnly'];
    isDefault = json['isDefault'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{ 'id': id, 'name': name, 'isReadOnly': isReadOnly, 'isDefault': isDefault };
    
    return data;
  }
}

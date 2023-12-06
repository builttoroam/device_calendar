/// A calendar on the user's device
class Calendar {
  /// Read-only. The unique identifier for this calendar
  String? id;

  /// The name of this calendar
  String? name;

  /// Read-only. If the calendar is read-only
  bool? isReadOnly;

  /// Read-only. If the calendar is the default
  bool? isDefault;

  /// Read-only. Color of the calendar
  int? color;

  // Read-only. Account name associated with the calendar
  String? accountName;

  // Read-only. Account type associated with the calendar
  String? accountType;

  /// The name of this calendar (the other one up is the "display name")
  String? name_;

  Calendar({
    this.id,
    this.name,
    this.isReadOnly,
    this.isDefault,
    this.color,
    this.accountName,
    this.accountType,
    this.name_,
  });

  Calendar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isReadOnly = json['isReadOnly'];
    isDefault = json['isDefault'];
    color = json['color'];
    accountName = json['accountName'];
    accountType = json['accountType'];
    name_ = json['name_'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'isReadOnly': isReadOnly,
      'isDefault': isDefault,
      'color': color,
      'accountName': accountName,
      'accountType': accountType,
      'name_': name_
    };

    return data;
  }
}

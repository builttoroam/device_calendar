import 'package:device_calendar/src/extenssion/map_extension.dart';

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

  Calendar({this.id, this.name, this.isReadOnly, this.isDefault, this.color, this.accountName, this.accountType});

  Calendar.fromJson(Map<String, dynamic> json) {
    id = json.hasKey('id') ? json['id'] : '';
    name = json.hasKey('name') ? json['name'] : '';
    isReadOnly = json.hasKey('isReadOnly') ? json['isReadOnly'] : false;
    isDefault = json.hasKey('isDefault') ? json['isDefault'] : false;
    color = json.hasKey('color') ? json['color'] : 0;
    accountName = json.hasKey('accountName') ? json['accountName'] : '';
    accountType = json.hasKey('accountType') ? json['accountType'] : '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id ?? '',
      'name': name ?? '',
      'isReadOnly': isReadOnly ?? false,
      'isDefault': isDefault ?? false,
      'color': color ?? 0,
      'accountName': accountName ?? '',
      'accountType': accountType ?? ''
    };

    return data;
  }
}

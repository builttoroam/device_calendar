import 'package:flutter/foundation.dart';

class AccountSource {
  String name;
  String type;

  AccountSource({@required this.name, this.type});

  AccountSource.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'name': name, 'type': type};
  }
}

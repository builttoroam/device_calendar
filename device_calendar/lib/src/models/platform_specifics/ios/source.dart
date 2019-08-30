import 'package:device_calendar/src/models/platform_specifics/ios/source_type.dart';
import 'package:flutter/foundation.dart';

class Source {
  String title;
  SourceType sourceType;

  Source({@required this.title, @required this.sourceType});

  Source.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    sourceType = SourceType.values[json['sourceType']];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'title': title, 'sourceType': sourceType.index};
  }
}

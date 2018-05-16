import 'dart:async';

import 'package:flutter/services.dart';

class DeviceCalendar {
  static const MethodChannel _channel =
      const MethodChannel('device_calendar');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

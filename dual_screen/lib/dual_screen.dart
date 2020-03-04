import 'dart:async';

import 'package:flutter/services.dart';

class DualScreen {
  static const MethodChannel _methodChannel =
      const MethodChannel('plugins.builttoroam.com/dual_screen/methods');
  static const EventChannel _eventChannel =
      const EventChannel('plugins.builttoroam.com/dual_screen/events');

  static Future<bool> get isDualScreenDevice async =>
      await _methodChannel.invokeMethod('isDualScreenDevice');

  static Future<bool> get isAppSpanned async =>
      await _methodChannel.invokeMethod('isAppSpanned');

  static Stream<bool> isAppSpannedStream() async* {
    yield* _eventChannel
        .receiveBroadcastStream()
        .map<bool>((dynamic result) => result);
  }
}

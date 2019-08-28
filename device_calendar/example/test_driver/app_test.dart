import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('App', () {
    FlutterDriver driver;
    setUpAll(() async {
      // workaround for handling permissions based on info taken from https://github.com/flutter/flutter/issues/12561
      // this is to be run in a Mac environment
      final Map<String, String> envVars = Platform.environment;
      final String adbPath = envVars['ANDROID_HOME'] + '/platform-tools/adb';
      await Process.run(adbPath, [
        'shell',
        'pm',
        'grant',
        'com.builttoroam.devicecalendarexample',
        'android.permission.INTERNET'
      ]);
      await Process.run(adbPath, [
        'shell',
        'pm',
        'grant',
        'com.builttoroam.devicecalendarexample',
        'android.permission.READ_CALENDAR'
      ]);
      await Process.run(adbPath, [
        'shell',
        'pm',
        'grant',
        'com.builttoroam.devicecalendarexample',
        'android.permission.WRITE_CALENDAR'
      ]);

      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver?.close();
    });

    test('check flutter driver health', () async {
      final health = await driver.checkHealth();
      print('flutter driver status: ${health.status}');
    });
  });
}

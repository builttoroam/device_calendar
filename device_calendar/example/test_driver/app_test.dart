import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('App', () {
    FlutterDriver driver;
    final saveEventButtonFinder = find.byValueKey('saveEventButton');
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

    test('starts on calendars page', () async {
      await driver.waitFor(find.byValueKey('calendarsPage'));
    });
    test('select first writable calendar', () async {
      final writableCalendarFinder = find.byValueKey('writableCalendar0');
      await driver.waitFor(writableCalendarFinder,
          timeout: Duration(milliseconds: 500));
      await driver.tap(writableCalendarFinder);
    });
    test('go to add event page', () async {
      final addEventButtonFinder = find.byValueKey('addEventButton');
      await driver.waitFor(addEventButtonFinder);
      await driver.tap(addEventButtonFinder);
      await driver.waitFor(saveEventButtonFinder);
    });
    test('try to save event without entering mandatory fields', () async {
      await driver.tap(saveEventButtonFinder);
      await driver.waitFor(
          find.text('Please fix the errors in red before submitting.'));
    });
  });
}

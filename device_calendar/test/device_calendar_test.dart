import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MethodChannel channel =
      const MethodChannel('plugins.builttoroam.com/device_calendar');
  DeviceCalendarPlugin deviceCalendarPlugin = new DeviceCalendarPlugin();

  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);

      return null;
    });

    log.clear();
  });

  test('RetrieveEvents_CalendarId_IsRequired', () async {
    final String calendarId = null;
    final RetrieveEventsParams params = new RetrieveEventsParams();

    final result =
        await deviceCalendarPlugin.retrieveEvents(calendarId, params);
    expect(result.isSuccess, false);
    expect(result.errorMessages.length, greaterThan(0));
    expect(result.errorMessages[0], contains("400"));
  });
}

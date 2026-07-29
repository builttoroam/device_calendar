import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reminder', () {
    test('FromJson_ToJson_RoundTrip', () {
      final reminder = Reminder(minutes: 30);
      final roundTripped = Reminder.fromJson(reminder.toJson());
      expect(roundTripped.minutes, 30);
    });

    test('Constructor_NegativeMinutes_ThrowsAssertionError', () {
      expect(() => Reminder(minutes: -1), throwsA(isA<AssertionError>()));
    });

    test('Constructor_ZeroMinutes_IsAllowed', () {
      final reminder = Reminder(minutes: 0);
      expect(reminder.minutes, 0);
    });
  });
}

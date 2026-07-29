import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetrieveEventsParams', () {
    // A dumb data holder: it does no validation of its own (validation lives
    // in DeviceCalendarPlugin.retrieveEvents, covered in
    // device_calendar_test.dart). These tests just pin that "no validation
    // here" contract so nobody adds it silently without a test forcing the
    // decision.
    test('Construction_EventIdsOnly', () {
      const params = RetrieveEventsParams(eventIds: ['1', '2']);
      expect(params.eventIds, ['1', '2']);
      expect(params.startDate, isNull);
      expect(params.endDate, isNull);
    });

    test('Construction_DatesOnly', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 2);
      final params = RetrieveEventsParams(startDate: start, endDate: end);
      expect(params.eventIds, isNull);
      expect(params.startDate, start);
      expect(params.endDate, end);
    });

    test('Construction_Both', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 2);
      final params = RetrieveEventsParams(
          eventIds: ['1'], startDate: start, endDate: end);
      expect(params.eventIds, ['1']);
      expect(params.startDate, start);
      expect(params.endDate, end);
    });

    test('Construction_Neither', () {
      const params = RetrieveEventsParams();
      expect(params.eventIds, isNull);
      expect(params.startDate, isNull);
      expect(params.endDate, isNull);
    });

    test('Construction_StartAfterEnd_DoesNotThrow', () {
      // No validation at this layer -- an inverted range is accepted here
      // without complaint.
      final start = DateTime(2024, 1, 2);
      final end = DateTime(2024, 1, 1);
      final params = RetrieveEventsParams(startDate: start, endDate: end);
      expect(params.startDate!.isAfter(params.endDate!), isTrue);
    });
  });
}

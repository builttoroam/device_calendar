import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attendee', () {
    test('FromJson_ToJson_RoundTrip_AllFieldsPopulated', () {
      final attendee = Attendee(
        name: 'Ada',
        emailAddress: 'ada@example.com',
        role: AttendeeRole.Optional,
        isOrganiser: true,
        isCurrentUser: true,
      );
      final roundTripped = Attendee.fromJson(attendee.toJson());
      expect(roundTripped.name, attendee.name);
      expect(roundTripped.emailAddress, attendee.emailAddress);
      expect(roundTripped.role, attendee.role);
      expect(roundTripped.isOrganiser, attendee.isOrganiser);
    });

    test('FromJson_ToJson_RoundTrip_OptionalFieldsAbsent', () {
      // toJson() never writes isCurrentUser, so fromJson always reads it
      // back as the json-default false regardless of the original value.
      final roundTripped = Attendee.fromJson(Attendee().toJson());
      expect(roundTripped.name, isNull);
      expect(roundTripped.emailAddress, isNull);
      expect(roundTripped.role, AttendeeRole.None); // json['role'] ?? 0
      expect(roundTripped.isOrganiser, isFalse);
      expect(roundTripped.isCurrentUser, isFalse);
    });

    test('AttendeeRole_IntEnumMapping_RoundTripsForEveryValue', () {
      for (final role in AttendeeRole.values) {
        final attendee = Attendee(role: role);
        final roundTripped = Attendee.fromJson(attendee.toJson());
        expect(roundTripped.role, role);
      }
    });

    test('AttendeeRole_OutOfRangeInt_ThrowsRangeError', () {
      // AttendeeRole.values[json['role']] does no bounds checking -- an
      // out-of-range int throws RangeError rather than clamping or
      // defaulting. Pinned down so this can't silently change to a swallow.
      expect(() => Attendee.fromJson({'role': 99}), throwsRangeError);
    });

    test('FromJson_NullJson_ThrowsArgumentError', () {
      expect(() => Attendee.fromJson(null), throwsArgumentError);
    });

    test('FromJson_NonAndroidNonIos_DetailsAreNull', () {
      // Test host is neither Android nor iOS, so both detail objects stay
      // null regardless of what's in the json -- this is the same
      // expectation the existing device_calendar_test.dart pins for
      // Attendee_Serialises_Correctly.
      final attendee = Attendee.fromJson({
        'name': 'Ada',
        'attendanceStatus': 1,
      });
      expect(attendee.androidAttendeeDetails, isNull);
      expect(attendee.iosAttendeeDetails, isNull);
    });
  });
}

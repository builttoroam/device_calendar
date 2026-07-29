import 'dart:convert';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Initializes the timezone database (and sets a default `local` location)
  // the same way the plugin's own factory constructor does.
  DeviceCalendarPlugin();

  group('Event.fromJson', () {
    test('FromJson_NullJson_ThrowsArgumentError', () {
      expect(() => Event.fromJson(null), throwsArgumentError);
    });

    test('FromJson_LegacyTopLevelKeys_ThrowsFormatException', () {
      // One test per legacy key, as the plan originally asked for. (Earlier
      // revision of this test documented a real bug where 8 of these 9 keys
      // were silently ignored -- a broken map literal in Event.fromJson
      // collapsed them into a single check on 'url' only. Fixed in
      // event.dart; this now verifies every key actually works.)
      for (final key in [
        'title',
        'description',
        'start',
        'end',
        'startTimeZone',
        'endTimeZone',
        'allDay',
        'location',
        'url',
      ]) {
        expect(() => Event.fromJson({key: 'x'}), throwsFormatException,
            reason: 'top-level "$key" should trigger legacy detection');
      }
    });

    test('FromJson_NoLegacyTopLevelKeys_DoesNotThrow', () {
      expect(() => Event.fromJson({'eventTitle': 'x'}), returnsNormally);
    });

    test('FromJson_StartTimeZone_UnknownName_DefaultsToLocal', () {
      final event = Event.fromJson({
        'eventStartTimeZone': 'Not/ARealZone',
        'eventStartDate': 0,
      });
      expect(event.start!.location.name, equals(local.name));
    });

    test('FromJson_EndTimeZone_Null_DefaultsToStartTimeZone', () {
      final event = Event.fromJson({
        'eventStartTimeZone': 'Australia/Sydney',
        'eventStartDate': 0,
        'eventEndDate': 0,
      });
      expect(event.end!.location.name, equals('Australia/Sydney'));
    });

    test('FromJson_Url_EmptyString_IsNull', () {
      final event = Event.fromJson({'eventURL': ''});
      expect(event.url, isNull);
    });

    test('FromJson_Url_Malformed_IsNullNotThrow', () {
      // Regression test for the #594/#604 fix (Uri.tryParse instead of
      // Uri.dataFromString): a string Uri.tryParse can't parse must produce
      // a null url, not throw.
      expect(Uri.tryParse('http://[invalid'), isNull,
          reason: 'test premise: this string must be unparseable');
      final event = Event.fromJson({'eventURL': 'http://[invalid'});
      expect(event.url, isNull);
    });

    test('FromJson_Attendees_OrganizerMatch_SetsIsOrganiser', () {
      final event = Event.fromJson({
        'attendees': [
          {'name': 'Ada', 'emailAddress': 'ada@example.com', 'role': 1},
        ],
        'organizer': {'name': 'Ada', 'emailAddress': 'ada@example.com'},
      });
      expect(event.attendees, hasLength(1));
      expect(event.attendees!.single!.isOrganiser, isTrue);
    });

    test('FromJson_Attendees_OrganizerNoMatch_LeavesAttendeesUnchanged', () {
      final event = Event.fromJson({
        'attendees': [
          {'name': 'Ada', 'emailAddress': 'ada@example.com', 'role': 1},
        ],
        'organizer': {
          'name': 'Someone Else',
          'emailAddress': 'else@example.com'
        },
      });
      expect(event.attendees, hasLength(1));
      expect(event.attendees!.single!.isOrganiser, isFalse);
    });

    test('FromJson_RecurrenceRule_ListFieldsCastCorrectly', () {
      final recurrenceRule = RecurrenceRule(
        frequency: Frequency.yearly,
        byWeekDays: [
          ByWeekDayEntry(DateTime.monday),
          ByWeekDayEntry(DateTime.tuesday),
        ],
        byMonthDays: const [1, 15],
        byYearDays: const [100],
        byWeeks: const [5],
        byMonths: const [3],
        bySetPositions: const [1],
      );
      final event = Event('calendarId', recurrenceRule: recurrenceRule);

      // Round-trip through actual JSON encode/decode, exactly like the
      // method channel does, so every list field arrives as `List<dynamic>`
      // -- the scenario the `.cast<...>()` fixups in Event.fromJson exist
      // for. Without them, the rrule package throws FormatException.
      final decoded =
          json.decode(json.encode(event.toJson())) as Map<String, dynamic>;

      final roundTripped = Event.fromJson(decoded);
      final rrule = roundTripped.recurrenceRule!;
      expect(rrule.frequency, equals(Frequency.yearly));
      expect(
        rrule.byWeekDays,
        equals([
          ByWeekDayEntry(DateTime.monday),
          ByWeekDayEntry(DateTime.tuesday),
        ]),
      );
      expect(rrule.byMonthDays, equals(const [1, 15]));
      expect(rrule.byYearDays, equals(const [100]));
      expect(rrule.byWeeks, equals(const [5]));
      expect(rrule.byMonths, equals(const [3]));
      expect(rrule.bySetPositions, equals(const [1]));
    });
  });

  group('Event.toJson', () {
    test('ToJson_RoundTrips_AllFields', () {
      final start =
          TZDateTime(getLocation('Australia/Sydney'), 2024, 3, 10, 9, 30);
      final end = start.add(const Duration(hours: 1));
      final attendee = Attendee(
        name: 'Ada',
        emailAddress: 'ada@example.com',
        role: AttendeeRole.Required,
        isOrganiser: true,
      );
      final reminder = Reminder(minutes: 15);
      final recurrenceRule = RecurrenceRule(frequency: Frequency.daily);

      final event = Event(
        'calendarId',
        eventId: 'eventId',
        title: 'Title',
        description: 'Description',
        start: start,
        end: end,
        location: 'Location',
        url: Uri.parse('http://example.com'),
        attendees: [attendee],
        recurrenceRule: recurrenceRule,
        reminders: [reminder],
        availability: Availability.Tentative,
        status: EventStatus.Confirmed,
        allDay: false,
      )..updateEventColor(EventColor(0xff112233, 7));

      final roundTripped =
          Event.fromJson(json.decode(json.encode(event.toJson())));

      // identity
      expect(roundTripped.calendarId, event.calendarId);
      expect(roundTripped.eventId, event.eventId);
      expect(roundTripped.title, event.title);
      expect(roundTripped.description, event.description);
      // dates
      expect(roundTripped.start!.millisecondsSinceEpoch,
          event.start!.millisecondsSinceEpoch);
      expect(roundTripped.end!.millisecondsSinceEpoch,
          event.end!.millisecondsSinceEpoch);
      expect(roundTripped.start!.location.name, event.start!.location.name);
      // location/url
      expect(roundTripped.location, event.location);
      expect(roundTripped.url, event.url);
      // attendees
      expect(roundTripped.attendees, hasLength(1));
      expect(roundTripped.attendees!.single!.name, attendee.name);
      // recurrence
      expect(roundTripped.recurrenceRule!.frequency, Frequency.daily);
      // reminders
      expect(roundTripped.reminders, hasLength(1));
      expect(roundTripped.reminders!.single.minutes, 15);
      // availability/status
      expect(roundTripped.availability, Availability.Tentative);
      expect(roundTripped.status, EventStatus.Confirmed);
      // color
      expect(roundTripped.color, 0xff112233);
      expect(roundTripped.colorKey, 7);
    });
  });

  group('parseStringToAvailability', () {
    test('ParseStringToAvailability_UnknownString_DefaultsToBusy', () {
      final event = Event('calendarId');
      expect(event.parseStringToAvailability('not-a-real-value'),
          Availability.Busy);
      expect(event.parseStringToAvailability(null), Availability.Busy);
    });

    test('ParseStringToAvailability_CaseInsensitive', () {
      final event = Event('calendarId');
      expect(event.parseStringToAvailability('free'), Availability.Free);
      expect(event.parseStringToAvailability('Free'), Availability.Free);
      expect(event.parseStringToAvailability('FREE'), Availability.Free);
    });
  });

  group('parseStringToEventStatus', () {
    test('ParseStringToEventStatus_UnknownString_ReturnsNull', () {
      // Differs from Availability's default-to-Busy: an unrecognized status
      // string is left as null rather than mapped to a fallback value. This
      // asymmetry is intentional (status is nullable, availability isn't),
      // not a bug -- pinned down here so it can't silently change.
      final event = Event('calendarId');
      expect(event.parseStringToEventStatus('not-a-real-value'), isNull);
      expect(event.parseStringToEventStatus(null), isNull);
    });
  });

  group('updateStartLocation / updateEndLocation', () {
    test('UpdateStartLocation_ValidTimeZone_ReturnsTrueAndUpdates', () {
      final event = Event('calendarId', start: TZDateTime.utc(2024, 1, 1));
      final result = event.updateStartLocation('Australia/Sydney');
      expect(result, isTrue);
      expect(event.start!.location.name, 'Australia/Sydney');
    });

    test('UpdateStartLocation_InvalidTimeZone_ReturnsFalseAndLeavesUnchanged',
        () {
      final start = TZDateTime.utc(2024, 1, 1);
      final event = Event('calendarId', start: start);
      final result = event.updateStartLocation('Not/ARealZone');
      expect(result, isFalse);
      expect(event.start, same(start));
    });

    test('UpdateEndLocation_ValidTimeZone_ReturnsTrueAndUpdates', () {
      final event = Event('calendarId', end: TZDateTime.utc(2024, 1, 1));
      final result = event.updateEndLocation('Australia/Sydney');
      expect(result, isTrue);
      expect(event.end!.location.name, 'Australia/Sydney');
    });

    test('UpdateEndLocation_InvalidTimeZone_ReturnsFalseAndLeavesUnchanged',
        () {
      final end = TZDateTime.utc(2024, 1, 1);
      final event = Event('calendarId', end: end);
      final result = event.updateEndLocation('Not/ARealZone');
      expect(result, isFalse);
      expect(event.end, same(end));
    });
  });

  group('updateEventColor', () {
    test('UpdateEventColor_SetsColorAndColorKey', () {
      final event = Event('calendarId');
      event.updateEventColor(EventColor(0xffabcdef, 3));
      expect(event.color, 0xffabcdef);
      expect(event.colorKey, 3);
    });

    test('UpdateEventColor_Null_ClearsColorAndColorKey', () {
      final event = Event('calendarId')..updateEventColor(EventColor(1, 2));
      event.updateEventColor(null);
      expect(event.color, isNull);
      expect(event.colorKey, isNull);
    });
  });
}

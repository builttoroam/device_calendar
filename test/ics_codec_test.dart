import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('eventsToIcs / eventsFromIcs round trip', () {
    test('RoundTrip_TimedEvent_PreservesCoreFields', () {
      final sydney = getLocation('Australia/Sydney');
      final start = TZDateTime(sydney, 2024, 3, 10, 14, 30);
      final end = TZDateTime(sydney, 2024, 3, 10, 15, 30);
      final organiser = Attendee(
          name: 'Organiser',
          emailAddress: 'organiser@test.com',
          role: AttendeeRole.Required,
          isOrganiser: true);
      final attendee = Attendee(
          name: 'Attendee One',
          emailAddress: 'attendee1@test.com',
          role: AttendeeRole.Optional);
      final event = Event('fakeCalendarId',
          title: 'Team sync',
          description: 'Weekly sync-up',
          location: 'Meeting Room 1',
          url: Uri.parse('https://example.com/meet'),
          start: start,
          end: end,
          availability: Availability.Tentative,
          status: EventStatus.Confirmed,
          attendees: [organiser, attendee],
          recurrenceRule: RecurrenceRule(
              frequency: Frequency.weekly, count: 5));

      final ics = event.toIcs();
      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('BEGIN:VEVENT'));

      final parsed = eventsFromIcs(ics);
      expect(parsed, hasLength(1));
      final roundTripped = parsed.single;

      expect(roundTripped.title, event.title);
      expect(roundTripped.description, event.description);
      expect(roundTripped.location, event.location);
      expect(roundTripped.url, event.url);
      expect(roundTripped.start!.millisecondsSinceEpoch,
          event.start!.millisecondsSinceEpoch);
      expect(roundTripped.end!.millisecondsSinceEpoch,
          event.end!.millisecondsSinceEpoch);
      expect(roundTripped.availability, event.availability);
      expect(roundTripped.status, event.status);
      expect(roundTripped.recurrenceRule?.frequency, Frequency.weekly);
      expect(roundTripped.recurrenceRule?.count, 5);
      expect(roundTripped.attendees, hasLength(2));
      expect(
        roundTripped.attendees!
            .firstWhere((a) => a!.isOrganiser)!
            .emailAddress,
        'organiser@test.com',
      );
      expect(
        roundTripped.attendees!
            .firstWhere((a) => !a!.isOrganiser)!
            .emailAddress,
        'attendee1@test.com',
      );

      // ICS UID belongs to the .ics document, not this plugin's
      // device-assigned eventId -- importing never sets it.
      expect(roundTripped.eventId, isNull);
    });

    test('RoundTrip_AllDayEvent_UsesDateOnlyValueAndRoundTrips', () {
      final start = TZDateTime.utc(2024, 6, 1);
      final end = TZDateTime.utc(2024, 6, 3);
      final event = Event('fakeCalendarId',
          title: 'Conference',
          start: start,
          end: end,
          allDay: true);

      final ics = event.toIcs();
      expect(ics, contains('DTSTART;VALUE=DATE:20240601'));
      expect(ics, contains('DTEND;VALUE=DATE:20240603'));

      final roundTripped = eventsFromIcs(ics).single;
      expect(roundTripped.allDay, true);
      expect(roundTripped.start!.year, 2024);
      expect(roundTripped.start!.month, 6);
      expect(roundTripped.start!.day, 1);
      expect(roundTripped.end!.day, 3);
    });

    test('RoundTrip_LongTextWithSpecialCharacters_FoldsAndEscapesCorrectly',
        () {
      final longTitle = 'A' * 120;
      const description =
          'Line one\nLine two; with a comma, and a \\backslash\\';
      final start = TZDateTime.utc(2024, 1, 1, 9);
      final event = Event('fakeCalendarId',
          title: longTitle,
          description: description,
          start: start,
          end: start.add(const Duration(hours: 1)));

      final ics = event.toIcs();
      // Folded lines are continued with CRLF + a single leading space.
      expect(ics, contains('\r\n '));

      final roundTripped = eventsFromIcs(ics).single;
      expect(roundTripped.title, longTitle);
      expect(roundTripped.description, description);
    });

    test('MultipleEvents_EventsToIcs_ProducesOneVeventPerEvent', () {
      final start = TZDateTime.utc(2024, 1, 1, 9);
      final events = List.generate(
        3,
        (i) => Event('fakeCalendarId',
            title: 'Event $i',
            start: start.add(Duration(days: i)),
            end: start.add(Duration(days: i, hours: 1))),
      );

      final ics = eventsToIcs(events);
      expect('BEGIN:VEVENT'.allMatches(ics).length, 3);

      final parsed = eventsFromIcs(ics);
      expect(parsed, hasLength(3));
      expect(parsed.map((e) => e.title), ['Event 0', 'Event 1', 'Event 2']);
    });
  });

  group('eventsFromIcs edge cases', () {
    test('MalformedRrule_IsDroppedNotThrown', () {
      final ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:1@test
DTSTART:20240101T090000Z
DTEND:20240101T100000Z
SUMMARY:Bad rrule
RRULE:NOT;A;VALID;RRULE
END:VEVENT
END:VCALENDAR
'''
          .replaceAll('\n', '\r\n');

      final events = eventsFromIcs(ics);
      expect(events, hasLength(1));
      expect(events.single.recurrenceRule, isNull);
    });

    test('VAlarmBlock_IsIgnored', () {
      final ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:1@test
DTSTART:20240101T090000Z
DTEND:20240101T100000Z
SUMMARY:Has an alarm
BEGIN:VALARM
ACTION:DISPLAY
TRIGGER:-PT15M
DESCRIPTION:Reminder
END:VALARM
END:VEVENT
END:VCALENDAR
'''
          .replaceAll('\n', '\r\n');

      final events = eventsFromIcs(ics);
      expect(events, hasLength(1));
      // The VALARM's own DESCRIPTION must not clobber the event's.
      expect(events.single.description, isNull);
      expect(events.single.title, 'Has an alarm');
    });

    test('EventWithoutDtstart_IsSkipped', () {
      final ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:1@test
SUMMARY:No start date
END:VEVENT
END:VCALENDAR
'''
          .replaceAll('\n', '\r\n');

      expect(eventsFromIcs(ics), isEmpty);
    });

    test('KnownTzid_ResolvesToCorrectInstant', () {
      final ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:1@test
DTSTART;TZID=Australia/Sydney:20240115T090000
DTEND;TZID=Australia/Sydney:20240115T100000
SUMMARY:Sydney meeting
END:VEVENT
END:VCALENDAR
'''
          .replaceAll('\n', '\r\n');

      final expected =
          TZDateTime(getLocation('Australia/Sydney'), 2024, 1, 15, 9);
      final event = eventsFromIcs(ics).single;
      expect(event.start!.millisecondsSinceEpoch,
          expected.millisecondsSinceEpoch);
    });

    test('UnknownTzid_FallsBackWithoutThrowing', () {
      final ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:1@test
DTSTART;TZID=Not/ARealZone:20240115T090000
DTEND;TZID=Not/ARealZone:20240115T100000
SUMMARY:Unknown zone
END:VEVENT
END:VCALENDAR
'''
          .replaceAll('\n', '\r\n');

      expect(() => eventsFromIcs(ics), returnsNormally);
      expect(eventsFromIcs(ics).single.title, 'Unknown zone');
    });
  });

  group('Event.toIcs', () {
    test('NoEventId_GeneratesNonEmptyUid', () {
      final start = TZDateTime.utc(2024, 1, 1, 9);
      final event = Event('fakeCalendarId',
          title: 'No id', start: start, end: start.add(const Duration(hours: 1)));

      final ics = event.toIcs();
      final uidLine =
          ics.split('\r\n').firstWhere((line) => line.startsWith('UID:'));
      expect(uidLine.substring('UID:'.length), isNotEmpty);
    });

    test('WithEventId_UsesItInUid', () {
      final start = TZDateTime.utc(2024, 1, 1, 9);
      final event = Event('fakeCalendarId',
          eventId: 'realEventId123',
          title: 'Has id',
          start: start,
          end: start.add(const Duration(hours: 1)));

      final ics = event.toIcs();
      expect(ics, contains('UID:realEventId123@device_calendar'));
    });
  });
}

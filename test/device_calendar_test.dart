import 'package:device_calendar/device_calendar.dart';
import 'package:device_calendar/src/common/error_codes.dart';
import 'package:device_calendar/src/common/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.builttoroam.com/device_calendar');
  var deviceCalendarPlugin = DeviceCalendarPlugin();

  final log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      print('Calling channel method ${methodCall.method}');
      log.add(methodCall);

      return null;
    });

    log.clear();
  });

  test('HasPermissions_Returns_Successfully', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return true;
    });

    final result = await deviceCalendarPlugin.hasPermissions();
    expect(result.isSuccess, true);
    expect(result.errors, isEmpty);
    expect(result.data, true);
  });

  test('RequestPermissions_Returns_Successfully', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return true;
    });

    final result = await deviceCalendarPlugin.requestPermissions();
    expect(result.isSuccess, true);
    expect(result.errors, isEmpty);
    expect(result.data, true);
  });

  test('RequestPermissions_Defaults_ToFullAccessLevel', () async {
    await deviceCalendarPlugin.requestPermissions();
    expect(log, <Matcher>[
      isMethodCall('requestPermissions', arguments: <String, dynamic>{
        'calendarAccessLevel': 'FULL',
      })
    ]);
  });

  test('RequestPermissions_WriteOnly_PassesAccessLevelArgument', () async {
    await deviceCalendarPlugin.requestPermissions(
      accessLevel: CalendarAccessLevel.writeOnly,
    );
    expect(log, <Matcher>[
      isMethodCall('requestPermissions', arguments: <String, dynamic>{
        'calendarAccessLevel': 'WRITE_ONLY',
      })
    ]);
  });

  test('RetrieveCalendars_Returns_Successfully', () async {
    const fakeCalendarName = 'fakeCalendarName';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '[{"id":"1","isReadOnly":false,"name":"$fakeCalendarName"}]';
    });

    final result = await deviceCalendarPlugin.retrieveCalendars();
    expect(result.isSuccess, true);
    expect(result.errors, isEmpty);
    expect(result.data, isNotNull);
    expect(result.data, isNotEmpty);
    expect(result.data?[0].name, fakeCalendarName);
  });

  test('RetrieveEvents_CalendarId_IsRequired', () async {
    const String? calendarId = null;
    const params = RetrieveEventsParams();

    final result =
        await deviceCalendarPlugin.retrieveEvents(calendarId, params);
    expect(result.isSuccess, false);
    expect(result.errors.length, greaterThan(0));
    expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
  });

  test('DeleteEvent_CalendarId_IsRequired', () async {
    const String? calendarId = null;
    const eventId = 'fakeEventId';

    final result = await deviceCalendarPlugin.deleteEvent(calendarId, eventId);
    expect(result.isSuccess, false);
    expect(result.errors.length, greaterThan(0));
    expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
  });

  test('DeleteEvent_EventId_IsRequired', () async {
    const calendarId = 'fakeCalendarId';
    const String? eventId = null;

    final result = await deviceCalendarPlugin.deleteEvent(calendarId, eventId);
    expect(result.isSuccess, false);
    expect(result.errors.length, greaterThan(0));
    expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
  });

  test('DeleteEvent_PassesArguments_Correctly', () async {
    const calendarId = 'fakeCalendarId';
    const eventId = 'fakeEventId';

    await deviceCalendarPlugin.deleteEvent(calendarId, eventId);
    expect(log, <Matcher>[
      isMethodCall('deleteEvent', arguments: <String, dynamic>{
        'calendarId': calendarId,
        'eventId': eventId
      })
    ]);
  });

  test('CreateEvent_Arguments_Invalid', () async {
    const String? fakeCalendarId = null;
    final event = Event(fakeCalendarId);

    final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
    expect(result!.isSuccess, false);
    expect(result.errors, isNotEmpty);
    expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
  });

  test('CreateEvent_Returns_Successfully', () async {
    const fakeNewEventId = 'fakeNewEventId';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return fakeNewEventId;
    });

    const fakeCalendarId = 'fakeCalendarId';
    final event = Event(fakeCalendarId);
    event.title = 'fakeEventTitle';
    event.start = TZDateTime.now(local);
    event.end = event.start!.add(const Duration(hours: 1));

    final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
    expect(result?.isSuccess, true);
    expect(result?.errors, isEmpty);
    expect(result?.data, isNotEmpty);
    expect(result?.data, fakeNewEventId);
  });

  test('UpdateEvent_Returns_Successfully', () async {
    const fakeNewEventId = 'fakeNewEventId';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      final arguments = methodCall.arguments as Map<dynamic, dynamic>;
      if (!arguments.containsKey('eventId') || arguments['eventId'] == null) {
        return null;
      }

      return fakeNewEventId;
    });

    const fakeCalendarId = 'fakeCalendarId';
    final event = Event(fakeCalendarId);
    event.eventId = 'fakeEventId';
    event.title = 'fakeEventTitle';
    event.start = TZDateTime.now(local);
    event.end = event.start!.add(const Duration(hours: 1));

    final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
    expect(result?.isSuccess, true);
    expect(result?.errors, isEmpty);
    expect(result?.data, isNotEmpty);
    expect(result?.data, fakeNewEventId);
  });

  test('Attendee_Serialises_Correctly', () async {
    final attendee = Attendee(
        name: 'Test Attendee',
        emailAddress: 'test@t.com',
        role: AttendeeRole.Required,
        isOrganiser: true);
    final stringAttendee = attendee.toJson();
    expect(stringAttendee, isNotNull);
    final newAttendee = Attendee.fromJson(stringAttendee);
    expect(newAttendee, isNotNull);
    expect(newAttendee.name, equals(attendee.name));
    expect(newAttendee.emailAddress, equals(attendee.emailAddress));
    expect(newAttendee.role, equals(attendee.role));
    expect(newAttendee.isOrganiser, equals(attendee.isOrganiser));
    expect(newAttendee.iosAttendeeDetails, isNull);
    expect(newAttendee.androidAttendeeDetails, isNull);
  });

  test('Event_Serializes_Correctly', () async {
    final startTime = TZDateTime(
        timeZoneDatabase.locations.entries.skip(20).first.value,
        1980,
        10,
        1,
        0,
        0,
        0);
    final endTime = TZDateTime(
        timeZoneDatabase.locations.entries.skip(21).first.value,
        1980,
        10,
        2,
        0,
        0,
        0);
    final attendee = Attendee(
        name: 'Test Attendee',
        emailAddress: 'test@t.com',
        role: AttendeeRole.Required,
        isOrganiser: true);
    final recurrence = RecurrenceRule(frequency: Frequency.daily);
    final reminder = Reminder(minutes: 10);
    var event = Event('calendarId',
        eventId: 'eventId',
        title: 'Test Event',
        start: startTime,
        location: 'Seattle, Washington',
        url: Uri.dataFromString('http://www.example.com'),
        end: endTime,
        attendees: [attendee],
        description: 'Test description',
        recurrenceRule: recurrence,
        reminders: [reminder],
        availability: Availability.Busy,
        status: EventStatus.Confirmed);
    event.updateEventColor(EventColor(0xffff00ff, 1));

    final stringEvent = event.toJson();
    expect(stringEvent, isNotNull);
    final newEvent = Event.fromJson(stringEvent);
    expect(newEvent, isNotNull);
    expect(newEvent.calendarId, equals(event.calendarId));
    expect(newEvent.eventId, equals(event.eventId));
    expect(newEvent.title, equals(event.title));
    expect(newEvent.start!.millisecondsSinceEpoch,
        equals(event.start!.millisecondsSinceEpoch));
    expect(newEvent.end!.millisecondsSinceEpoch,
        equals(event.end!.millisecondsSinceEpoch));
    expect(newEvent.description, equals(event.description));
    expect(newEvent.url, equals(event.url));
    expect(newEvent.location, equals(event.location));
    expect(newEvent.attendees, isNotNull);
    expect(newEvent.attendees?.length, equals(1));
    expect(newEvent.recurrenceRule, isNotNull);
    expect(newEvent.recurrenceRule?.frequency,
        equals(event.recurrenceRule?.frequency));
    expect(newEvent.reminders, isNotNull);
    expect(newEvent.reminders?.length, equals(1));
    expect(newEvent.availability, equals(event.availability));
    expect(newEvent.status, equals(event.status));
    expect(newEvent.color, equals(event.color));
    expect(newEvent.colorKey, equals(event.colorKey));
  });

  test('Event_OriginalInstanceTime_SerializesWriteOnly', () async {
    final instanceTime = TZDateTime.utc(1980, 10, 1);
    final event = Event('calendarId',
        eventId: 'eventId', originalInstanceTime: instanceTime);

    expect(event.toJson()['originalInstanceTime'],
        equals(instanceTime.millisecondsSinceEpoch));

    // Write-only: it's never present in a server/plugin JSON response, so
    // fromJson has nothing to read it back from.
    final roundTripped = Event.fromJson(event.toJson());
    expect(roundTripped.originalInstanceTime, isNull);
  });

  group('requestPermissions/hasPermissions error paths', () {
    test('RequestPermissions_PlatformException_MapsToResultError', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERR', message: 'boom');
      });

      final result = await deviceCalendarPlugin.requestPermissions();
      expect(result.isSuccess, false);
      expect(result.data, isNull);
      // Was previously swallowed silently (see git history / TESTING_PLAN.md):
      // _invokeChannelMethod's catch block special-cased `e is
      // PlatformException` to only debugPrint it, never reaching
      // _parsePlatformExceptionAndUpdateResult. Fixed so every caught
      // throwable now maps to a ResultError.
      expect(result.hasErrors, true);
      expect(result.errors.single.errorCode, equals(ErrorCodes.platformSpecific));
      expect(result.errors.single.errorMessage, contains('ERR'));
      expect(result.errors.single.errorMessage, contains('boom'));
    });

    test('RetrieveEvents_NullChannelResponse_MapsToResultErrorNotCrash',
        () async {
      // Was previously an unhandled crash: the catch block's `e as
      // Exception?` threw a TypeError whenever `e` wasn't itself an
      // Exception. A null channel response makes evaluateResponse's
      // `json.decode(null)` throw a real TypeError, which is exactly such
      // a case -- this used to blow up instead of returning a Result.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });

      final result = await deviceCalendarPlugin
          .retrieveEvents('fakeCalendarId', const RetrieveEventsParams(eventIds: ['1']));
      expect(result.isSuccess, false);
      expect(result.errors.single.errorCode, equals(ErrorCodes.generic));
    });

    test('HasPermissions_Failure_ReturnsFalseResult', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return false;
      });

      final result = await deviceCalendarPlugin.hasPermissions();
      // isSuccess reflects "the channel call completed", not "permission
      // granted" -- data == false still satisfies `data != null`.
      expect(result.isSuccess, true);
      expect(result.data, false);
    });
  });

  group('retrieveCalendars', () {
    test('RetrieveCalendars_EmptyList_ReturnsEmptyNotNull', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return '[]';
      });

      final result = await deviceCalendarPlugin.retrieveCalendars();
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data, isEmpty);
    });

    test('RetrieveCalendars_MalformedJson_ReturnsGenericErrorNotCrash',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return 'not valid json {{{';
      });

      final result = await deviceCalendarPlugin.retrieveCalendars();
      // json.decode inside evaluateResponse throws FormatException, which is
      // neither ArgumentError nor PlatformException, so it falls through to
      // the generic-Exception branch of _parsePlatformExceptionAndUpdateResult.
      expect(result.isSuccess, false);
      expect(result.hasErrors, true);
      expect(result.errors.single.errorCode, equals(ErrorCodes.generic));
    });
  });

  group('retrieveEvents', () {
    test('RetrieveEvents_EventIdsOnly_SkipsDateValidation', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return '[]';
      });
      const calendarId = 'fakeCalendarId';
      const params = RetrieveEventsParams(eventIds: ['1', '2']);

      final result =
          await deviceCalendarPlugin.retrieveEvents(calendarId, params);
      expect(result.isSuccess, true); // no *validation* error was raised
      expect(result.errors, isEmpty);
      expect(log, <Matcher>[
        isMethodCall('retrieveEvents', arguments: <String, dynamic>{
          'calendarId': calendarId,
          'startDate': null,
          'endDate': null,
          'eventIds': ['1', '2'],
        })
      ]);
    });

    test('RetrieveEvents_NoEventIdsNoDates_Invalid', () async {
      const calendarId = 'fakeCalendarId';
      const params = RetrieveEventsParams();

      final result =
          await deviceCalendarPlugin.retrieveEvents(calendarId, params);
      expect(result.isSuccess, false);
      expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });

    test('RetrieveEvents_OnlyStartDate_Invalid', () async {
      const calendarId = 'fakeCalendarId';
      final params = RetrieveEventsParams(startDate: DateTime(2024, 1, 1));

      final result =
          await deviceCalendarPlugin.retrieveEvents(calendarId, params);
      expect(result.isSuccess, false);
      expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });

    test('RetrieveEvents_StartAfterEnd_Invalid', () async {
      const calendarId = 'fakeCalendarId';
      final params = RetrieveEventsParams(
        startDate: DateTime(2024, 1, 2),
        endDate: DateTime(2024, 1, 1),
      );

      final result =
          await deviceCalendarPlugin.retrieveEvents(calendarId, params);
      expect(result.isSuccess, false);
      expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });

    test('RetrieveEvents_ValidDateRange_PassesMillisecondArgs', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return '[]';
      });
      const calendarId = 'fakeCalendarId';
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 2);
      final params = RetrieveEventsParams(startDate: startDate, endDate: endDate);

      await deviceCalendarPlugin.retrieveEvents(calendarId, params);
      expect(log, <Matcher>[
        isMethodCall('retrieveEvents', arguments: <String, dynamic>{
          'calendarId': calendarId,
          'startDate': startDate.millisecondsSinceEpoch,
          'endDate': endDate.millisecondsSinceEpoch,
          'eventIds': null,
        })
      ]);
    });

    test('RetrieveEvents_SuccessResponse_ParsesEventList', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return '[{"eventId":"1","calendarId":"fakeCalendarId","eventTitle":"Test"}]';
      });

      const calendarId = 'fakeCalendarId';
      final params = RetrieveEventsParams(eventIds: const ['1']);
      final result =
          await deviceCalendarPlugin.retrieveEvents(calendarId, params);
      expect(result.isSuccess, true);
      expect(result.data, hasLength(1));
      expect(result.data!.first.eventId, '1');
      expect(result.data!.first.title, 'Test');
    });
  });

  group('deleteEventInstance', () {
    test('DeleteEventInstance_AllArgsProvided_PassesThroughCorrectly',
        () async {
      const calendarId = 'fakeCalendarId';
      const eventId = 'fakeEventId';
      final startDate = DateTime(2024, 1, 1).millisecondsSinceEpoch;
      final endDate = DateTime(2024, 1, 2).millisecondsSinceEpoch;

      await deviceCalendarPlugin.deleteEventInstance(
          calendarId, eventId, startDate, endDate, true);
      expect(log, <Matcher>[
        isMethodCall('deleteEventInstance', arguments: <String, dynamic>{
          'calendarId': calendarId,
          'eventId': eventId,
          'eventStartDate': startDate,
          'eventEndDate': endDate,
          'followingInstances': true,
        })
      ]);
    });

    test('DeleteEventInstance_CalendarIdMissing_Invalid', () async {
      final result = await deviceCalendarPlugin.deleteEventInstance(
          null, 'fakeEventId', null, null, false);
      expect(result.isSuccess, false);
      expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });

    test('DeleteEventInstance_EventIdMissing_Invalid', () async {
      final result = await deviceCalendarPlugin.deleteEventInstance(
          'fakeCalendarId', null, null, null, false);
      expect(result.isSuccess, false);
      expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });
  });

  group('createOrUpdateEvent', () {
    test('CreateOrUpdateEvent_NullEvent_ReturnsNull', () async {
      final result = await deviceCalendarPlugin.createOrUpdateEvent(null);
      expect(result, isNull);
    });

    test('CreateOrUpdateEvent_AllDay_CalendarIdEmpty_UsesAllDayErrorMessage',
        () async {
      final event = Event('', allDay: true, title: 'Title')
        ..start = TZDateTime.now(local);

      final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
      expect(result!.isSuccess, false);
      expect(
        result.errors[0].errorMessage,
        equals(
            ErrorMessages.createOrUpdateEventInvalidArgumentsMessageAllDay),
      );
    });

    test(
        'CreateOrUpdateEvent_NonAllDay_StartAfterEnd_UsesNonAllDayErrorMessage',
        () async {
      final start = TZDateTime.now(local);
      final event = Event('fakeCalendarId',
          allDay: false, start: start, end: start.subtract(const Duration(hours: 1)));

      final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
      expect(result!.isSuccess, false);
      expect(
        result.errors[0].errorMessage,
        equals(ErrorMessages.createOrUpdateEventInvalidArgumentsMessage),
      );
    });

    test('CreateOrUpdateEvent_AllDay_NormalizesStartEndToMidnight_NonAndroid',
        () async {
      // This test host isn't Android (Platform.isAndroid == false), so this
      // exercises the non-Android normalization branch only; the Android
      // branch needs an actual Android runtime and is integration-test-only
      // coverage (see TESTING_PLAN.md section 5).
      //
      // The non-Android branch builds midnight via the platform-native
      // `DateTime(y, m, d, 0, 0, 0)` constructor (host-local wall clock, NOT
      // the timezone package's `local`) and then reinterprets that instant
      // in the event's own TZ location. That means the exact instant this
      // produces is coupled to the test host's OS timezone -- asserting a
      // literal hour of 0 is only correct when the host OS TZ happens to
      // match the event's TZ (it doesn't in this container: host is
      // America/New_York, event is Australia/Sydney). So this test mirrors
      // the same formula independently rather than hard-coding an hour,
      // which still catches a real regression (e.g. switching to a UTC- or
      // TZDateTime-relative midnight) without being flaky across hosts.
      final sydney = getLocation('Australia/Sydney');
      final start = TZDateTime(sydney, 2024, 3, 10, 14, 30);
      final end = TZDateTime(sydney, 2024, 3, 11, 9, 15);
      final event = Event('fakeCalendarId',
          allDay: true, title: 'Title', start: start, end: end);

      final expectedStart =
          TZDateTime.from(DateTime(start.year, start.month, start.day), sydney);
      final expectedEnd =
          TZDateTime.from(DateTime(end.year, end.month, end.day), sydney);

      await deviceCalendarPlugin.createOrUpdateEvent(event);

      expect(event.start, expectedStart);
      expect(event.end, expectedEnd);
    });
  });

  group('createOrUpdateEvents', () {
    test('CreateOrUpdateEvents_EmptyList_ReturnsEmptySuccessWithoutChannelCall',
        () async {
      final result = await deviceCalendarPlugin.createOrUpdateEvents([]);
      expect(result.hasErrors, false);
      expect(result.data, isEmpty);
      expect(log, isEmpty);
    });

    test('CreateOrUpdateEvents_InvalidEventAtIndex_FailsFastNoChannelCall',
        () async {
      final start = TZDateTime.now(local);
      final valid = Event('fakeCalendarId',
          title: 'Valid', start: start, end: start.add(const Duration(hours: 1)));
      final invalid = Event('', allDay: true, title: 'Invalid')
        ..start = start;
      final alsoValid = Event('fakeCalendarId',
          title: 'AlsoValid',
          start: start,
          end: start.add(const Duration(hours: 1)));

      final result = await deviceCalendarPlugin
          .createOrUpdateEvents([valid, invalid, alsoValid]);
      expect(result.hasErrors, true);
      expect(result.errors.single.errorCode, equals(ErrorCodes.invalidArguments));
      expect(result.errors.single.errorMessage, contains('index 1'));
      expect(result.errors.single.errorMessage,
          contains(ErrorMessages.createOrUpdateEventInvalidArgumentsMessageAllDay));
      // Fail-fast validates every event before touching the channel at all --
      // not even the valid event before the bad one should be sent.
      expect(log, isEmpty);
    });

    test('CreateOrUpdateEvents_AllValid_ReturnsIdsInOrder_OneChannelCallPerEvent',
        () async {
      var callCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        callCount++;
        return 'fakeEventId$callCount';
      });

      final start = TZDateTime.now(local);
      final first = Event('fakeCalendarId',
          title: 'First', start: start, end: start.add(const Duration(hours: 1)));
      final second = Event('fakeCalendarId',
          title: 'Second', start: start, end: start.add(const Duration(hours: 1)));

      final result = await deviceCalendarPlugin.createOrUpdateEvents([first, second]);
      expect(result.hasErrors, false);
      expect(result.data, ['fakeEventId1', 'fakeEventId2']);
      expect(log, hasLength(2));
      expect(log.every((call) => call.method == 'createOrUpdateEvent'), true);
    });

    test('CreateOrUpdateEvents_ChannelFailsPartway_StopsAndReturnsError',
        () async {
      var callCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        callCount++;
        if (callCount == 2) {
          throw PlatformException(code: 'ERR', message: 'boom');
        }
        return 'fakeEventId$callCount';
      });

      final start = TZDateTime.now(local);
      final events = List.generate(
        3,
        (i) => Event('fakeCalendarId',
            title: 'Event$i', start: start, end: start.add(const Duration(hours: 1))),
      );

      final result = await deviceCalendarPlugin.createOrUpdateEvents(events);
      expect(result.hasErrors, true);
      expect(result.errors.single.errorCode, equals(ErrorCodes.platformSpecific));
      // Only the first (successful) and second (failed) events reach the
      // channel; the third is never attempted once the second fails.
      expect(log, hasLength(2));
    });
  });

  group('retrieveFreeBusy', () {
    test('EmptyCalendarIds_ReturnsEmptyWithoutChannelCall', () async {
      final result = await deviceCalendarPlugin.retrieveFreeBusy(
          [], DateTime(2024, 1, 1), DateTime(2024, 1, 2));
      expect(result.hasErrors, false);
      expect(result.data, isEmpty);
      expect(log, isEmpty);
    });

    test('FiltersOutFreeEvents_AndMergesTheRest', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return '['
            '{"eventId":"1","calendarId":"cal1","eventTitle":"Busy",'
            '"eventStartDate":${DateTime(2024, 1, 1, 9).millisecondsSinceEpoch},'
            '"eventEndDate":${DateTime(2024, 1, 1, 10).millisecondsSinceEpoch},'
            '"availability":"BUSY"},'
            '{"eventId":"2","calendarId":"cal1","eventTitle":"Free",'
            '"eventStartDate":${DateTime(2024, 1, 1, 9, 30).millisecondsSinceEpoch},'
            '"eventEndDate":${DateTime(2024, 1, 1, 9, 45).millisecondsSinceEpoch},'
            '"availability":"FREE"},'
            '{"eventId":"3","calendarId":"cal1","eventTitle":"Tentative",'
            '"eventStartDate":${DateTime(2024, 1, 1, 10).millisecondsSinceEpoch},'
            '"eventEndDate":${DateTime(2024, 1, 1, 11).millisecondsSinceEpoch},'
            '"availability":"TENTATIVE"}'
            ']';
      });

      final result = await deviceCalendarPlugin.retrieveFreeBusy(
          ['cal1'], DateTime(2024, 1, 1), DateTime(2024, 1, 2));
      expect(result.hasErrors, false);
      // The Busy (9-10) and Tentative (10-11) events touch at 10 and merge
      // into one period; the Free event in between never becomes a period.
      expect(result.data, hasLength(1));
      expect(result.data!.single.status, Availability.Busy);
      expect(result.data!.single.start.millisecondsSinceEpoch,
          DateTime(2024, 1, 1, 9).millisecondsSinceEpoch);
      expect(result.data!.single.end.millisecondsSinceEpoch,
          DateTime(2024, 1, 1, 11).millisecondsSinceEpoch);
    });

    test('QueriesEachCalendarSeparately_CombinesResults', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        final calendarId = (methodCall.arguments
            as Map<dynamic, dynamic>)['calendarId'];
        if (calendarId == 'cal1') {
          return '[{"eventId":"1","calendarId":"cal1","eventTitle":"A",'
              '"eventStartDate":${DateTime(2024, 1, 1, 9).millisecondsSinceEpoch},'
              '"eventEndDate":${DateTime(2024, 1, 1, 10).millisecondsSinceEpoch},'
              '"availability":"BUSY"}]';
        }
        return '[{"eventId":"2","calendarId":"cal2","eventTitle":"B",'
            '"eventStartDate":${DateTime(2024, 1, 1, 14).millisecondsSinceEpoch},'
            '"eventEndDate":${DateTime(2024, 1, 1, 15).millisecondsSinceEpoch},'
            '"availability":"BUSY"}]';
      });

      final result = await deviceCalendarPlugin.retrieveFreeBusy(
          ['cal1', 'cal2'], DateTime(2024, 1, 1), DateTime(2024, 1, 2));
      expect(result.hasErrors, false);
      expect(result.data, hasLength(2));
      expect(log, hasLength(2));
    });

    test('CalendarRetrievalFails_FailsWholeCall', () async {
      final result = await deviceCalendarPlugin.retrieveFreeBusy(
          [''], DateTime(2024, 1, 1), DateTime(2024, 1, 2));
      // Empty calendarId fails DeviceCalendarPlugin.retrieveEvents's own
      // validation before ever touching the channel.
      expect(result.hasErrors, true);
      expect(result.errors.single.errorCode, equals(ErrorCodes.invalidArguments));
    });
  });

  group('createCalendar', () {
    test('CreateCalendar_NameNullOrEmpty_Invalid', () async {
      final resultNull = await deviceCalendarPlugin.createCalendar(null);
      expect(resultNull.isSuccess, false);
      expect(resultNull.errors[0].errorCode, equals(ErrorCodes.invalidArguments));

      final resultEmpty = await deviceCalendarPlugin.createCalendar('');
      expect(resultEmpty.isSuccess, false);
      expect(
          resultEmpty.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });

    test('CreateCalendar_ColorNull_DefaultsToRed', () async {
      await deviceCalendarPlugin.createCalendar('Test Calendar');
      final arguments = log.single.arguments as Map<dynamic, dynamic>;
      expect(arguments['calendarColor'], '0x${Colors.red.toARGB32().toRadixString(16)}');
    });

    test('CreateCalendar_LocalAccountNameEmpty_DefaultsToDeviceCalendar',
        () async {
      await deviceCalendarPlugin.createCalendar('Test Calendar',
          localAccountName: '');
      final arguments = log.single.arguments as Map<dynamic, dynamic>;
      expect(arguments['localAccountName'], 'Device Calendar');
    });
  });

  group('deleteCalendar', () {
    test('DeleteCalendar_Success', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return true;
      });

      final result = await deviceCalendarPlugin.deleteCalendar('fakeCalendarId');
      expect(result.isSuccess, true);
      expect(result.data, true);
    });

    test('DeleteCalendar_CalendarIdInvalid', () async {
      final result = await deviceCalendarPlugin.deleteCalendar('');
      expect(result.isSuccess, false);
      expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });
  });

  test('ShowIosEventModal_PassesEventIdArgument', () async {
    const eventId = 'fakeEventId';
    await deviceCalendarPlugin.showiOSEventModal(eventId);
    expect(log, <Matcher>[
      isMethodCall('showiOSEventModal',
          arguments: <String, String>{'eventId': eventId})
    ]);
  });

  group('retrieveEventColors / retrieveCalendarColors (non-Android host)', () {
    // This test host is never Android, so only the `!Platform.isAndroid`
    // early-return branch of each method is reachable here. The
    // account-name-null and success-mapping branches require an actual
    // Android runtime and aren't covered by this suite -- documenting the
    // gap rather than skipping it silently, per TESTING_PLAN.md.
    test('RetrieveEventColors_NonAndroid_ReturnsNullWithoutChannelCall',
        () async {
      final colors =
          await deviceCalendarPlugin.retrieveEventColors(Calendar());
      expect(colors, isNull);
      expect(log, isEmpty);
    });

    test('RetrieveCalendarColors_NonAndroid_ReturnsEmptyWithoutChannelCall',
        () async {
      // Note: unlike retrieveEventColors (returns null), this one returns an
      // empty list on non-Android -- a real difference between the two
      // "same shape" methods, not an oversight in this test.
      final colors =
          await deviceCalendarPlugin.retrieveCalendarColors(Calendar());
      expect(colors, isEmpty);
      expect(log, isEmpty);
    });
  });

  group('updateCalendarColor', () {
    test('UpdateCalendarColor_CalendarIdNull_ReturnsFalseWithoutChannelCall',
        () async {
      final result =
          await deviceCalendarPlugin.updateCalendarColor(Calendar(id: null));
      expect(result, false);
      expect(log, isEmpty);
    });

    test('UpdateCalendarColor_BothColorArgsNull_ReturnsFalseWithoutChannelCall',
        () async {
      final result = await deviceCalendarPlugin
          .updateCalendarColor(Calendar(id: 'fakeCalendarId'));
      expect(result, false);
      expect(log, isEmpty);
    });

    test('UpdateCalendarColor_Success_UpdatesLocalCalendarColorField',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return true;
      });

      final calendar = Calendar(id: 'fakeCalendarId');
      final result = await deviceCalendarPlugin
          .updateCalendarColor(calendar, color: Colors.blue);
      expect(result, true);
      expect(calendar.color, Colors.blue.toARGB32());
    });

    test('UpdateCalendarColor_Failure_ReturnsFalse', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return false;
      });

      final calendar = Calendar(id: 'fakeCalendarId');
      final result = await deviceCalendarPlugin
          .updateCalendarColor(calendar, color: Colors.blue);
      expect(result, false);
      expect(calendar.color, isNull);
    });
  });

  group('updateAttendeeStatus', () {
    test('UpdateAttendeeStatus_CalendarIdMissing_Invalid', () async {
      final result = await deviceCalendarPlugin.updateAttendeeStatus(
          null, 'fakeEventId', 'attendee@test.com');
      expect(result.isSuccess, false);
      expect(result.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
      expect(
        result.errors[0].errorMessage,
        equals(ErrorMessages.invalidMissingCalendarId),
      );
      expect(log, isEmpty);
    });

    test('UpdateAttendeeStatus_EventIdMissingOrEmpty_Invalid', () async {
      final resultNull = await deviceCalendarPlugin.updateAttendeeStatus(
          'fakeCalendarId', null, 'attendee@test.com');
      expect(resultNull.isSuccess, false);
      expect(
          resultNull.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
      expect(
        resultNull.errors[0].errorMessage,
        equals(ErrorMessages.updateAttendeeStatusInvalidArgumentsMessage),
      );
      expect(log, isEmpty);

      final resultEmpty = await deviceCalendarPlugin.updateAttendeeStatus(
          'fakeCalendarId', '', 'attendee@test.com');
      expect(resultEmpty.isSuccess, false);
      expect(
          resultEmpty.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });

    test('UpdateAttendeeStatus_AttendeeEmailMissingOrEmpty_Invalid', () async {
      final resultNull = await deviceCalendarPlugin.updateAttendeeStatus(
          'fakeCalendarId', 'fakeEventId', null);
      expect(resultNull.isSuccess, false);
      expect(
          resultNull.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
      expect(
        resultNull.errors[0].errorMessage,
        equals(ErrorMessages.updateAttendeeStatusInvalidArgumentsMessage),
      );
      expect(log, isEmpty);

      final resultEmpty = await deviceCalendarPlugin.updateAttendeeStatus(
          'fakeCalendarId', 'fakeEventId', '');
      expect(resultEmpty.isSuccess, false);
      expect(
          resultEmpty.errors[0].errorCode, equals(ErrorCodes.invalidArguments));
    });

    test('UpdateAttendeeStatus_PassesArguments_Correctly', () async {
      const calendarId = 'fakeCalendarId';
      const eventId = 'fakeEventId';
      const attendeeEmail = 'attendee@test.com';

      // Test host is never Android (Platform.isAndroid == false), so only
      // the iosStatus branch of the platform-select is reachable here; the
      // androidStatus branch needs an Android runtime, same gap already
      // documented for the allDay-normalization test above.
      await deviceCalendarPlugin.updateAttendeeStatus(
        calendarId,
        eventId,
        attendeeEmail,
        androidStatus: AndroidAttendanceStatus.Accepted,
        iosStatus: IosAttendanceStatus.Declined,
      );
      expect(log, <Matcher>[
        isMethodCall('updateAttendeeStatus', arguments: <String, dynamic>{
          'calendarId': calendarId,
          'eventId': eventId,
          'attendeeEmail': attendeeEmail,
          'attendanceStatus': IosAttendanceStatus.Declined.index,
        })
      ]);
    });

    test('UpdateAttendeeStatus_NoStatusProvided_SendsNullAttendanceStatus',
        () async {
      const calendarId = 'fakeCalendarId';
      const eventId = 'fakeEventId';
      const attendeeEmail = 'attendee@test.com';

      await deviceCalendarPlugin.updateAttendeeStatus(
          calendarId, eventId, attendeeEmail);
      expect(log, <Matcher>[
        isMethodCall('updateAttendeeStatus', arguments: <String, dynamic>{
          'calendarId': calendarId,
          'eventId': eventId,
          'attendeeEmail': attendeeEmail,
          'attendanceStatus': null,
        })
      ]);
    });

    test('UpdateAttendeeStatus_Returns_Successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return true;
      });

      final result = await deviceCalendarPlugin.updateAttendeeStatus(
          'fakeCalendarId', 'fakeEventId', 'attendee@test.com',
          iosStatus: IosAttendanceStatus.Accepted);
      expect(result.isSuccess, true);
      expect(result.errors, isEmpty);
      expect(result.data, true);
    });

    test('UpdateAttendeeStatus_Returns_FalseWhenPlatformReportsNoMatch',
        () async {
      // iOS returns false (not an error) when attendeeEmail doesn't match
      // the current user's own participant -- documented platform gap, not
      // a failure.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return false;
      });

      final result = await deviceCalendarPlugin.updateAttendeeStatus(
          'fakeCalendarId', 'fakeEventId', 'someoneelse@test.com',
          iosStatus: IosAttendanceStatus.Accepted);
      expect(result.isSuccess, true);
      expect(result.data, false);
    });
  });

  group('onCalendarsChanged', () {
    const eventChannel =
        EventChannel('plugins.builttoroam.com/device_calendar_events');

    test('OnCalendarsChanged_NativeEvent_EmitsOnStream', () async {
      MockStreamHandlerEventSink? capturedSink;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) => capturedSink = events,
        ),
      );

      final events = <void>[];
      final subscription =
          deviceCalendarPlugin.onCalendarsChanged.listen(events.add);
      // Let the stream subscription's `listen` platform message land before
      // asserting the sink was captured.
      await Future<void>.delayed(Duration.zero);
      expect(capturedSink, isNotNull);

      capturedSink!.success(null);
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));

      await subscription.cancel();
    });

    test('OnCalendarsChanged_ReturnsSameBroadcastStreamOnRepeatedAccess',
        () async {
      // Repeated `.listen()`/`.cancel()` cycles across the app's lifetime
      // must not create a fresh EventChannel subscription each time -- that
      // would leak native ContentObserver/NSNotification registrations.
      expect(
        identical(
          deviceCalendarPlugin.onCalendarsChanged,
          deviceCalendarPlugin.onCalendarsChanged,
        ),
        true,
      );
    });
  });
}

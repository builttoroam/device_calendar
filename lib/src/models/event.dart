import 'dart:io';

import 'package:collection/collection.dart';

import '../../device_calendar.dart';
import '../common/error_messages.dart';

/// Corrects the wall-clock date of an all-day event's [start]/[end] as read
/// back from the native Android calendar provider (#535/#559/#323): the raw
/// millis represent midnight UTC of the intended calendar day, but the
/// timezone attached to them by the provider can be a non-UTC zone, so
/// reading `.year`/`.month`/`.day` directly can show the wrong day.
///
/// The fix re-derives the calendar day directly from the UTC millis (not
/// from `raw.year`/`.month`/`.day`, which read it through the possibly-wrong
/// zone) and constructs local midnight for that exact date. An earlier
/// version of this function instead subtracted the zone's current UTC
/// offset from the instant -- that assumes the offset at the raw instant
/// still applies once shifted to local midnight, which is false on the
/// UTC-calendar-day of a DST transition: e.g. Australia/Sydney's October
/// 2024 "spring forward" produced 2024-10-05 23:00 for an event intended as
/// 2024-10-06, an off-by-one-day result. See the brute-force property test
/// in event_test.dart that caught this.
///
/// Extracted as a pure function (rather than inlined behind
/// `Platform.isAndroid`) so both branches are unit-testable on any host.
({TZDateTime? start, TZDateTime? end}) normalizeAllDayDatesFromNative({
  required TZDateTime? start,
  required TZDateTime? end,
  required bool allDay,
  required bool isAndroid,
}) {
  if (!isAndroid || !allDay) {
    return (start: start, end: end);
  }
  // The Event End Date for allDay events is midnight of the day after the
  // last day, so subtract one day after re-deriving the correct date.
  return (
    start: _localMidnightOnUtcCalendarDay(start),
    end: _localMidnightOnUtcCalendarDay(end)
        ?.subtract(const Duration(days: 1)),
  );
}

TZDateTime? _localMidnightOnUtcCalendarDay(TZDateTime? raw) {
  if (raw == null) {
    return null;
  }
  final utcCalendarDay = DateTime.fromMillisecondsSinceEpoch(
      raw.millisecondsSinceEpoch,
      isUtc: true);
  return TZDateTime(
      raw.location, utcCalendarDay.year, utcCalendarDay.month, utcCalendarDay.day);
}

/// An event associated with a calendar
class Event {
  /// Read-only. The unique identifier for this event. This is auto-generated when a new event is created
  String? eventId;

  /// Read-only. The identifier of the calendar that this event is associated with
  String? calendarId;

  /// The title of this event
  String? title;

  /// The description for this event
  String? description;

  /// Indicates when the event starts
  TZDateTime? start;

  /// Indicates when the event ends
  TZDateTime? end;

  /// Indicates if this is an all-day event
  bool? allDay;

  /// The location of this event
  String? location;

  /// An URL for this event
  Uri? url;

  /// A list of attendees for this event
  List<Attendee?>? attendees;

  /// The recurrence rule for this event
  RecurrenceRule? recurrenceRule;

  /// A list of reminders (by minutes) for this event
  List<Reminder>? reminders;

  /// Indicates if this event counts as busy time, tentative, unavaiable or is still free time
  late Availability availability;

  /// Indicates if this event is of confirmed, canceled, tentative or none status
  EventStatus? status;

  /// Read-only. Android exclusive. Updatable only using [Event.updateEventColor] with color from [DeviceCalendarPlugin.retrieveEventColors]
  int? color;

  /// Read-only. Android exclusive. Updatable only using [Event.updateEventColor] with color from [DeviceCalendarPlugin.retrieveEventColors]
  int? colorKey;

  /// Write-only. Android exclusive. Set this to the start time of the
  /// recurring instance being edited to create/update a single-instance
  /// exception instead of the whole recurring series. Ignored on iOS and
  /// ignored if [recurrenceRule] isn't set on the underlying event.
  TZDateTime? originalInstanceTime;

  ///Note for development:
  ///
  ///JSON field names are coded in dart, swift and kotlin to facilitate data exchange.
  ///Make sure all locations are updated if changes needed to be made.
  ///Swift:
  ///`ios/Classes/SwiftDeviceCalendarPlugin.swift`
  ///Kotlin:
  ///`android/src/main/kotlin/com/builttoroam/devicecalendar/models/Event.kt`
  ///`android/src/main/kotlin/com/builttoroam/devicecalendar/CalendarDelegate.kt`
  ///`android/src/main/kotlin/com/builttoroam/devicecalendar/DeviceCalendarPlugin.kt`
  Event(this.calendarId,
      {this.eventId,
      this.title,
      this.start,
      this.end,
      this.description,
      this.attendees,
      this.recurrenceRule,
      this.reminders,
      this.availability = Availability.Busy,
      this.location,
      this.url,
      this.allDay = false,
      this.status,
      this.originalInstanceTime});

  ///Get Event from JSON.
  ///
  ///Sample JSON:
  ///{calendarId: 00, eventId: 0000, eventTitle: Sample Event, eventDescription: This is a sample event, eventStartDate: 1563719400000, eventStartTimeZone: Asia/Hong_Kong, eventEndDate: 1640532600000, eventEndTimeZone: Asia/Hong_Kong, eventAllDay: false, eventLocation: Yuenlong Station, eventURL: null, availability: BUSY, attendees: [{name: commonfolk, emailAddress: total.loss@hong.com, role: 1, isOrganizer: false, attendanceStatus: 3}], reminders: [{minutes: 39}]}
  Event.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }
    String? foundUrl;
    String? startLocationName;
    String? endLocationName;
    int? startTimestamp;
    int? endTimestamp;
    const legacyKeys = [
      'title',
      'description',
      'start',
      'end',
      'startTimeZone',
      'endTimeZone',
      'allDay',
      'location',
      'url',
    ];
    final legacyJSON = legacyKeys.any((key) => json[key] != null);

    eventId = json['eventId'];
    calendarId = json['calendarId'];
    title = json['eventTitle'];
    description = json['eventDescription'];
    color = json['eventColor'];
    colorKey = json['eventColorKey'];

    startTimestamp = json['eventStartDate'];
    startLocationName = json['eventStartTimeZone'];
    var startTimeZone = timeZoneDatabase.locations[startLocationName];
    startTimeZone ??= local;
    start = startTimestamp != null
        ? TZDateTime.fromMillisecondsSinceEpoch(startTimeZone, startTimestamp)
        : TZDateTime.now(local);

    endTimestamp = json['eventEndDate'];
    endLocationName = json['eventEndTimeZone'];
    var endLocation = timeZoneDatabase.locations[endLocationName];
    endLocation ??= startTimeZone;
    end = endTimestamp != null
        ? TZDateTime.fromMillisecondsSinceEpoch(endLocation, endTimestamp)
        : TZDateTime.now(local);
    allDay = json['eventAllDay'] ?? false;
    final normalized = normalizeAllDayDatesFromNative(
      start: start,
      end: end,
      allDay: allDay ?? false,
      isAndroid: Platform.isAndroid,
    );
    start = normalized.start;
    end = normalized.end;
    location = json['eventLocation'];
    availability = parseStringToAvailability(json['availability']);
    status = parseStringToEventStatus(json['eventStatus']);

    foundUrl = json['eventURL']?.toString();
    if (foundUrl?.isEmpty ?? true) {
      url = null;
    } else {
      url = Uri.tryParse(foundUrl as String);
    }

    if (json['attendees'] != null) {
      attendees = json['attendees'].map<Attendee>((decodedAttendee) {
        return Attendee.fromJson(decodedAttendee);
      }).toList();
    }

    if (json['organizer'] != null) {
      // Getting and setting an organiser for iOS
      var organiser = Attendee.fromJson(json['organizer']);

      var attendee = attendees?.firstWhereOrNull((at) =>
          at?.name == organiser.name &&
          at?.emailAddress == organiser.emailAddress);
      if (attendee != null) {
        attendee.isOrganiser = true;
      }
    }

    if (json['recurrenceRule'] != null) {
      // debugPrint(
      //     "EVENT_MODEL: $title; START: $start, END: $end RRULE = ${json['recurrenceRule']}");

      //TODO: If we don't cast it to List<String>, the rrule package throws an error as it detects it as List<dynamic> ('Invalid JSON in 'byday'')
      if (json['recurrenceRule']['byday'] != null) {
        json['recurrenceRule']['byday'] =
            json['recurrenceRule']['byday'].cast<String>();
      }
      //TODO: If we don't cast it to List<int>, the rrule package throws an error as it detects it as List<dynamic> ('Invalid JSON in 'bymonthday'')
      if (json['recurrenceRule']['bymonthday'] != null) {
        json['recurrenceRule']['bymonthday'] =
            json['recurrenceRule']['bymonthday'].cast<int>();
      }
      //TODO: If we don't cast it to List<int>, the rrule package throws an error as it detects it as List<dynamic> ('Invalid JSON in 'byyearday'')
      if (json['recurrenceRule']['byyearday'] != null) {
        json['recurrenceRule']['byyearday'] =
            json['recurrenceRule']['byyearday'].cast<int>();
      }
      //TODO: If we don't cast it to List<int>, the rrule package throws an error as it detects it as List<dynamic> ('Invalid JSON in 'byweekno'')
      if (json['recurrenceRule']['byweekno'] != null) {
        json['recurrenceRule']['byweekno'] =
            json['recurrenceRule']['byweekno'].cast<int>();
      }
      //TODO: If we don't cast it to List<int>, the rrule package throws an error as it detects it as List<dynamic> ('Invalid JSON in 'bymonth'')
      if (json['recurrenceRule']['bymonth'] != null) {
        json['recurrenceRule']['bymonth'] =
            json['recurrenceRule']['bymonth'].cast<int>();
      }
      //TODO: If we don't cast it to List<int>, the rrule package throws an error as it detects it as List<dynamic> ('Invalid JSON in 'bysetpos'')
      if (json['recurrenceRule']['bysetpos'] != null) {
        json['recurrenceRule']['bysetpos'] =
            json['recurrenceRule']['bysetpos'].cast<int>();
      }
      // debugPrint("EVENT_MODEL: $title; RRULE = ${json['recurrenceRule']}");
      recurrenceRule = RecurrenceRule.fromJson(json['recurrenceRule']);
      // debugPrint("EVENT_MODEL_recurrenceRule: ${recurrenceRule.toString()}");
    }

    if (json['reminders'] != null) {
      reminders = json['reminders'].map<Reminder>((decodedReminder) {
        return Reminder.fromJson(decodedReminder);
      }).toList();
    }
    if (legacyJSON) {
      throw const FormatException(
          'legacy JSON detected. Please update your current JSONs as they may not be supported later on.');
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['calendarId'] = calendarId;
    data['eventId'] = eventId;
    data['eventTitle'] = title;
    data['eventDescription'] = description;
    data['eventStartDate'] = start?.millisecondsSinceEpoch ??
        TZDateTime.now(local).millisecondsSinceEpoch;
    data['eventStartTimeZone'] = start?.location.name;
    data['eventEndDate'] = end?.millisecondsSinceEpoch ??
        TZDateTime.now(local).millisecondsSinceEpoch;
    data['eventEndTimeZone'] = end?.location.name;
    data['eventAllDay'] = allDay;
    data['eventLocation'] = location;
    data['eventURL'] = url?.toString();
    data['availability'] = availability.enumToString;
    data['eventStatus'] = status?.enumToString;
    data['eventColor'] = color;
    data['eventColorKey'] = colorKey;
    data['originalInstanceTime'] = originalInstanceTime?.millisecondsSinceEpoch;

    if (attendees != null) {
      data['attendees'] = attendees?.map((a) => a?.toJson()).toList();
    }

    if (attendees != null) {
      data['organizer'] =
          attendees?.firstWhereOrNull((a) => a!.isOrganiser)?.toJson();
    }

    if (recurrenceRule != null) {
      data['recurrenceRule'] = recurrenceRule?.toJson();
      // print("EVENT_TO_JSON_RRULE: ${recurrenceRule?.toJson()}");
    }

    if (reminders != null) {
      data['reminders'] = reminders?.map((r) => r.toJson()).toList();
    }
    // debugPrint("EVENT_TO_JSON: $data");
    return data;
  }

  Availability parseStringToAvailability(String? value) {
    var testValue = value?.toUpperCase();
    switch (testValue) {
      case 'BUSY':
        return Availability.Busy;
      case 'FREE':
        return Availability.Free;
      case 'TENTATIVE':
        return Availability.Tentative;
      case 'UNAVAILABLE':
        return Availability.Unavailable;
    }
    return Availability.Busy;
  }

  EventStatus? parseStringToEventStatus(String? value) {
    var testValue = value?.toUpperCase();
    switch (testValue) {
      case 'CONFIRMED':
        return EventStatus.Confirmed;
      case 'TENTATIVE':
        return EventStatus.Tentative;
      case 'CANCELED':
        return EventStatus.Canceled;
      case 'NONE':
        return EventStatus.None;
    }
    return null;
  }

  bool updateStartLocation(String? newStartLocation) {
    if (newStartLocation == null) return false;
    try {
      var location = timeZoneDatabase.get(newStartLocation);
      start = TZDateTime.from(start as TZDateTime, location);
      return true;
    } on LocationNotFoundException {
      return false;
    }
  }

  bool updateEndLocation(String? newEndLocation) {
    if (newEndLocation == null) return false;
    try {
      var location = timeZoneDatabase.get(newEndLocation);
      end = TZDateTime.from(end as TZDateTime, location);
      return true;
    } on LocationNotFoundException {
      return false;
    }
  }

  void updateEventColor(EventColor? eventColor) {
    color = eventColor?.color;
    colorKey = eventColor?.colorKey;
  }
}

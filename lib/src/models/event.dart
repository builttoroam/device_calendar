import 'dart:io';

import 'package:collection/collection.dart';
import 'event_color.dart';

import '../../device_calendar.dart';
import '../common/error_messages.dart';

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
      this.status});

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
    bool legacyJSON = false;
    var legacyName = {
      title: 'title',
      description: 'description',
      startTimestamp: 'start',
      endTimestamp: 'end',
      startLocationName: 'startTimeZone',
      endLocationName: 'endTimeZone',
      allDay: 'allDay',
      location: 'location',
      foundUrl: 'url',
    };
    legacyName.forEach((key, value) {
      if (json[value] != null) {
        key = json[value];
        legacyJSON = true;
      }
    });

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
    if (Platform.isAndroid && (allDay ?? false)) {
      // On Android, the datetime in an allDay event is adjusted to local
      // timezone, which can result in the wrong day, so we need to bring the
      // date back to midnight UTC to get the correct date
      var startOffset = start?.timeZoneOffset.inMilliseconds ?? 0;
      var endOffset = end?.timeZoneOffset.inMilliseconds ?? 0;
      // subtract the offset to get back to midnight on the correct date
      start = start?.subtract(Duration(milliseconds: startOffset));
      end = end?.subtract(Duration(milliseconds: endOffset));
      // The Event End Date for allDay events is midnight of the next day, so
      // subtract one day
      end = end?.subtract(const Duration(days: 1));
    }
    location = json['eventLocation'];
    availability = parseStringToAvailability(json['availability']);
    status = parseStringToEventStatus(json['eventStatus']);

    foundUrl = json['eventURL']?.toString();
    if (foundUrl?.isEmpty ?? true) {
      url = null;
    } else {
      url = Uri.dataFromString(foundUrl as String);
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
    data['eventURL'] = url?.data?.contentText;
    data['availability'] = availability.enumToString;
    data['eventStatus'] = status?.enumToString;
    data['eventColor'] = color;
    data['eventColorKey'] = colorKey;

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
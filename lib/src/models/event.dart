import '../../device_calendar.dart';
import '../common/calendar_enums.dart';
import '../common/error_messages.dart';
import 'attendee.dart';
import 'recurrence_rule.dart';
import 'package:timezone/timezone.dart';

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
  TZDateTime start;

  /// Indicates when the event ends
  TZDateTime end;

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
  Availability? availability;

  Event(this.calendarId,
      {this.eventId,
      this.title,
      this.start,
      this.end,
      this.description,
      this.attendees,
      this.recurrenceRule,
      this.reminders,
      this.availability,
      this.allDay = false});

  Event.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    eventId = json['eventId'];
    calendarId = json['calendarId'];
    title = json['title'];
    description = json['description'];
    final String startAsIso8601String = json['startAsIso8601String'];
    final String startLocationName = json['startLocation'];
    var startLocation = timeZoneDatabase.locations[startLocationName];
    startLocation ??= local;
    start = (startAsIso8601String?.isNotEmpty == true)
        ? TZDateTime.parse(startLocation, startAsIso8601String)
        : TZDateTime.now(local);

    final String endAsIso8601String = json['endAsIso8601String'];
    final String endLocationName = json['endLocation'];
    var endLocation = timeZoneDatabase.locations[endLocationName];
    endLocation ??= local;
    end = (endAsIso8601String?.isNotEmpty == true)
        ? TZDateTime.parse(endLocation, endAsIso8601String)
        : TZDateTime.now(local);

    allDay = json['isAllDay'];
    location = json['location'];

    var foundUrl = json['url']?.toString();
    if (foundUrl?.isEmpty ?? true) {
      url = null;
    } else {
      url = Uri.dataFromString(foundUrl as String);
    }

    availability = parseStringToAvailability(json['availability']);

    if (json['attendees'] != null) {
      attendees = json['attendees'].map<Attendee>((decodedAttendee) {
        return Attendee.fromJson(decodedAttendee);
      }).toList();
    }

    if (json['organizer'] != null) {
      // Getting and setting an organiser for iOS
      var organiser = Attendee.fromJson(json['organizer']);

      var attendee = attendees?.firstWhere(
          (at) =>
              at?.name == organiser.name &&
              at?.emailAddress == organiser.emailAddress);
      if (attendee != null) {
        attendee.isOrganiser = true;
      }
    }

    if (json['recurrenceRule'] != null) {
      recurrenceRule = RecurrenceRule.fromJson(json['recurrenceRule']);
    }

    if (json['reminders'] != null) {
      reminders = json['reminders'].map<Reminder>((decodedReminder) {
        return Reminder.fromJson(decodedReminder);
      }).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['eventId'] = eventId;
    data['calendarId'] = calendarId;
    data['title'] = title;
    data['description'] = description;
    data['startAsIso8601String'] = start.toIso8601String();
    data['startLocation'] = start.location.name;
    data['endAsIso8601String'] = end.toIso8601String();
    data['endLocation'] = end.location.name;
    data['isAllDay'] = allDay;
    data['location'] = location;
    data['url'] = url?.data?.contentText;
    data['availability'] = availability.enumToString;

    if (attendees != null) {
      data['attendees'] = attendees?.map((a) => a?.toJson()).toList();
    }

    if (attendees != null) {
      data['organizer'] = attendees.firstWhere((a) => a.isOrganiser)?.toJson();
    }

    if (recurrenceRule != null) {
      data['recurrenceRule'] = recurrenceRule?.toJson();
    }

    if (reminders != null) {
      data['reminders'] = reminders?.map((r) => r.toJson()).toList();
    }

    return data;
  }

  Availability parseStringToAvailability(String value) {
    var testValue = value.toUpperCase();
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
    return null;
  }

  bool updateStartLocation(String newStartLocation) {
    if (newStartLocation == null) return false;
    try {
      var location = timeZoneDatabase.get(newStartLocation);
      start = TZDateTime.from(start, location);
      return true;
    } on LocationNotFoundException {
      return false;
    }
  }

  bool updateEndLocation(String newEndLocation) {
    if (newEndLocation == null) return false;
    try {
      var location = timeZoneDatabase.get(newEndLocation);
      end = TZDateTime.from(end, location);
      return true;
    } on LocationNotFoundException {
      return false;
    }
  }
}

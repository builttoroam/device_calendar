import '../../device_calendar.dart';
import '../common/error_messages.dart';
import 'attendee.dart';
import 'recurrence_rule.dart';

/// An event associated with a calendar
class Event {
  /// Read-only. The unique identifier for this event. This is auto-generated when a new event is created
  String eventId;

  /// Read-only. The identifier of the calendar that this event is associated with
  String calendarId;

  /// The title of this event
  String title;

  /// The description for this event
  String description;

  /// Indicates when the event starts
  DateTime start;

  /// Indicates when the event ends
  DateTime end;

  // Time zone of the event start date
  String startTimeZone;

  // Time zone of the event end date
  String endTimeZone;

  /// Indicates if this is an all-day event
  bool allDay;

  /// The location of this event
  String location;

  /// An URL for this event
  Uri url;

  /// A list of attendees for this event
  List<Attendee> attendees;

  /// The recurrence rule for this event
  RecurrenceRule recurrenceRule;

  List<Reminder> reminders;

  Event(this.calendarId,
      {this.eventId,
      this.title,
      this.start,
      this.end,
      this.startTimeZone,
      this.endTimeZone,
      this.description,
      this.attendees,
      this.recurrenceRule,
      this.allDay = false});

  Event.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw ArgumentError(ErrorMessages.fromJsonMapIsNull);
    }

    eventId = json['eventId'];
    calendarId = json['calendarId'];
    title = json['title'];
    description = json['description'];
    int startMillisecondsSinceEpoch = json['start'];
    if (startMillisecondsSinceEpoch != null) {
      start = DateTime.fromMillisecondsSinceEpoch(startMillisecondsSinceEpoch);
    }
    int endMillisecondsSinceEpoch = json['end'];
    if (endMillisecondsSinceEpoch != null) {
      end = DateTime.fromMillisecondsSinceEpoch(endMillisecondsSinceEpoch);
    }
    startTimeZone = json['startTimeZone'];
    endTimeZone = json['endTimeZone'];
    allDay = json['allDay'];
    location = json['location'];

    var foundUrl = json['url']?.toString();
    if (foundUrl?.isEmpty ?? true) {
      url = null;
    }
    else {
      url = Uri.dataFromString(foundUrl);
    }

    if (json['attendees'] != null) {
      attendees = json['attendees'].map<Attendee>((decodedAttendee) {
        return Attendee.fromJson(decodedAttendee);
      }).toList();
    }
    if (json['recurrenceRule'] != null) {
      recurrenceRule = RecurrenceRule.fromJson(json['recurrenceRule']);
    }
    if (json['organizer'] != null) { // Getting and setting an organiser for iOS
      var organiser = Attendee.fromJson(json['organizer']);

      var attendee = attendees.firstWhere((at) => at.name == organiser.name && at.emailAddress == organiser.emailAddress, orElse: () => null);
      if (attendee != null) { 
        attendee.isOrganiser = true;
      }
    }
    if (json['reminders'] != null) {
      reminders = json['reminders'].map<Reminder>((decodedReminder) {
        return Reminder.fromJson(decodedReminder);
      }).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['calendarId'] = calendarId;
    data['eventId'] = eventId;    
    data['eventTitle'] = title;
    data['eventDescription'] = description;
    data['eventStartDate'] = start.millisecondsSinceEpoch;
    data['eventEndDate'] = end.millisecondsSinceEpoch;
    data['eventStartTimeZone'] = startTimeZone;
    data['eventEndTimeZone'] = endTimeZone;
    data['eventAllDay'] = allDay;
    data['eventLocation'] = location;
    data['eventURL'] = url?.data?.contentText;
    if (attendees != null) {
      data['attendees'] = attendees.map((a) => a.toJson()).toList();
    }
    if (recurrenceRule != null) {
      data['recurrenceRule'] = recurrenceRule.toJson();
    }
    if (reminders != null) {
      data['reminders'] = reminders.map((r) => r.toJson()).toList();
    }

    return data;
  }
}

import '../common/error_messages.dart';
import 'attendee.dart';
import 'recurrence_rule.dart';

/// An event associated with a calendar
class Event {
  /// The unique identifier for this event
  String eventId;

  /// The identifier of the calendar that this event is associated with
  String calendarId;

  /// The title of this event
  String title;

  /// The description for this event
  String description;

  /// Indicates when the event starts
  DateTime start;

  /// Indicates when the event ends
  DateTime end;

  /// Indicates if this is an all-day event
  bool allDay;

  /// The location of this event
  String location;

  /// A list of attendees for this event
  List<Attendee> attendees;

  /// The organizer of this event
  Attendee organizer;

  /// The recurrence rule for this event
  RecurrenceRule recurrenceRule;

  Event(this.calendarId,
      {this.eventId,
      this.title,
      this.start,
      this.end,
      this.description,
      this.attendees,
      this.recurrenceRule});

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
    allDay = json['allDay'];
    location = json['location'];
    if (json['attendees'] != null) {
      attendees = json['attendees'].map<Attendee>((decodedAttendee) {
        return Attendee.fromJson(decodedAttendee);
      }).toList();
    }
    if (json['recurrenceRule'] != null) {
      recurrenceRule = RecurrenceRule.fromJson(json['recurrenceRule']);
    }
    if (json['organizer'] != null) {
      organizer = Attendee.fromJson(json['organizer']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['eventId'] = eventId;
    data['calendarId'] = calendarId;
    data['title'] = title;
    data['description'] = description;
    data['start'] = start.millisecondsSinceEpoch;
    data['end'] = end.millisecondsSinceEpoch;
    data['allDay'] = allDay;
    data['location'] = location;
    if (attendees != null) {
      print('have attendees');
      data['attendees'] = attendees.map((a) => a.toJson()).toList();
    }
    if (recurrenceRule != null) {
      data['recurrenceRule'] = recurrenceRule.toJson();
    }
    return data;
  }
}

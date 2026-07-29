import 'dart:math';

import 'package:collection/collection.dart';

import '../device_calendar.dart';

/// Encodes/decodes [Event]s to/from iCalendar (RFC 5545, `.ics`) text.
///
/// Pure Dart, no native/channel involvement -- neither platform has an OS
/// API for this.
///
/// ponytail: hand-rolled rather than a pub.dev `.ics` package, scoped to
/// what this plugin's [Event] model actually needs (not a general-purpose
/// RFC 5545 library):
/// - Dates are always written/read as UTC (`...Z` suffix) or a bare
///   `TZID=<IANA name>` reference into whatever `timezone` locations are
///   already loaded in this process -- there's no `VTIMEZONE` component
///   reader/writer, so a re-imported event's *instant* is always correct
///   but its original wall-clock display timezone is only preserved when
///   the source used a plain IANA `TZID` (most modern exports do; legacy
///   Windows-style TZIDs or embedded custom `VTIMEZONE` rules aren't
///   resolved and fall back to the local timezone).
/// - Line folding on export counts UTF-16 code units, not UTF-8 octets per
///   spec -- fine for the ASCII-heavy properties this codec writes, would
///   under-fold for very long non-Latin text.
/// - `VALARM` blocks are skipped on import (reminders aren't read from
///   ICS); attendee `PARTSTAT` (platform-specific attendance status,
///   already covered by `DeviceCalendarPlugin.updateAttendeeStatus`) isn't
///   read or written, only name/email/role/organiser-flag.
/// - The iCalendar `UID` is treated as belonging to the `.ics` file, not
///   this plugin's own device-assigned [Event.eventId] -- importing an
///   event never sets [Event.eventId] (creating it on a real device
///   calendar is what assigns that), so round-tripping through
///   [eventsToIcs]/[eventsFromIcs] preserves content, not identity.
const String _lineBreak = '\r\n';

/// Converts [events] to a single iCalendar (`VCALENDAR`) document containing
/// one `VEVENT` per event, in order.
String eventsToIcs(List<Event> events) {
  final buffer = StringBuffer()
    ..write(_foldLine('BEGIN:VCALENDAR'))
    ..write(_lineBreak)
    ..write(_foldLine('VERSION:2.0'))
    ..write(_lineBreak)
    ..write(_foldLine('PRODID:-//device_calendar//EN'))
    ..write(_lineBreak)
    ..write(_foldLine('CALSCALE:GREGORIAN'))
    ..write(_lineBreak);

  for (final event in events) {
    buffer.write(_eventToVEvent(event));
  }

  buffer
    ..write(_foldLine('END:VCALENDAR'))
    ..write(_lineBreak);

  return buffer.toString();
}

/// Parses every `VEVENT` found in [icsText] (regardless of how many
/// `VCALENDAR` wrappers it's split across) into [Event]s. Unrecognised
/// components/properties are ignored rather than raising an error, since
/// real-world `.ics` files commonly carry vendor extensions this codec
/// doesn't know about.
List<Event> eventsFromIcs(String icsText) {
  final lines = _unfoldLines(icsText);
  final events = <Event>[];
  _VEventBuilder? current;
  var alarmDepth = 0;

  for (final line in lines) {
    final prop = _parseIcsProperty(line);

    if (prop.name == 'BEGIN' && prop.value == 'VALARM') {
      alarmDepth++;
      continue;
    }
    if (prop.name == 'END' && prop.value == 'VALARM') {
      if (alarmDepth > 0) alarmDepth--;
      continue;
    }
    if (alarmDepth > 0) continue;

    if (prop.name == 'BEGIN' && prop.value == 'VEVENT') {
      current = _VEventBuilder();
      continue;
    }
    if (prop.name == 'END' && prop.value == 'VEVENT') {
      final builder = current;
      if (builder != null) {
        final event = builder.build();
        if (event != null) events.add(event);
      }
      current = null;
      continue;
    }

    current?.consume(prop);
  }

  return events;
}

/// Converts a single [Event] to a standalone iCalendar document. Convenience
/// wrapper over [eventsToIcs] for the single-event case.
extension IcsEventExtension on Event {
  String toIcs() => eventsToIcs([this]);
}

String _eventToVEvent(Event event) {
  final buffer = StringBuffer()
    ..write(_foldLine('BEGIN:VEVENT'))
    ..write(_lineBreak)
    ..write(_foldLine('UID:${_generateUid(event)}'))
    ..write(_lineBreak)
    ..write(_foldLine('DTSTAMP:${_formatIcsUtc(DateTime.now().toUtc())}'))
    ..write(_lineBreak);

  final start = event.start;
  final end = event.end;
  if (start != null) {
    buffer
      ..write(_foldLine(_formatIcsDateTimeProperty('DTSTART', start,
          allDay: event.allDay ?? false)))
      ..write(_lineBreak);
  }
  if (end != null) {
    buffer
      ..write(_foldLine(_formatIcsDateTimeProperty('DTEND', end,
          allDay: event.allDay ?? false)))
      ..write(_lineBreak);
  }

  if (event.title?.isNotEmpty ?? false) {
    buffer
      ..write(_foldLine('SUMMARY:${_escapeText(event.title!)}'))
      ..write(_lineBreak);
  }
  if (event.description?.isNotEmpty ?? false) {
    buffer
      ..write(_foldLine('DESCRIPTION:${_escapeText(event.description!)}'))
      ..write(_lineBreak);
  }
  if (event.location?.isNotEmpty ?? false) {
    buffer
      ..write(_foldLine('LOCATION:${_escapeText(event.location!)}'))
      ..write(_lineBreak);
  }
  if (event.url != null) {
    buffer
      ..write(_foldLine('URL:${event.url}'))
      ..write(_lineBreak);
  }

  final statusValue = _icsStatus(event.status);
  if (statusValue != null) {
    buffer
      ..write(_foldLine('STATUS:$statusValue'))
      ..write(_lineBreak);
  }

  buffer
    ..write(_foldLine('TRANSP:${event.availability == Availability.Free ? 'TRANSPARENT' : 'OPAQUE'}'))
    ..write(_lineBreak)
    ..write(_foldLine('X-DEVICE-CALENDAR-AVAILABILITY:${event.availability.enumToString}'))
    ..write(_lineBreak);

  final rrule = event.recurrenceRule;
  if (rrule != null) {
    buffer
      ..write(_foldLine('RRULE:${rrule.toString()}'))
      ..write(_lineBreak);
  }

  final organiser =
      event.attendees?.firstWhereOrNull((a) => a?.isOrganiser ?? false);
  if (organiser != null) {
    buffer
      ..write(_foldLine(_attendeeLine('ORGANIZER', organiser)))
      ..write(_lineBreak);
  }
  for (final attendee in event.attendees ?? const <Attendee?>[]) {
    if (attendee == null) continue;
    buffer
      ..write(_foldLine(_attendeeLine('ATTENDEE', attendee)))
      ..write(_lineBreak);
  }

  buffer
    ..write(_foldLine('END:VEVENT'))
    ..write(_lineBreak);

  return buffer.toString();
}

String? _icsStatus(EventStatus? status) {
  switch (status) {
    case EventStatus.Confirmed:
      return 'CONFIRMED';
    case EventStatus.Tentative:
      return 'TENTATIVE';
    case EventStatus.Canceled:
      return 'CANCELLED';
    case EventStatus.None:
    case null:
      return null;
  }
}

EventStatus? _parseIcsStatus(String? value) {
  switch (value?.toUpperCase()) {
    case 'CONFIRMED':
      return EventStatus.Confirmed;
    case 'TENTATIVE':
      return EventStatus.Tentative;
    case 'CANCELLED':
    case 'CANCELED':
      return EventStatus.Canceled;
  }
  return null;
}

String _roleParam(AttendeeRole? role) {
  switch (role) {
    case AttendeeRole.Required:
      return 'REQ-PARTICIPANT';
    case AttendeeRole.Optional:
      return 'OPT-PARTICIPANT';
    case AttendeeRole.Resource:
      return 'NON-PARTICIPANT';
    case AttendeeRole.None:
    case null:
      return 'REQ-PARTICIPANT';
  }
}

AttendeeRole _parseRoleParam(String? value) {
  switch (value?.toUpperCase()) {
    case 'CHAIR':
    case 'REQ-PARTICIPANT':
      return AttendeeRole.Required;
    case 'OPT-PARTICIPANT':
      return AttendeeRole.Optional;
    case 'NON-PARTICIPANT':
      return AttendeeRole.Resource;
  }
  return AttendeeRole.None;
}

String _attendeeLine(String propertyName, Attendee attendee) {
  var line = propertyName;
  if (attendee.name?.isNotEmpty ?? false) {
    line += ';CN=${attendee.name!.replaceAll('"', "'")}';
  }
  if (propertyName == 'ATTENDEE') {
    line += ';ROLE=${_roleParam(attendee.role)}';
  }
  return '$line:mailto:${attendee.emailAddress ?? ''}';
}

final _uidRandom = Random();

String _generateUid(Event event) {
  final eventId = event.eventId;
  if (eventId?.isNotEmpty ?? false) return '$eventId@device_calendar';
  final unique =
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_uidRandom.nextInt(1 << 32).toRadixString(36)}';
  return '$unique@device_calendar';
}

String _formatIcsDateTimeProperty(String name, TZDateTime dt,
    {required bool allDay}) {
  if (allDay) {
    return '$name;VALUE=DATE:${_formatIcsDate(dt)}';
  }
  return '$name:${_formatIcsUtc(dt.toUtc())}';
}

String _pad2(int value) => value.toString().padLeft(2, '0');
String _pad4(int value) => value.toString().padLeft(4, '0');

String _formatIcsDate(TZDateTime dt) =>
    '${_pad4(dt.year)}${_pad2(dt.month)}${_pad2(dt.day)}';

String _formatIcsUtc(DateTime utc) =>
    '${_pad4(utc.year)}${_pad2(utc.month)}${_pad2(utc.day)}T'
    '${_pad2(utc.hour)}${_pad2(utc.minute)}${_pad2(utc.second)}Z';

String _escapeText(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\n', '\\n');

String _unescapeText(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char == '\\' && i + 1 < value.length) {
      final next = value[i + 1];
      if (next == 'n' || next == 'N') {
        buffer.write('\n');
        i++;
        continue;
      }
      if (next == '\\' || next == ';' || next == ',') {
        buffer.write(next);
        i++;
        continue;
      }
    }
    buffer.write(char);
  }
  return buffer.toString();
}

/// Folds a single unfolded property line to RFC 5545's 75-octet limit
/// (counted in UTF-16 code units here -- see the module doc comment).
String _foldLine(String line) {
  const maxLen = 75;
  if (line.length <= maxLen) return line;

  final buffer = StringBuffer(line.substring(0, maxLen));
  var index = maxLen;
  while (index < line.length) {
    // Continuation lines start with a single space, which counts toward
    // their own 74 remaining characters of budget.
    final chunkEnd = min(index + maxLen - 1, line.length);
    buffer
      ..write(_lineBreak)
      ..write(' ')
      ..write(line.substring(index, chunkEnd));
    index = chunkEnd;
  }
  return buffer.toString();
}

List<String> _unfoldLines(String ics) {
  final rawLines = ics.split(RegExp(r'\r\n|\r|\n'));
  final unfolded = <String>[];
  for (final line in rawLines) {
    if (line.isEmpty) continue;
    if ((line.startsWith(' ') || line.startsWith('\t')) &&
        unfolded.isNotEmpty) {
      unfolded[unfolded.length - 1] += line.substring(1);
    } else {
      unfolded.add(line);
    }
  }
  return unfolded;
}

class _IcsProperty {
  final String name;
  final Map<String, String> params;
  final String value;

  _IcsProperty(this.name, this.params, this.value);
}

_IcsProperty _parseIcsProperty(String line) {
  var inQuotes = false;
  var colonIndex = -1;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') inQuotes = !inQuotes;
    if (char == ':' && !inQuotes) {
      colonIndex = i;
      break;
    }
  }
  if (colonIndex == -1) {
    return _IcsProperty(line.toUpperCase(), const {}, '');
  }

  final head = line.substring(0, colonIndex);
  final value = line.substring(colonIndex + 1);
  final headParts = head.split(';');
  final name = headParts.first.toUpperCase();
  final params = <String, String>{};
  for (final part in headParts.skip(1)) {
    final eq = part.indexOf('=');
    if (eq == -1) continue;
    params[part.substring(0, eq).toUpperCase()] =
        part.substring(eq + 1).replaceAll('"', '');
  }
  return _IcsProperty(name, params, value);
}

TZDateTime _parseIcsDateTime(_IcsProperty prop) {
  final value = prop.value;
  final isDateOnly = prop.params['VALUE'] == 'DATE' || !value.contains('T');
  if (isDateOnly || value.length < 8) {
    final y = int.parse(value.substring(0, 4));
    final m = int.parse(value.substring(4, 6));
    final d = int.parse(value.substring(6, 8));
    return TZDateTime.utc(y, m, d);
  }

  final y = int.parse(value.substring(0, 4));
  final m = int.parse(value.substring(4, 6));
  final d = int.parse(value.substring(6, 8));
  final h = int.parse(value.substring(9, 11));
  final mi = int.parse(value.substring(11, 13));
  final s = int.parse(value.substring(13, 15));

  if (value.endsWith('Z')) {
    return TZDateTime.utc(y, m, d, h, mi, s);
  }

  final tzid = prop.params['TZID'];
  if (tzid != null) {
    try {
      return TZDateTime(timeZoneDatabase.get(tzid), y, m, d, h, mi, s);
    } on LocationNotFoundException {
      // Unknown/unsupported TZID (e.g. a Windows-style name, or one defined
      // by an embedded VTIMEZONE this codec doesn't read) -- fall through to
      // the floating/local interpretation below.
    }
  }
  return TZDateTime(local, y, m, d, h, mi, s);
}

class _VEventBuilder {
  _IcsProperty? dtstart;
  _IcsProperty? dtend;
  String? summary;
  String? description;
  String? location;
  String? url;
  EventStatus? status;
  Availability? xAvailability;
  bool transparent = false;
  String? rrule;
  _IcsProperty? organizer;
  final List<_IcsProperty> attendees = [];

  void consume(_IcsProperty prop) {
    switch (prop.name) {
      case 'DTSTART':
        dtstart = prop;
        break;
      case 'DTEND':
        dtend = prop;
        break;
      case 'SUMMARY':
        summary = _unescapeText(prop.value);
        break;
      case 'DESCRIPTION':
        description = _unescapeText(prop.value);
        break;
      case 'LOCATION':
        location = _unescapeText(prop.value);
        break;
      case 'URL':
        url = prop.value;
        break;
      case 'STATUS':
        status = _parseIcsStatus(prop.value);
        break;
      case 'TRANSP':
        transparent = prop.value.toUpperCase() == 'TRANSPARENT';
        break;
      case 'X-DEVICE-CALENDAR-AVAILABILITY':
        xAvailability = Availability.values.firstWhereOrNull(
            (a) => a.enumToString == prop.value.toUpperCase());
        break;
      case 'RRULE':
        rrule = prop.value;
        break;
      case 'ORGANIZER':
        organizer = prop;
        break;
      case 'ATTENDEE':
        attendees.add(prop);
        break;
    }
  }

  Event? build() {
    if (dtstart == null) return null;

    final allDay = dtstart!.params['VALUE'] == 'DATE';
    final start = _parseIcsDateTime(dtstart!);
    final end = dtend != null ? _parseIcsDateTime(dtend!) : start;

    final parsedAttendees = <Attendee>[
      for (final prop in attendees) _attendeeFromProperty(prop),
    ];

    final organizerProp = organizer;
    if (organizerProp != null) {
      final organizerEmail = _emailFromMailto(organizerProp.value);
      final existing = parsedAttendees
          .firstWhereOrNull((a) => a.emailAddress == organizerEmail);
      if (existing != null) {
        existing.isOrganiser = true;
      } else {
        parsedAttendees
            .add(_attendeeFromProperty(organizerProp)..isOrganiser = true);
      }
    }

    RecurrenceRule? parsedRrule;
    final rawRrule = rrule;
    if (rawRrule != null) {
      try {
        parsedRrule = RecurrenceRule.fromString(rawRrule);
      } catch (_) {
        // Malformed/unsupported RRULE text -- drop the recurrence rather
        // than fail the whole import.
        parsedRrule = null;
      }
    }

    return Event(
      null,
      title: summary,
      description: description,
      location: location,
      url: url?.isNotEmpty ?? false ? Uri.tryParse(url!) : null,
      start: start,
      end: end,
      allDay: allDay,
      status: status,
      availability: xAvailability ??
          (transparent ? Availability.Free : Availability.Busy),
      recurrenceRule: parsedRrule,
      attendees: parsedAttendees.isEmpty ? null : parsedAttendees,
    );
  }
}

Attendee _attendeeFromProperty(_IcsProperty prop) {
  return Attendee(
    name: prop.params['CN'],
    emailAddress: _emailFromMailto(prop.value),
    role: _parseRoleParam(prop.params['ROLE']),
  );
}

String _emailFromMailto(String value) {
  const prefix = 'mailto:';
  return value.toLowerCase().startsWith(prefix)
      ? value.substring(prefix.length)
      : value;
}

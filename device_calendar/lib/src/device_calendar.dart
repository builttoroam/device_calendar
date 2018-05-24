part of device_calendar;

/// A singleton service providing functionality to work with device calendar(s)
class DeviceCalendarPlugin {
  static const MethodChannel channel =
      const MethodChannel('plugins.builttoroam.com/device_calendar');

  static final DeviceCalendarPlugin _instance =
      new DeviceCalendarPlugin._createInstance();

  factory DeviceCalendarPlugin() {
    return _instance;
  }

  DeviceCalendarPlugin._createInstance();

  /// Retrieves all of the device defined calendars
  Future<List<Calendar>> retrieveCalendars() async {
    try {
      var calendarsJson = await channel.invokeMethod('retrieveCalendars');

      final List<Calendar> calendars =
          json.decode(calendarsJson).map<Calendar>((decodedCalendar) {
        return new Calendar.fromJson(decodedCalendar);
      }).toList();

      return calendars;
    } catch (e) {
      print(e);
    }

    return new List<Calendar>();
  }

  /// Retrieves calendar events
  Future<List<Event>> retrieveEvents(
      String calendarId, DateTime startDate, DateTime endDate) async {
    try {
      var eventsJson =
          await channel.invokeMethod('retrieveEvents', <String, Object>{
        'calendarId': calendarId,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch
      });

      final List<Event> events =
          json.decode(eventsJson).map<Event>((decodedEvent) {
        return new Event.fromJson(decodedEvent);
      }).toList();

      return events;
    } catch (e) {
      print(e);
    }

    return new List<Event>();
  }

  /// Delete calendar event
  Future<bool> deleteEvent(Calendar calendar, Event event) async {
    try {
      var succeeded = await channel.invokeMethod('deleteEvent',
          <String, Object>{'calendarId': calendar.id, 'eventId': event.id});
      return succeeded;
    } catch (e) {
      print(e);
    }

    return false;
  }

  /// Creates or updates an event
  ///
  /// returns: event ID
  Future<BaseResult<String>> createOrUpdateEvent(
      String calendarId, Event event) async {
    var res = new BaseResult<String>(null);
    if ((calendarId?.isEmpty ?? true) ||
        (event?.title?.isEmpty ?? false) ||
        event.start == null ||
        event.end == null ||
        event.start.isAfter(event.end)) {
      res.errorMessages.add(Constants.invalidArgument);
      res.errorMessages.add(Constants.createOrUpdateEventArgumentRequirements);

      return res;
    }

    try {
      res.data =
          await channel.invokeMethod('createOrUpdateEvent', <String, Object>{
        'calendarId': calendarId,
        'eventId': event.id,
        'eventTitle': event.title,
        'eventDescription': event.description,
        'eventStartDate': event.start.millisecondsSinceEpoch,
        'eventEndDate': event.end.millisecondsSinceEpoch,
      });
      res.isSuccess = res.data?.isNotEmpty;
    } catch (e) {
      res.errorMessages.add(e.toString());
      print(e);
    }

    return res;
  }
}

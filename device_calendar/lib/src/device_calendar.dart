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
      final List<Calendar> calendars = new List<Calendar>();

      var decodedCalendars = json.decode(calendarsJson);
      for (var decodedCalendar in decodedCalendars) {
        var calendar = new Calendar.fromJson(decodedCalendar);
        calendars.add(calendar);
      }

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
      final List<Event> events = new List<Event>();

      var decodedEvents = json.decode(eventsJson);
      for (var decodedCalendar in decodedEvents) {
        var event = new Event.fromJson(decodedCalendar);
        events.add(event);
      }

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

  /// Create an event
  ///
  /// returns: Newly created event ID
  Future<BaseResult<String>> createEvent(Calendar calendar, Event event) async {
    var res = new BaseResult<String>(null);
    if (calendar?.id == null ||
        (event?.title?.isEmpty ?? false) ||
        event.start == null ||
        event.end == null) {
      res.errorMessages.add(Constants.invalidArgument);
      res.errorMessages.add(Constants.createEventArgumentReuirements);

      return res;
    }

    try {
      res.data = await channel.invokeMethod('createEvent', <String, Object>{
        'calendarId': calendar.id,
        'eventTitle': event.title,
        'eventStartDate': event.start.millisecondsSinceEpoch,
        'eventEndDate': event.end.millisecondsSinceEpoch,
      });
      res.isSuccess = true;
    } catch (e) {
      res.errorMessages.add(e.toString());
      print(e);
    }

    return res;
  }
}

part of device_calendar;

/// Provides functionality for working with device calendar(s)
class DeviceCalendarPlugin {
  static const MethodChannel channel =
      const MethodChannel('plugins.builttoroam.com/device_calendar');

  static final DeviceCalendarPlugin _instance =
      new DeviceCalendarPlugin._createInstance();

  factory DeviceCalendarPlugin() {
    return _instance;
  }

  DeviceCalendarPlugin._createInstance();

  /// Requests permissions to modify the calendars on the device
  Future<Result<bool>> requestPermissions() async {
    var res = new Result(false);
    
    try {
      var permissionsGranted = await channel.invokeMethod('requestPermissions');

      res.isSuccess = true;
      res.data = permissionsGranted;
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
      print(e);
    }

    return res;
  }

  /// Checks if permissions for modifying the device calendars have been granted
  Future<Result<bool>> hasPermissions() async {
    var res = new Result(false);

    try {
      var permissionsGranted = await channel.invokeMethod('hasPermissions');

      res.isSuccess = true;
      res.data = permissionsGranted;
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
      print(e);
    }

    return res;
  }

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

  /// Retrieves the events from the specified calendar that fall within a certain date/time range
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

  /// Deletes an event from a calendar
  Future<bool> deleteEvent(String calendarId, String eventId) async {
    try {
      var succeeded = await channel.invokeMethod('deleteEvent',
          <String, Object>{'calendarId': calendarId, 'eventId': eventId});
      return succeeded;
    } catch (e) {
      print(e);
    }

    return false;
  }

  /// Creates or updates an event
  ///
  /// returns: event ID
  Future<Result<String>> createOrUpdateEvent(Event event) async {
    var res = new Result<String>(null);
    if ((event.calendarId?.isEmpty ?? true) ||
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
        'calendarId': event.calendarId,
        'eventId': event.eventId,
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

  void _parsePlatformExceptionAndUpdateResult<T>(
      PlatformException exception, Result<T> result) {
    if (exception == null || result == null) {
      return;
    }

    result.errorMessages.add(
        "Device calendar plugin ran into an issue. Platform specific exception [${exception.code}], with message :\"${exception.message}\", has been thrown.");
  }
}

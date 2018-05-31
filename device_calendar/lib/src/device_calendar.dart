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
    final res = new Result(false);

    try {
      res.data = await channel.invokeMethod('requestPermissions');
      res.isSuccess = true;
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
      print(e);
    }

    return res;
  }

  /// Checks if permissions for modifying the device calendars have been granted
  Future<Result<bool>> hasPermissions() async {
    final res = new Result(false);

    try {
      res.data = await channel.invokeMethod('hasPermissions');
      res.isSuccess = true;
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
      print(e);
    }

    return res;
  }

  /// Retrieves all of the device defined calendars
  Future<Result<List<Calendar>>> retrieveCalendars() async {
    final res = new Result(new List<Calendar>());

    try {
      var calendarsJson = await channel.invokeMethod('retrieveCalendars');

      res.data = json.decode(calendarsJson).map<Calendar>((decodedCalendar) {
        return new Calendar.fromJson(decodedCalendar);
      }).toList();

      res.isSuccess = true;
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<List<Calendar>>(e, res);
      print(e);
    }

    return res;
  }

  /// Retrieves the events from the specified calendar
  Future<Result<List<Event>>> retrieveEvents(
      String calendarId, RetrieveEventsParams retrieveEventsParams) async {
    final res = new Result(new List<Event>());

    if ((calendarId?.isEmpty ?? true)) {
      res.errorMessages.add(
          "[${ErrorCodes.invalidArguments}] ${ErrorMessages.retrieveEventsInvalidArgumentsMessage}");
      return res;
    }

    // TODO: validate the params
    try {
      var eventsJson =
          await channel.invokeMethod('retrieveEvents', <String, Object>{
        'calendarId': calendarId,
        'startDate': retrieveEventsParams.startDate?.millisecondsSinceEpoch,
        'endDate': retrieveEventsParams.endDate?.millisecondsSinceEpoch,
        'eventIds': retrieveEventsParams.eventIds
      });

      res.data = json.decode(eventsJson).map<Event>((decodedEvent) {
        return new Event.fromJson(decodedEvent);
      }).toList();
      res.isSuccess = true;
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<List<Event>>(e, res);
      print(e);
    }

    return res;
  }

  /// Deletes an event from a calendar
  Future<Result<bool>> deleteEvent(String calendarId, String eventId) async {
    final res = new Result(false);

    if ((calendarId?.isEmpty ?? true) || (eventId?.isEmpty ?? true)) {
      res.errorMessages.add(
          "[${ErrorCodes.invalidArguments}] ${ErrorMessages.deleteEventInvalidArgumentsMessage}");
      return res;
    }

    try {
      res.data = await channel.invokeMethod('deleteEvent',
          <String, Object>{'calendarId': calendarId, 'eventId': eventId});
      res.isSuccess = true;
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
      print(e);
    }

    return res;
  }

  /// Creates or updates an event
  ///
  /// returns: event ID
  Future<Result<String>> createOrUpdateEvent(Event event) async {
    final res = new Result<String>(null);

    if ((event?.calendarId?.isEmpty ?? true) ||
        (event?.title?.isEmpty ?? true) ||
        event.start == null ||
        event.end == null ||
        event.start.isAfter(event.end)) {
      res.errorMessages.add(
          "[${ErrorCodes.invalidArguments}] ${ErrorMessages.createOrUpdateEventInvalidArgumentsMessage}");
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
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<String>(e, res);
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

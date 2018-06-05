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

  @visibleForTesting
  DeviceCalendarPlugin._createInstance();

  /// Requests permissions to modify the calendars on the device
  /// TODO: add comment about return value
  Future<Result<bool>> requestPermissions() async {
    final res = new Result(false);

    try {
      res.data = await channel.invokeMethod('requestPermissions');
      // TODO: Remove calls to set isSuccess to true
      res.isSuccess = true;
    } on PlatformException catch (e) { 
      // TODO: Change parse method to return a new Result that can be returned immediately     
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
      // TODO: Move print into the parse method
      print(e);
    }

    return res;
  }

  /// Checks if permissions for modifying the device calendars have been granted
  /// TODO: add comment about return value
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
  /// TODO: add comment about return value
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
  /// TODO: add comment about input values and return value
  Future<Result<List<Event>>> retrieveEvents(
      String calendarId, RetrieveEventsParams retrieveEventsParams) async {
    final res = new Result(new List<Event>());

    if ((calendarId?.isEmpty ?? true)) {
      res.errorMessages.add(
          "[${ErrorCodes.invalidArguments}] ${ErrorMessages.invalidMissingCalendarId}");
    }

    // TODO: Extend capability to handle null start or null end (eg all events after a certain date (null end date) or all events prior to a certain date (null start date))
    if ((retrieveEventsParams?.eventIds?.isEmpty ?? true) &&
        ((retrieveEventsParams?.startDate == null ||
                retrieveEventsParams?.endDate == null) ||
            (retrieveEventsParams.startDate != null &&
                retrieveEventsParams.endDate != null &&
                retrieveEventsParams.startDate
                    .isAfter(retrieveEventsParams.endDate)))) {
      res.errorMessages.add(
          "[${ErrorCodes.invalidArguments}] ${ErrorMessages.invalidRetrieveEventsParams}");
    }

    // TODO: Change this to check Success
    if (res.errorMessages.isNotEmpty) {
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
  /// TODO: add comment about input values and return value
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
  /// TODO: add comment about input values
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

  // TODO: Change this to return a new Result based on the parsed exception
  void _parsePlatformExceptionAndUpdateResult<T>(
      PlatformException exception, Result<T> result) {
    if (exception == null || result == null) {
      // TODO: Change to return generic error (ie exception wasn't returned so no additional information)
      return;
    }

    result.errorMessages.add(
        "Device calendar plugin ran into an issue. Platform specific exception [${exception.code}], with message :\"${exception.message}\", has been thrown.");
  }
}

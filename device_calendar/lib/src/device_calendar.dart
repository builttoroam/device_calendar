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
    final res = new Result();

    try {
      res.data = await channel.invokeMethod('requestPermissions');
    } on PlatformException catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
    }

    return res;
  }

  /// Checks if permissions for modifying the device calendars have been granted
  /// TODO: add comment about return value
  Future<Result<bool>> hasPermissions() async {
    final res = new Result<bool>();

    try {
      res.data = await channel.invokeMethod('hasPermissions');
    } catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
    }

    return res;
  }

  /// Retrieves all of the device defined calendars
  /// TODO: add comment about return value
  Future<Result<List<Calendar>>> retrieveCalendars() async {
    final res = new Result<List<Calendar>>();

    try {
      var calendarsJson = await channel.invokeMethod('retrieveCalendars');

      res.data = json.decode(calendarsJson).map<Calendar>((decodedCalendar) {
        return new Calendar.fromJson(decodedCalendar);
      }).toList();
    } catch (e) {
      _parsePlatformExceptionAndUpdateResult<List<Calendar>>(e, res);
    }

    return res;
  }

  /// Retrieves the events from the specified calendar
  /// TODO: add comment about input values and return value
  Future<Result<List<Event>>> retrieveEvents(
      String calendarId, RetrieveEventsParams retrieveEventsParams) async {
    final res = new Result<List<Event>>();

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

    if (res.isSuccess) {
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
      } catch (e) {
        _parsePlatformExceptionAndUpdateResult<List<Event>>(e, res);
      }
    }

    return res;
  }

  /// Deletes an event from a calendar
  /// TODO: add comment about input values and return value
  Future<Result<bool>> deleteEvent(String calendarId, String eventId) async {
    final res = new Result<bool>();

    if ((calendarId?.isEmpty ?? true) || (eventId?.isEmpty ?? true)) {
      res.errorMessages.add(
          "[${ErrorCodes.invalidArguments}] ${ErrorMessages.deleteEventInvalidArgumentsMessage}");
      return res;
    }

    try {
      res.data = await channel.invokeMethod('deleteEvent',
          <String, Object>{'calendarId': calendarId, 'eventId': eventId});
    } catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
    }

    return res;
  }

  /// Creates or updates an event
  ///
  /// returns: event ID
  /// TODO: add comment about input values
  Future<Result<String>> createOrUpdateEvent(Event event) async {
    final res = new Result<String>();

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
    } catch (e) {
      _parsePlatformExceptionAndUpdateResult<String>(e, res);
    }

    return res;
  }

  void _parsePlatformExceptionAndUpdateResult<T>(
      Exception exception, Result<T> result) {
    if (exception == null) {
      result.errorMessages.add(
          "[${ErrorCodes.unknown}] Device calendar plugin ran into an unknown issue");
      return;
    }

    print(exception);

    if (exception is PlatformException) {
      result.errorMessages.add(
          "[${ErrorCodes.platformSpecific}] Device calendar plugin ran into an issue. Platform specific exception [${exception.code}], with message :\"${exception.message}\", has been thrown.");
    } else {
      result.errorMessages.add(
          "[${ErrorCodes.generic}] Device calendar plugin ran into an issue, with message \"${exception.toString()}\"");
    }
  }
}

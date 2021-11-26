class ErrorMessages {
  static const String fromJsonMapIsNull = 'The json object is null';

  static const String invalidMissingCalendarId =
      'Calendar ID is missing or invalid';

  static const String invalidRetrieveEventsParams =
      'A valid instance of the RetrieveEventsParams class is required. Must the event ids to filter by or the start and end date to filter by or a combination of these';
  static const String deleteEventInvalidArgumentsMessage =
      'Calendar ID and/or Event ID argument(s) have not been specified or are invalid';
  static const String createOrUpdateEventInvalidArgumentsMessageAllDay =
      "To create or update an all day event you must provide calendar ID, event with a title and event's start date";
  static const String createOrUpdateEventInvalidArgumentsMessage =
      "To create or update an event you must provide calendar ID, event with a title and event's start date and end date (where start date must be before end date)";
  static const String createCalendarInvalidCalendarNameMessage =
      'Calendar name must not be null or empty';

  static const String invalidRecurrencyFrequency =
      'Invalid recurrency frequency';

  static const String unknownDeviceIssue =
      'Device calendar plugin ran into an unknown issue';
  static const String unknownDeviceExceptionTemplate =
      'Device calendar plugin ran into an issue. Platform specific exception [%s], with message :\"%s\", has been thrown.';
  static const String unknownDeviceGenericExceptionTemplate =
      'Device calendar plugin ran into an issue, with message \"%s\"';
}

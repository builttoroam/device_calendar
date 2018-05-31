class ErrorMessages {
  static const String fromJsonMapIsNull = "The json object is null";

  static const String retrieveEventsInvalidArgumentsMessage =
      "Calendar ID argument have not been specified or is invalid";
  static const String deleteEventInvalidArgumentsMessage =
      "Calendar ID and/or Event ID argument(s) have not been specified or are invalid";
  static const String createOrUpdateEventInvalidArgumentsMessage =
      "To create or update an event you must provide calendar ID, event with a title and event's start date and end date (where start date must be before end date)";
}

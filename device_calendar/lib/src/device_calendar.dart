import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'common/error_codes.dart';
import 'common/error_messages.dart';
import 'models/calendar.dart';
import 'models/event.dart';
import 'models/result.dart';
import 'models/retrieve_events_params.dart';

/// Provides functionality for working with device calendar(s)
class DeviceCalendarPlugin {
  static const MethodChannel channel =
      MethodChannel('plugins.builttoroam.com/device_calendar');

  static final DeviceCalendarPlugin _instance = DeviceCalendarPlugin.private();

  factory DeviceCalendarPlugin() {
    return _instance;
  }

  @visibleForTesting
  DeviceCalendarPlugin.private();

  /// Requests permissions to modify the calendars on the device
  ///
  /// Returns a [Result] indicating if calendar READ and WRITE permissions
  /// have (true) or have not (false) been granted
  Future<Result<bool>> requestPermissions() async {
    final res = Result<bool>();

    try {
      res.data = await channel.invokeMethod('requestPermissions');
    } catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
    }

    return res;
  }

  /// Checks if permissions for modifying the device calendars have been granted
  ///
  /// Returns a [Result] indicating if calendar READ and WRITE permissions
  /// have (true) or have not (false) been granted
  Future<Result<bool>> hasPermissions() async {
    final res = Result<bool>();

    try {
      res.data = await channel.invokeMethod('hasPermissions');
    } catch (e) {
      _parsePlatformExceptionAndUpdateResult<bool>(e, res);
    }

    return res;
  }

  /// Retrieves all of the device defined calendars
  ///
  /// Returns a [Result] containing a list of device [Calendar]
  Future<Result<UnmodifiableListView<Calendar>>> retrieveCalendars() async {
    final res = Result<UnmodifiableListView<Calendar>>();

    try {
      var calendarsJson = await channel.invokeMethod('retrieveCalendars');

      res.data = UnmodifiableListView(
          json.decode(calendarsJson).map<Calendar>((decodedCalendar) {
        return Calendar.fromJson(decodedCalendar);
      }));
    } catch (e) {
      _parsePlatformExceptionAndUpdateResult<UnmodifiableListView<Calendar>>(
          e, res);
    }

    return res;
  }

  /// Retrieves the events from the specified calendar
  ///
  /// The `calendarId` paramter is the id of the calendar that plugin will return events for
  /// The `retrieveEventsParams` parameter combines multiple properties that
  /// specifies conditions of the events retrieval. For instance, defining [RetrieveEventsParams.startDate]
  /// and [RetrieveEventsParams.endDate] will return events only happening in that time range
  ///
  /// Returns a [Result] containing a list [Event], that fall
  /// into the specified parameters
  Future<Result<UnmodifiableListView<Event>>> retrieveEvents(
      String calendarId, RetrieveEventsParams retrieveEventsParams) async {
    final res = Result<UnmodifiableListView<Event>>();

    if ((calendarId?.isEmpty ?? true)) {
      res.errorMessages.add(
          '[${ErrorCodes.invalidArguments}] ${ErrorMessages.invalidMissingCalendarId}');
    }

    // TODO: Extend capability to handle null start or null end (e.g. all events after a certain date (null end date) or all events prior to a certain date (null start date))
    if ((retrieveEventsParams?.eventIds?.isEmpty ?? true) &&
        ((retrieveEventsParams?.startDate == null ||
                retrieveEventsParams?.endDate == null) ||
            (retrieveEventsParams.startDate != null &&
                retrieveEventsParams.endDate != null &&
                retrieveEventsParams.startDate
                    .isAfter(retrieveEventsParams.endDate)))) {
      res.errorMessages.add(
          '[${ErrorCodes.invalidArguments}] ${ErrorMessages.invalidRetrieveEventsParams}');
    }

    if (res.errorMessages.isEmpty) {
      try {
        var eventsJson =
            await channel.invokeMethod('retrieveEvents', <String, Object>{
          'calendarId': calendarId,
          'startDate': retrieveEventsParams.startDate?.millisecondsSinceEpoch,
          'endDate': retrieveEventsParams.endDate?.millisecondsSinceEpoch,
          'eventIds': retrieveEventsParams.eventIds
        });

        res.data = UnmodifiableListView(
            json.decode(eventsJson).map<Event>((decodedEvent) {
          return Event.fromJson(decodedEvent);
        }));
      } catch (e) {
        _parsePlatformExceptionAndUpdateResult<UnmodifiableListView<Event>>(
            e, res);
      }
    }

    return res;
  }

  /// Deletes an event from a calendar. For a recurring event, this will delete all instances of it
  ///
  /// The `calendarId` paramter is the id of the calendar that plugin will try to delete the event from
  /// The `eventId` parameter is the id of the event that plugin will try to delete
  ///
  /// Returns a [Result] indicating if the event has (true) or has not (false) been deleted from the calendar
  Future<Result<bool>> deleteEvent(String calendarId, String eventId) async {
    final res = Result<bool>();

    if ((calendarId?.isEmpty ?? true) || (eventId?.isEmpty ?? true)) {
      res.errorMessages.add(
          '[${ErrorCodes.invalidArguments}] ${ErrorMessages.deleteEventInvalidArgumentsMessage}');
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
  /// The `event` paramter specifies how event data should be saved into the calendar
  /// Always specify the [Event.calendarId], to inform the plugin in which calendar
  /// it should create or update the event.
  ///
  /// Returns a [Result] with the newly created or updated [Event.eventId]
  Future<Result<String>> createOrUpdateEvent(Event event) async {
    final res = Result<String>();

    // Setting time to 0 for all day events
    if (event.allDay == true) {
      event.start = DateTime(event.start.year, event.start.month, event.start.day, 0, 0, 0);
      event.end = DateTime(event.end.year, event.end.month, event.end.day, 0, 0, 0);
    }

    if (event.allDay == true && (event?.calendarId?.isEmpty ?? true) || event.start == null || event.end == null) {
      res.errorMessages.add('[${ErrorCodes.invalidArguments}] ${ErrorMessages.createOrUpdateEventInvalidArgumentsMessageAllDay}');
      return res;
    }
    else if (event.allDay != true && ((event?.calendarId?.isEmpty ?? true) || event.start == null || event.end == null || event.start.isAfter(event.end))) {
      res.errorMessages.add('[${ErrorCodes.invalidArguments}] ${ErrorMessages.createOrUpdateEventInvalidArgumentsMessage}');
      return res;
    }

    try {
      res.data =
          await channel.invokeMethod('createOrUpdateEvent', <String, Object>{
        'calendarId': event.calendarId,
        'eventId': event.eventId,
        'eventTitle': event.title,
        'eventDescription': event.description,
        'eventLocation': event.location,
        'eventAllDay': event.allDay,
        'eventStartDate': event.start.millisecondsSinceEpoch,
        'eventEndDate': event.end.millisecondsSinceEpoch,
        'eventLocation': event.location,
        'eventURL': event.url?.data?.contentText,
        'recurrenceRule': event.recurrenceRule?.toJson(),
        'attendees': event.attendees?.map((a) => a.toJson())?.toList(),
        'reminders': event.reminders?.map((r) => r.toJson())?.toList()
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
          '[${ErrorCodes.unknown}] Device calendar plugin ran into an unknown issue');
      return;
    }

    print(exception);

    if (exception is PlatformException) {
      result.errorMessages.add(
          '[${ErrorCodes.platformSpecific}] Device calendar plugin ran into an issue. Platform specific exception [${exception.code}], with message :\"${exception.message}\", has been thrown.');
    } else {
      result.errorMessages.add(
          '[${ErrorCodes.generic}] Device calendar plugin ran into an issue, with message \"${exception.toString()}\"');
    }
  }
}

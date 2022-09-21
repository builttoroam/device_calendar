import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isolate_handler/isolate_handler.dart';
import 'package:sprintf/sprintf.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'common/channel_constants.dart';
import 'common/error_codes.dart';
import 'common/error_messages.dart';
import 'models/calendar.dart';
import 'models/event.dart';
import 'models/result.dart';
import 'models/retrieve_events_params.dart';

/// Provides functionality for working with device calendar(s)
class DeviceCalendarPlugin {
  static const MethodChannel channel = MethodChannel(ChannelConstants.channelName);

  static final DeviceCalendarPlugin _instance = DeviceCalendarPlugin.private();
  final isolates = IsolateHandler();

  factory DeviceCalendarPlugin({bool shouldInitTimezone = true}) {
    if (shouldInitTimezone) {
      tz.initializeTimeZones();
    }
    return _instance;
  }

  @visibleForTesting
  DeviceCalendarPlugin.private();

  /// Requests permissions to modify the calendars on the device
  ///
  /// Returns a [Result] indicating if calendar READ and WRITE permissions
  /// have (true) or have not (false) been granted
  Future<Result<bool>> requestPermissions() async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameRequestPermissions,
    );
  }

  /// Checks if permissions for modifying the device calendars have been granted
  ///
  /// Returns a [Result] indicating if calendar READ and WRITE permissions
  /// have (true) or have not (false) been granted
  Future<Result<bool>> hasPermissions() async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameHasPermissions,
    );
  }

  /// Retrieves all of the device defined calendars
  ///
  /// Returns a [Result] containing a list of device [Calendar]
  Future<Result<UnmodifiableListView<Calendar>>> retrieveCalendars({
    bool useIsolate = false,
  }) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameRetrieveCalendars,
      evaluateResponse: (rawData) => UnmodifiableListView(
        json.decode(rawData).map<Calendar>(
              (decodedCalendar) => Calendar.fromJson(decodedCalendar),
            ),
      ),
      useIsolate: useIsolate,
    );
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
    String? calendarId,
    RetrieveEventsParams? retrieveEventsParams, {
    bool useIsolate = true,
  }) async {
    return retrieveEventsFromAnyCalendars(
      calendarIds: [calendarId ?? ''],
      params: retrieveEventsParams,
      useIsolate: useIsolate,
    );
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
  Future<Result<UnmodifiableListView<Event>>> retrieveEventsFromAnyCalendars({
    List<String>? calendarIds,
    RetrieveEventsParams? params,
    bool useIsolate = true,
  }) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameRetrieveEvents,
      assertParameters: (result) {
        _validateCalendarIdsParameter(
          result,
          calendarIds,
        );

        _assertParameter(
          result,
          !((params?.eventIds?.isEmpty ?? true) &&
              ((params?.startDate == null || params?.endDate == null) ||
                  (params?.startDate != null &&
                      params?.endDate != null &&
                      (params != null && params.startDate!.isAfter(params.endDate!))))),
          ErrorCodes.invalidArguments,
          ErrorMessages.invalidRetrieveEventsParams,
        );
      },
      arguments: () => <String, Object?>{
        ChannelConstants.parameterNameCalendarIds: calendarIds,
        ChannelConstants.parameterNameStartDate: params?.startDate?.millisecondsSinceEpoch,
        ChannelConstants.parameterNameEndDate: params?.endDate?.millisecondsSinceEpoch,
        ChannelConstants.parameterNameEventIds: params?.eventIds,
      },
      useIsolate: useIsolate,
      evaluateResponse: (rawData) {
        return UnmodifiableListView(
          json.decode(rawData).map<Event>((decodedEvent) => Event.fromJson(decodedEvent)),
        );
      },
    );
  }

  /// Deletes an event from a calendar. For a recurring event, this will delete all instances of it.\
  /// To delete individual instance of a recurring event, please use [deleteEventInstance()]
  ///
  /// The `calendarId` parameter is the id of the calendar that plugin will try to delete the event from\
  /// The `eventId` parameter is the id of the event that plugin will try to delete
  ///
  /// Returns a [Result] indicating if the event has (true) or has not (false) been deleted from the calendar
  Future<Result<bool?>> deleteEvent(
    String? calendarId,
    String? eventId, {
    bool useIsolate = false,
  }) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameDeleteEvent,
      assertParameters: (result) {
        _validateCalendarIdParameter(
          result,
          calendarId,
        );

        _assertParameter(
          result,
          eventId?.isNotEmpty ?? false,
          ErrorCodes.invalidArguments,
          ErrorMessages.deleteEventInvalidArgumentsMessage,
        );
      },
      arguments: () => <String, Object?>{
        ChannelConstants.parameterNameCalendarId: calendarId,
        ChannelConstants.parameterNameEventId: eventId,
      },
      useIsolate: useIsolate,
    );
  }

  /// Deletes an instance of a recurring event from a calendar. This should be used for a recurring event only.\
  /// If `startDate`, `endDate` or `deleteFollowingInstances` is not valid or null, then all instances of the event will be deleted.
  ///
  /// The `calendarId` parameter is the id of the calendar that plugin will try to delete the event from\
  /// The `eventId` parameter is the id of the event that plugin will try to delete\
  /// The `startDate` parameter is the start date of the instance to delete\
  /// The `endDate` parameter is the end date of the instance to delete\
  /// The `deleteFollowingInstances` parameter will also delete the following instances if set to true
  ///
  /// Returns a [Result] indicating if the instance of the event has (true) or has not (false) been deleted from the calendar
  Future<Result<bool?>> deleteEventInstance(
    String? calendarId,
    String? eventId,
    DateTime? startDate,
    DateTime? endDate,
    bool deleteFollowingInstances, {
    bool useIsolate = false,
  }) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameDeleteEventInstance,
      assertParameters: (result) {
        _validateCalendarIdParameter(
          result,
          calendarId,
        );

        _assertParameter(
          result,
          eventId?.isNotEmpty ?? false,
          ErrorCodes.invalidArguments,
          ErrorMessages.deleteEventInvalidArgumentsMessage,
        );
      },
      arguments: () => <String, Object?>{
        ChannelConstants.parameterNameCalendarId: calendarId,
        ChannelConstants.parameterNameEventId: eventId,
        ChannelConstants.parameterNameEventStartDate: startDate?.millisecondsSinceEpoch,
        ChannelConstants.parameterNameEventEndDate: endDate?.millisecondsSinceEpoch,
        ChannelConstants.parameterNameFollowingInstances: deleteFollowingInstances,
      },
      useIsolate: useIsolate,
    );
  }

  /// Creates or updates an event
  ///
  /// The `event` paramter specifies how event data should be saved into the calendar
  /// Always specify the [Event.calendarId], to inform the plugin in which calendar
  /// it should create or update the event.
  ///
  /// Returns a [Result] with the newly created or updated [Event.eventId]
  Future<Result<UnmodifiableListView<Event>>?> createOrUpdateEvent(
    Event? event, {
    bool useIsolate = false,
  }) async {
    if (event == null) return null;
    return _invokeChannelMethod(
      ChannelConstants.methodNameCreateOrUpdateEvent,
      assertParameters: (result) {
        // Setting time to 0 for all day events
        if (event.allDay == true) {
          if (event.start != null) {
            var dateStart = DateTime(event.start!.year, event.start!.month, event.start!.day, 0, 0, 0);
            // allDay events on Android need to be at midnight UTC
            event.start = Platform.isAndroid
                ? TZDateTime.utc(event.start!.year, event.start!.month, event.start!.day, 0, 0, 0)
                : TZDateTime.from(dateStart, timeZoneDatabase.locations[event.start!.location.name]!);
          }
          if (event.end != null) {
            var dateEnd = DateTime(event.end!.year, event.end!.month, event.end!.day, 0, 0, 0);
            // allDay events on Android need to be at midnight UTC on the
            // day after the last day. For example, a 2-day allDay event on
            // Jan 1 and 2, should be from Jan 1 00:00:00 to Jan 3 00:00:00
            event.end = Platform.isAndroid
                ? TZDateTime.utc(event.end!.year, event.end!.month, event.end!.day, 0, 0, 0).add(Duration(days: 1))
                : TZDateTime.from(dateEnd, timeZoneDatabase.locations[event.end!.location.name]!);
          }
        }

        _assertParameter(
          result,
          !(event.allDay == true && (event.calendarId?.isEmpty ?? true) || event.start == null || event.end == null),
          ErrorCodes.invalidArguments,
          ErrorMessages.createOrUpdateEventInvalidArgumentsMessageAllDay,
        );

        _assertParameter(
          result,
          !(event.allDay != true &&
              ((event.calendarId?.isEmpty ?? true) ||
                  event.start == null ||
                  event.end == null ||
                  (event.start != null && event.end != null && event.start!.isAfter(event.end!)))),
          ErrorCodes.invalidArguments,
          ErrorMessages.createOrUpdateEventInvalidArgumentsMessage,
        );
      },
      evaluateResponse: (rawData) {
        return UnmodifiableListView(
          json.decode(rawData).map<Event>((decodedEvent) => Event.fromJson(decodedEvent)),
        );
      },
      arguments: () => event.toJson(),
      useIsolate: useIsolate,
    );
  }

  /// Creates or updates an event
  ///
  /// The `event` paramter specifies how event data should be saved into the calendar
  /// Always specify the [Event.calendarId], to inform the plugin in which calendar
  /// it should create or update the event.
  ///
  /// The `startDate` parameter is the start date of the instance to update\
  /// The `endDate` parameter is the end date of the instance to update\
  /// The `updateFollowingInstances` parameter will also update the following instances if set to true
  ///
  /// Returns a [Result] with the newly created or updated [Event.eventId]
  Future<Result<UnmodifiableListView<Event>>?> updateEventInstance(
    Event? event,
    DateTime? startDate,
    DateTime? endDate,
    bool updateFollowingInstances, {
    bool useIsolate = false,
  }) async {
    if (event == null) return null;
    return _invokeChannelMethod(
      ChannelConstants.methodNameUpdateEventInstance,
      assertParameters: (result) {
        // Setting time to 0 for all day events
        if (event.allDay == true) {
          if (event.start != null) {
            var dateStart = DateTime(event.start!.year, event.start!.month, event.start!.day, 0, 0, 0);
            // allDay events on Android need to be at midnight UTC
            event.start = Platform.isAndroid
                ? TZDateTime.utc(event.start!.year, event.start!.month, event.start!.day, 0, 0, 0)
                : TZDateTime.from(dateStart, timeZoneDatabase.locations[event.start!.location.name]!);
          }
          if (event.end != null) {
            var dateEnd = DateTime(event.end!.year, event.end!.month, event.end!.day, 0, 0, 0);
            // allDay events on Android need to be at midnight UTC on the
            // day after the last day. For example, a 2-day allDay event on
            // Jan 1 and 2, should be from Jan 1 00:00:00 to Jan 3 00:00:00
            event.end = Platform.isAndroid
                ? TZDateTime.utc(event.end!.year, event.end!.month, event.end!.day, 0, 0, 0).add(Duration(days: 1))
                : TZDateTime.from(dateEnd, timeZoneDatabase.locations[event.end!.location.name]!);
          }
        }

        _assertParameter(
          result,
          !(event.allDay == true && (event.calendarId?.isEmpty ?? true) || event.start == null || event.end == null),
          ErrorCodes.invalidArguments,
          ErrorMessages.createOrUpdateEventInvalidArgumentsMessageAllDay,
        );

        _assertParameter(
          result,
          !(event.allDay != true &&
              ((event.calendarId?.isEmpty ?? true) ||
                  event.start == null ||
                  event.end == null ||
                  (event.start != null && event.end != null && event.start!.isAfter(event.end!)))),
          ErrorCodes.invalidArguments,
          ErrorMessages.createOrUpdateEventInvalidArgumentsMessage,
        );
      },
      evaluateResponse: (rawData) {
        return UnmodifiableListView(
          json.decode(rawData).map<Event>((decodedEvent) => Event.fromJson(decodedEvent)),
        );
      },
      arguments: () => event.toJson()
        ..addAll({
          ChannelConstants.parameterNameEventStartDate: startDate?.millisecondsSinceEpoch,
          ChannelConstants.parameterNameEventEndDate: endDate?.millisecondsSinceEpoch,
          ChannelConstants.parameterNameFollowingInstances: updateFollowingInstances,
        }),
      useIsolate: useIsolate,
    );
  }

  /// Creates a new local calendar for the current device.
  ///
  /// The `calendarName` parameter is the name of the new calendar\
  /// The `calendarColor` parameter is the color of the calendar. If null,
  /// a default color (red) will be used\
  /// The `localAccountName` parameter is the name of the local account:
  /// - [Android] Required. If `localAccountName` parameter is null or empty, it will default to 'Device Calendar'.
  /// If the account name already exists in the device, it will add another calendar under the account,
  /// otherwise a new local account and a new calendar will be created.
  /// - [iOS] Not used. A local account will be picked up automatically, if not found, an error will be thrown.
  ///
  /// Returns a [Result] with the newly created [Calendar.id]
  Future<Result<String>> createCalendar(
    String? calendarName, {
    Color? calendarColor,
    String? localAccountName,
    bool useIsolate = false,
  }) async {
    return _invokeChannelMethod(ChannelConstants.methodNameCreateCalendar,
        assertParameters: (result) {
          calendarColor ??= Colors.red;

          _assertParameter(
            result,
            calendarName?.isNotEmpty == true,
            ErrorCodes.invalidArguments,
            ErrorMessages.createCalendarInvalidCalendarNameMessage,
          );
        },
        arguments: () => <String, Object?>{
              ChannelConstants.parameterNameCalendarName: calendarName,
              ChannelConstants.parameterNameCalendarColor: '0x${calendarColor?.value.toRadixString(16)}',
              ChannelConstants.parameterNameLocalAccountName:
                  localAccountName?.isEmpty ?? true ? 'Device Calendar' : localAccountName
            },
        useIsolate: useIsolate);
  }

  /// Deletes a calendar.
  /// The `calendarId` parameter is the id of the calendar that plugin will try to delete the event from\///
  /// Returns a [Result] indicating if the instance of the calendar has (true) or has not (false) been deleted
  Future<Result<bool?>> deleteCalendar(
    String calendarId, {
    bool useIsolate = false,
  }) async {
    return _invokeChannelMethod(
      ChannelConstants.methodNameDeleteCalendar,
      assertParameters: (result) {
        _validateCalendarIdParameter(
          result,
          calendarId,
        );
      },
      arguments: () => <String, Object>{
        ChannelConstants.parameterNameCalendarId: calendarId,
      },
      useIsolate: useIsolate,
    );
  }

  /// Displays a native iOS view [EKEventViewController]
  /// https://developer.apple.com/documentation/eventkitui/ekeventviewcontroller
  ///
  /// Allows to change the event's attendance status
  /// Works only on iOS
  /// Returns after dismissing EKEventViewController's dialog
  Future<Result<void>> showiOSEventModal(
    String eventId,
  ) {
    return _invokeChannelMethod(
      ChannelConstants.methodNameShowiOSEventModal,
      arguments: () => <String, String>{
        ChannelConstants.parameterNameEventId: eventId,
      },
    );
  }

  Future<Result<T>> _invokeChannelMethod<T>(
    String channelMethodName, {
    Function(Result<T>)? assertParameters,
    Map<String, Object?> Function()? arguments,
    T Function(dynamic)? evaluateResponse,
    bool useIsolate = false,
  }) async {
    final result = Result<T>();

    try {
      if (assertParameters != null) {
        assertParameters(result);
        if (result.hasErrors) {
          return result;
        }
      }
      final resultCompleter = Completer<Result<T>>();
      final receive = (dynamic message) {
        if (evaluateResponse != null) {
          result.data = evaluateResponse(message);
        } else {
          result.data = message as T;
        }
        resultCompleter.complete(result);
      };
      final createArguments = () {
        final map = arguments?.call() ?? {};
        map[ChannelConstants.parameterFuncName] = channelMethodName;
        map[ChannelConstants.parameterIsAsync] = useIsolate;
        return map;
      };
      if (useIsolate) {
        final isolateName = '$channelMethodName${DateTime.now().microsecondsSinceEpoch}';
        isolates.spawn(_callChannelMethod, name: isolateName,
            // Executed every time data is received from the spawned isolate.
            onReceive: (message) {
          if (message is Map<String, dynamic> && message['isError']) {
            result.errors.add(ResultError.fromMap(message));
            resultCompleter.complete(result);
          } else {
            receive(message);
          }
          isolates.kill(isolateName, priority: Isolate.immediate);
        },
            // Executed once when spawned isolate is ready for communication.
            onInitialized: () {
          isolates.send(
            createArguments(),
            to: isolateName,
          );
        });
      } else {
        var rawData = await channel.invokeMethod(
          channelMethodName,
          createArguments(),
        );
        receive(rawData);
      }
      return resultCompleter.future;
    } catch (e) {
      _parsePlatformExceptionAndUpdateResult<T>(e as Exception?, result);
    }

    return result;
  }

  // Isolate entry point must be static or top-level.
  static Future<void> _callChannelMethod(Map<String, dynamic> context) async {
    final messenger = HandledIsolate.initialize(context);
    messenger.listen((message) async {
      try {
        var rawData = await channel.invokeMethod(
          message[ChannelConstants.parameterFuncName],
          message,
        );
        messenger.send(rawData);
      } catch (e) {
        final error = _parsePlatformException(e as Exception?);
        messenger.send(error.toMap());
      }
    });
  }

  void _parsePlatformExceptionAndUpdateResult<T>(Exception? exception, Result<T> result) {
    result.errors.add(_parsePlatformException(exception));
  }

  static ResultError _parsePlatformException(Exception? exception) {
    if (exception == null) {
      return ResultError(
        ErrorCodes.unknown,
        ErrorMessages.unknownDeviceIssue,
      );
    }

    print(exception);

    if (exception is PlatformException) {
      return ResultError(
        ErrorCodes.platformSpecific,
        sprintf(ErrorMessages.unknownDeviceExceptionTemplate, [exception.code, exception.message]),
      );
    } else {
      return ResultError(
        ErrorCodes.generic,
        sprintf(ErrorMessages.unknownDeviceGenericExceptionTemplate, [exception.toString()]),
      );
    }
  }

  void _assertParameter<T>(
    Result<T> result,
    bool predicate,
    int errorCode,
    String errorMessage,
  ) {
    if (!predicate) {
      result.errors.add(
        ResultError(errorCode, errorMessage),
      );
    }
  }

  void _validateCalendarIdParameter<T>(
    Result<T> result,
    String? calendarId,
  ) {
    _assertParameter(
      result,
      calendarId?.isNotEmpty ?? false,
      ErrorCodes.invalidArguments,
      ErrorMessages.invalidMissingCalendarId,
    );
  }

  void _validateCalendarIdsParameter<T>(
    Result<T> result,
    List<String>? calendarIds,
  ) {
    _assertParameter(
      result,
      (calendarIds?.isNotEmpty ?? true) &&
          calendarIds?.where((element) => element.isNotEmpty).length == calendarIds?.length,
      ErrorCodes.invalidArguments,
      ErrorMessages.invalidMissingCalendarId,
    );
  }
}

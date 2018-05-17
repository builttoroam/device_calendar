import 'dart:async';

import 'package:flutter/services.dart';

import '../common/constants.dart';
import '../models/calendar.dart';

const MethodChannel _calendarsChannel =
    const MethodChannel('${Constants.channelsNamePrefix}/calendars');

/// A singleton service providing functionality to work with device calendar(s)
class CalendarsService {
  static final CalendarsService _instance =
      new CalendarsService._createInstance();

  factory CalendarsService() {
    return _instance;
  }

  CalendarsService._createInstance() {
    // initialization logic here
  }

  /// Retrieves all of the device defined calendars
  Future<List<Calendar>> retrieveCalendars() async {
    try {
      var calendarsJson = await _calendarsChannel.invokeMethod('retrieve');
      return _parseCalendars(calendarsJson);
    } catch (e) {
      print(e);
    }

    return new List<Calendar>();
  }
}

List<Calendar> _parseCalendars(List<dynamic> calendarsJson) {
  final List<Calendar> calendars = new List<Calendar>();
  for (var item in calendarsJson) {
    calendars.add(new Calendar("1", name: item));
  }

  return calendars;
}

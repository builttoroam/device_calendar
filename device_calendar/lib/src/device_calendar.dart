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
}

part of device_calendar;
/// A singleton service providing functionality to work with device calendar(s)
class DeviceCalendarPlugin {
  static const MethodChannel channel = const MethodChannel('plugins.builttoroam.com/device_calendar');

  static final DeviceCalendarPlugin _instance =
      new DeviceCalendarPlugin._createInstance();

  factory DeviceCalendarPlugin() {
    return _instance;
  }

  DeviceCalendarPlugin._createInstance() {
  }

  /// Retrieves all of the device defined calendars
  Future<List<Calendar>> retrieveCalendars() async {
    try {
      var calendarsJson =
          await channel.invokeMethod('retrieveCalendars');
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

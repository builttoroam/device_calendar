part of device_calendar;

/// Device calendar abstraction
class Calendar {
  /// Platform-specific unique calendar identifier
  String id;

  /// Calendar display name
  String name;

  Calendar(this.id, {this.name});
}

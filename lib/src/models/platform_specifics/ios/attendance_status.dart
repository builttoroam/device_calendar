/// Note: [DeviceCalendarPlugin.updateAttendeeStatus] can only write this
/// back for the current signed-in user's own participant -- `EventKit` has
/// no public API to set another attendee's status.
enum IosAttendanceStatus {
  Unknown,
  Pending,
  Accepted,
  Declined,
  Tentative,
  Delegated,
  Completed,
  InProcess,
}

extension IosAttendanceStatusExtensions on IosAttendanceStatus {
  String _enumToString(IosAttendanceStatus enumValue) {
    return enumValue.toString().split('.').last;
  }

  String get enumToString => _enumToString(this);
}

part of device_calendar;

class RetrieveEventsParams {
  final List<String> eventIds;
  final DateTime startDate;
  final DateTime endDate;

  const RetrieveEventsParams({this.eventIds, this.startDate, this.endDate});
}

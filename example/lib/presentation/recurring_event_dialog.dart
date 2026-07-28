import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';

class RecurringEventDialog extends StatefulWidget {
  final DeviceCalendarPlugin _deviceCalendarPlugin;
  final Event _calendarEvent;

  final VoidCallback _onLoadingStarted;
  final Function(bool) _onDeleteFinished;

  const RecurringEventDialog(this._deviceCalendarPlugin, this._calendarEvent,
      this._onLoadingStarted, this._onDeleteFinished,
      {super.key});

  @override
  State<RecurringEventDialog> createState() => _RecurringEventDialogState();
}

class _RecurringEventDialogState extends State<RecurringEventDialog> {
  late final DeviceCalendarPlugin _deviceCalendarPlugin;
  late final Event _calendarEvent;
  VoidCallback? _onLoadingStarted;
  Function(bool)? _onDeleteFinished;

  @override
  void initState() {
    super.initState();
    _deviceCalendarPlugin = widget._deviceCalendarPlugin;
    _calendarEvent = widget._calendarEvent;
    _onLoadingStarted = widget._onLoadingStarted;
    _onDeleteFinished = widget._onDeleteFinished;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Are you sure you want to delete this event?'),
      children: <Widget>[
        SimpleDialogOption(
          onPressed: () async {
            Navigator.of(context).pop(true);
            if (_onLoadingStarted != null) _onLoadingStarted!();
            final deleteResult =
                await _deviceCalendarPlugin.deleteEventInstance(
                    _calendarEvent.calendarId,
                    _calendarEvent.eventId,
                    _calendarEvent.start?.millisecondsSinceEpoch,
                    _calendarEvent.end?.millisecondsSinceEpoch,
                    false);
            if (_onDeleteFinished != null) {
              _onDeleteFinished!(
                  deleteResult.isSuccess && deleteResult.data != null);
            }
          },
          child: const Text('This instance only'),
        ),
        SimpleDialogOption(
          onPressed: () async {
            Navigator.of(context).pop(true);
            if (_onLoadingStarted != null) _onLoadingStarted!();
            final deleteResult =
                await _deviceCalendarPlugin.deleteEventInstance(
                    _calendarEvent.calendarId,
                    _calendarEvent.eventId,
                    _calendarEvent.start?.millisecondsSinceEpoch,
                    _calendarEvent.end?.millisecondsSinceEpoch,
                    true);
            if (_onDeleteFinished != null) {
              _onDeleteFinished!(
                  deleteResult.isSuccess && deleteResult.data != null);
            }
          },
          child: const Text('This and following instances'),
        ),
        SimpleDialogOption(
          onPressed: () async {
            Navigator.of(context).pop(true);
            if (_onLoadingStarted != null) _onLoadingStarted!();
            final deleteResult = await _deviceCalendarPlugin.deleteEvent(
                _calendarEvent.calendarId, _calendarEvent.eventId);
            if (_onDeleteFinished != null) {
              _onDeleteFinished!(
                  deleteResult.isSuccess && deleteResult.data != null);
            }
          },
          child: const Text('All instances'),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        )
      ],
    );
  }
}

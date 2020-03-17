import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';

class RecurringEventDialog extends StatefulWidget {
  final DeviceCalendarPlugin _deviceCalendarPlugin;
  final Event _calendarEvent;

  final VoidCallback _onLoadingStarted;
  final Function(bool) _onDeleteFinished;
  final bool _isDelete;

  RecurringEventDialog(
    this._deviceCalendarPlugin,
    this._calendarEvent,
    this._isDelete,
    this._onLoadingStarted,
    this._onDeleteFinished,
    {Key key}) : super(key: key);

  _RecurringEventDialogState createState() =>
  _RecurringEventDialogState(_deviceCalendarPlugin, _calendarEvent, _isDelete, onLoadingStarted: _onLoadingStarted, onDeleteFinished: _onDeleteFinished);
}

class _RecurringEventDialogState extends State<RecurringEventDialog> {
  DeviceCalendarPlugin _deviceCalendarPlugin;
  Event _calendarEvent;
  VoidCallback _onLoadingStarted;
  Function(bool) _onDeleteFinished;
  bool _isDelete;

  _RecurringEventDialogState(DeviceCalendarPlugin deviceCalendarPlugin, Event calendarEvent, bool isDelete, {VoidCallback onLoadingStarted, Function(bool) onDeleteFinished}) {
    _deviceCalendarPlugin = deviceCalendarPlugin;
    _calendarEvent = calendarEvent;
    _onLoadingStarted = onLoadingStarted;
    _onDeleteFinished = onDeleteFinished;
    _isDelete = isDelete;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
        title: Text(_isDelete
          ? 'Are you sure you want to delete this event?'
          : 'Update recurring event'),
        children: <Widget>[
          SimpleDialogOption(
            child: Text('This instance only'),
            onPressed: () async {
              if (_isDelete) {
                Navigator.of(context).pop(true);
                _onLoadingStarted();
                final deleteResult = await _deviceCalendarPlugin.deleteEventInstance(
                  _calendarEvent.calendarId,
                  _calendarEvent.eventId,
                  _calendarEvent.start.millisecondsSinceEpoch,
                  _calendarEvent.end.millisecondsSinceEpoch,
                  false);
                _onDeleteFinished(deleteResult.isSuccess && deleteResult.data);
              }
              else {
                final updateResult = await _deviceCalendarPlugin.updateEventInstance(
                  _calendarEvent.calendarId,
                  _calendarEvent,
                  false);
                Navigator.of(context).pop(updateResult);
              }
            },
          ),
          SimpleDialogOption(
            child: Text('This and following instances'),
            onPressed: () async {
              if (_isDelete) {
                Navigator.of(context).pop(true);
                _onLoadingStarted();
                final deleteResult = await _deviceCalendarPlugin.deleteEventInstance(
                  _calendarEvent.calendarId,
                  _calendarEvent.eventId,
                  _calendarEvent.start.millisecondsSinceEpoch,
                  _calendarEvent.end.millisecondsSinceEpoch,
                  true);
                _onDeleteFinished(deleteResult.isSuccess && deleteResult.data);
              }
              else {
                final updateResult = await _deviceCalendarPlugin.updateEventInstance(
                  _calendarEvent.calendarId,
                  _calendarEvent,
                  true);
                Navigator.of(context).pop(updateResult);
              }
            },
          ),
          SimpleDialogOption(
            child: Text('All instances'),
            onPressed: () async {
              if (_isDelete) {
                Navigator.of(context).pop(true);
                _onLoadingStarted();
                final deleteResult = await _deviceCalendarPlugin.deleteEvent(_calendarEvent.calendarId, _calendarEvent.eventId);
                _onDeleteFinished(deleteResult.isSuccess && deleteResult.data);
              }
              else {
                final updateResult = await _deviceCalendarPlugin.createOrUpdateEvent(_calendarEvent);
                Navigator.of(context).pop(updateResult);
              }
            },
          ),
          SimpleDialogOption(
            child: Text('Cancel'),
            onPressed: () { Navigator.of(context).pop(); },
          )
        ],
      );
  }
}

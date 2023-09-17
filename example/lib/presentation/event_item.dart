import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import 'recurring_event_dialog.dart';

class EventItem extends StatefulWidget {
  final Event? _calendarEvent;
  final DeviceCalendarPlugin _deviceCalendarPlugin;
  final bool _isReadOnly;

  final Function(Event) _onTapped;
  final VoidCallback _onLoadingStarted;
  final Function(bool) _onDeleteFinished;

  const EventItem(
      this._calendarEvent,
      this._deviceCalendarPlugin,
      this._onLoadingStarted,
      this._onDeleteFinished,
      this._onTapped,
      this._isReadOnly,
      {Key? key})
      : super(key: key);

  @override
  State<EventItem> createState() {
    return _EventItemState();
  }
}

class _EventItemState extends State<EventItem> {
  final double _eventFieldNameWidth = 75.0;
  Location? _currentLocation;

  @override
  void initState() {
    super.initState();
    setCurentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget._calendarEvent != null) {
          widget._onTapped(widget._calendarEvent as Event);
        }
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: FlutterLogo(),
            ),
            ListTile(
                title: Text(widget._calendarEvent?.title ?? ''),
                subtitle: Text(widget._calendarEvent?.description ?? '')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  if (_currentLocation != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          SizedBox(
                            width: _eventFieldNameWidth,
                            child: const Text('Starts'),
                          ),
                          Text(
                            widget._calendarEvent == null
                                ? ''
                                : _formatDateTime(
                                    dateTime: widget._calendarEvent!.start!,
                                  ),
                          )
                        ],
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.0),
                  ),
                  if (_currentLocation != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        children: [
                          SizedBox(
                            width: _eventFieldNameWidth,
                            child: const Text('Ends'),
                          ),
                          Text(
                            widget._calendarEvent?.end == null
                                ? ''
                                : _formatDateTime(
                                    dateTime: widget._calendarEvent!.end!,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _eventFieldNameWidth,
                          child: const Text('All day?'),
                        ),
                        Text(widget._calendarEvent?.allDay != null &&
                                widget._calendarEvent?.allDay == true
                            ? 'Yes'
                            : 'No')
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _eventFieldNameWidth,
                          child: const Text('Location'),
                        ),
                        Expanded(
                          child: Text(
                            widget._calendarEvent?.location ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _eventFieldNameWidth,
                          child: const Text('URL'),
                        ),
                        Expanded(
                          child: Text(
                            widget._calendarEvent?.url?.data?.contentText ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _eventFieldNameWidth,
                          child: const Text('Attendees'),
                        ),
                        Expanded(
                          child: Text(
                            widget._calendarEvent?.attendees
                                    ?.where((a) => a?.name?.isNotEmpty ?? false)
                                    .map((a) => a?.name)
                                    .join(', ') ??
                                '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _eventFieldNameWidth,
                          child: const Text('Availability'),
                        ),
                        Expanded(
                          child: Text(
                            widget._calendarEvent?.availability.enumToString ??
                                '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _eventFieldNameWidth,
                          child: const Text('Status'),
                        ),
                        Expanded(
                          child: Text(
                            widget._calendarEvent?.status?.enumToString ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ButtonBar(
              children: [
                if (!widget._isReadOnly) ...[
                  IconButton(
                    onPressed: () {
                      if (widget._calendarEvent != null) {
                        widget._onTapped(widget._calendarEvent as Event);
                      }
                    },
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          if (widget._calendarEvent?.recurrenceRule == null) {
                            return AlertDialog(
                              title: const Text(
                                  'Are you sure you want to delete this event?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    widget._onLoadingStarted();
                                    final deleteResult = await widget
                                        ._deviceCalendarPlugin
                                        .deleteEvent(
                                            widget._calendarEvent?.calendarId,
                                            widget._calendarEvent?.eventId);
                                    widget._onDeleteFinished(
                                        deleteResult.isSuccess &&
                                            deleteResult.data != null);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          } else {
                            if (widget._calendarEvent == null) {
                              return const SizedBox();
                            }
                            return RecurringEventDialog(
                                widget._deviceCalendarPlugin,
                                widget._calendarEvent!,
                                widget._onLoadingStarted,
                                widget._onDeleteFinished);
                          }
                        },
                      );
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ] else ...[
                  IconButton(
                    onPressed: () {
                      if (widget._calendarEvent != null) {
                        widget._onTapped(widget._calendarEvent!);
                      }
                    },
                    icon: const Icon(Icons.remove_red_eye),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  void setCurentLocation() async {
    String? timezone;
    try {
      timezone = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      print('Could not get the local timezone');
    }
    timezone ??= 'Etc/UTC';
    _currentLocation = timeZoneDatabase.locations[timezone];
    setState(() {});
  }

  /// Formats [dateTime] into a human-readable string.
  /// If [_calendarEvent] is an Android allDay event, then the output will
  /// omit the time.
  String _formatDateTime({DateTime? dateTime}) {
    if (dateTime == null) {
      return 'Error';
    }
    var output = '';
    if (Platform.isAndroid && widget._calendarEvent?.allDay == true) {
      // just the dates, no times
      output = DateFormat.yMd().format(dateTime);
    } else {
      output = DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(TZDateTime.from(dateTime, _currentLocation!));
    }
    return output;
  }
}

import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:device_calendar_example/presentation/pages/calendar_add.dart';
import 'package:device_calendar_example/presentation/color_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

import 'calendar_events.dart';

class CalendarsPage extends StatefulWidget {
  const CalendarsPage({Key? key}) : super(key: key);

  @override
  _CalendarsPageState createState() {
    return _CalendarsPageState();
  }
}

class _CalendarsPageState extends State<CalendarsPage> {
  late DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Calendar> _calendars = [];

  List<Calendar> get _writableCalendars =>
      _calendars.where((c) => c.isReadOnly == false).toList();

  List<Calendar> get _readOnlyCalendars =>
      _calendars.where((c) => c.isReadOnly == true).toList();

  _CalendarsPageState() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  @override
  void initState() {
    super.initState();
    _retrieveCalendars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendars'),
        actions: [_getRefreshButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'WARNING: some aspects of saving events are hardcoded in this example app. As such we recommend you do not modify existing events as this may result in loss of information',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _calendars.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  key: Key(_calendars[index].isReadOnly == true
                      ? 'readOnlyCalendar${_readOnlyCalendars.indexWhere((c) => c.id == _calendars[index].id)} color:${_calendars[index].color}'
                      : 'writableCalendar${_writableCalendars.indexWhere((c) => c.id == _calendars[index].id)} color:${_calendars[index].color}'),
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (BuildContext context) {
                          return CalendarEventsPage(_calendars[index],
                              key: const Key('calendarEventsPage'));
                        }));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${_calendars[index]
                                        .id}: ${_calendars[index].name!}",
                                    style:
                                    Theme
                                        .of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  Text(
                                      "Account: ${_calendars[index]
                                          .accountName!}"),
                                  Text(
                                      "type: ${_calendars[index].accountType}"),
                                ])),
                        GestureDetector(
                          onTap: () async {
                            final calendar = _calendars[index];
                            final googleCalendarColors = await _deviceCalendarPlugin
                                .retrieveCalendarColors(_calendars[index]);
                            final colors = googleCalendarColors.isNotEmpty
                                ? googleCalendarColors.map((calendarColor) =>
                                Color(calendarColor.color)).toList()
                                : [
                              Colors.red,
                              Colors.green,
                              Colors.blue,
                              Colors.yellow,
                              Colors.orange,
                              Colors.purple,
                              Colors.cyan,
                              Colors.pink,
                              Colors.brown,
                              Colors.grey,
                            ];
                            final color = await ColorPickerDialog
                                .selectColorDialog(colors, context);
                            if (color != null) {
                              final success = await _deviceCalendarPlugin
                                  .updateCalendarColor(calendar,
                                  calendarColor: googleCalendarColors
                                      .firstWhereOrNull((calendarColor) =>
                                  calendarColor.color == color.value),
                                  color: color);
                              if (success) {
                                _retrieveCalendars();
                              }
                            }
                          },
                          child: Container(
                            key: ValueKey(_calendars[index].color),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 10),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(_calendars[index].color!)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_calendars[index].isDefault!)
                          Container(
                            margin: const EdgeInsets.fromLTRB(0, 0, 5.0, 0),
                            padding: const EdgeInsets.all(3.0),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueAccent)),
                            child: const Text('Default'),
                          ),
                        Icon(_calendars[index].isReadOnly == true
                            ? Icons.lock
                            : Icons.lock_open)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final createCalendar = await Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
                return const CalendarAddPage();
              }));

          if (createCalendar == true) {
            _retrieveCalendars();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _retrieveCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess &&
          (permissionsGranted.data == null ||
              permissionsGranted.data == false)) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess ||
            permissionsGranted.data == null ||
            permissionsGranted.data == false) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      setState(() {
        _calendars = calendarsResult.data as List<Calendar>;
      });
    } on PlatformException catch (e, s) {
      debugPrint('RETRIEVE_CALENDARS: $e, $s');
    }
  }

  Widget _getRefreshButton() {
    return IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () async {
          _retrieveCalendars();
        });
  }
}
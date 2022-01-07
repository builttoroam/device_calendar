import 'dart:io';

import 'package:device_calendar_example/common/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';

late DeviceCalendarPlugin _deviceCalendarPlugin;

class EventAttendeePage extends StatefulWidget {
  final Attendee? attendee;
  final String? eventId;
  const EventAttendeePage({Key? key, this.attendee, this.eventId})
      : super(key: key);

  @override
  _EventAttendeePageState createState() =>
      _EventAttendeePageState(attendee, eventId);
}

class _EventAttendeePageState extends State<EventAttendeePage> {
  Attendee? _attendee;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailAddressController = TextEditingController();
  var _role = AttendeeRole.None;
  var _status = AndroidAttendanceStatus.None;
  String _eventId = '';

  _EventAttendeePageState(Attendee? attendee, eventId) {
    if (attendee != null) {
      _attendee = attendee;
      _nameController.text = _attendee!.name!;
      _emailAddressController.text = _attendee!.emailAddress!;
      _role = _attendee!.role!;
      _status = _attendee!.androidAttendeeDetails?.attendanceStatus ??
          AndroidAttendanceStatus.None;
    }
    _eventId = eventId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_attendee != null
            ? 'Edit attendee ${_attendee!.name}'
            : 'Add an Attendee'),
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextFormField(
                    controller: _nameController,
                    validator: (value) {
                      if (_attendee!.isCurrentUser == false &&
                          (value == null || value.isEmpty)) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextFormField(
                    controller: _emailAddressController,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    decoration:
                        const InputDecoration(labelText: 'Email Address'),
                  ),
                ),
                ListTile(
                  leading: Text('Role'),
                  trailing: DropdownButton<AttendeeRole>(
                    onChanged: (value) {
                      setState(() {
                        _role = value as AttendeeRole;
                      });
                    },
                    value: _role,
                    items: AttendeeRole.values
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.enumToString),
                            ))
                        .toList(),
                  ),
                ),
                Visibility(
                  visible: Platform.isIOS,
                  child: ListTile(
                    onTap: () async {
                      _deviceCalendarPlugin = DeviceCalendarPlugin();

                      var result = await _deviceCalendarPlugin
                          .showiOSEventModal(_eventId);
                      Navigator.popUntil(
                          context, ModalRoute.withName(AppRoutes.calendars));
                      //TODO: finish calling and getting attendee details from iOS
                    },
                    leading: Icon(Icons.edit),
                    title: Text('View / edit iOS attendance details'),
                  ),
                ),
                Visibility(
                  visible: Platform.isAndroid,
                  child: ListTile(
                    leading: Text('Android attendee status'),
                    trailing: DropdownButton<AndroidAttendanceStatus>(
                      onChanged: (value) {
                        setState(() {
                          _status = value as AndroidAttendanceStatus;
                        });
                      },
                      value: _status,
                      items: AndroidAttendanceStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.enumToString),
                              ))
                          .toList(),
                    ),
                  ),
                )
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _attendee = Attendee(
                      name: _nameController.text,
                      emailAddress: _emailAddressController.text,
                      role: _role,
                      isOrganiser: _attendee!.isOrganiser,
                      isCurrentUser: _attendee!.isCurrentUser,
                      iosAttendeeDetails: _attendee!.iosAttendeeDetails,
                      androidAttendeeDetails: AndroidAttendeeDetails.fromJson(
                          {'attendanceStatus': _status.index}));

                  _emailAddressController.clear();
                });

                Navigator.pop(context, _attendee);
              }
            },
            child: Text(_attendee != null ? 'Update' : 'Add'),
          )
        ],
      ),
    );
  }
}

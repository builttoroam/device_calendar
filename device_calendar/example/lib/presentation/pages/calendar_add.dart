import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

class CalendarAddPage extends StatefulWidget {
  @override
  _CalendarAddPageState createState() {
    return _CalendarAddPageState();
  }
}

class _CalendarAddPageState extends State<CalendarAddPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DeviceCalendarPlugin _deviceCalendarPlugin;

  bool _autovalidate = false;
  String _calendarName = '';
  String _localAccountName = '';

  _CalendarAddPageState() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Create Calendar'),
      ),
      body: Form(
        autovalidate: _autovalidate,
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Calendar Name',
                  hintText: 'My New Calendar',
                ),
                validator: _validateCalendarName,
                onSaved: (String value) => _calendarName = value,
              ),
              if (Platform.isAndroid) ...[
                SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Local Account Name',
                    hintText: 'Device Calendar',
                  ),
                  onSaved: (String value) => _localAccountName = value,
                ),
              ]
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () async {
          final FormState form = _formKey.currentState;
          if (!form.validate()) {
            _autovalidate = true; // Start validating on every change.
            showInSnackBar('Please fix the errors in red before submitting.');
          } else {
            form.save();
            var result = await _deviceCalendarPlugin.createCalendar(
              _calendarName,
              localAccountName: _localAccountName,
            );

            if (result.isSuccess) {
              Navigator.pop(context, true);
            } else {
              showInSnackBar(result.errorMessages.join(' | '));
            }
          }
        },
      ),
    );
  }

  String _validateCalendarName(String value) {
    if (value.isEmpty) {
      return 'Calendar name is required.';
    }

    return null;
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(value)));
  }
}

import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';

class EventAttendeesPage extends StatefulWidget {
  const EventAttendeesPage({Key key}) : super(key: key);

  @override
  _EventAttendeesPageState createState() =>
      _EventAttendeesPageState();
}

class _EventAttendeesPageState extends State<EventAttendeesPage> {
  Attendee _attendee;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailAddressController = TextEditingController();
  var _attendeeType = AttendeeType.None;

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
        title: Text('Add an Attendee'),
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
                        if (value == null || value.isEmpty) return 'Please enter a name';
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
                        if (value == null || value.isEmpty || !value.contains('@')) return 'Please enter a valid email address';
                        return null;
                      },
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                ),
                ListTile(
                  leading: Text('Role'),
                  trailing: DropdownButton<AttendeeType>(
                    onChanged: (value) { setState(() { _attendeeType = value; }); },
                    value: _attendeeType,
                    items: AttendeeType.values
                      .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.enumToString),
                      ))
                      .toList(),
                  ),
                ),
              ])
          ),
          RaisedButton(
            child: Text('Add'),
            onPressed: () {
              if (_formKey.currentState.validate()) {
                setState(() {
                  _attendee = Attendee(
                      name: _nameController.text,
                      emailAddress: _emailAddressController.text,
                      attendeeType: _attendeeType
                    );

                  _emailAddressController.clear();
                });

                Navigator.pop(context, _attendee);
              }
            },
          )
        ],
      ),
    );
  }
}

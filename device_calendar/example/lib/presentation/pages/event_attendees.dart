import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';

class EventAttendees extends StatefulWidget {
  final List<Attendee> _attendees;
  const EventAttendees(this._attendees, {Key key}) : super(key: key);

  @override
  _EventAttendeesState createState() =>
      _EventAttendeesState(_attendees ?? List<Attendee>());
}

class _EventAttendeesState extends State<EventAttendees> {
  List<Attendee> _attendees;
  final _formKey = GlobalKey<FormState>();
  final _emailAddressController = TextEditingController();

  _EventAttendeesState(List<Attendee> attendees) {
    _attendees = List<Attendee>()..addAll(attendees);
  }

  @override
  void dispose() {
    _emailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendees'),
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailAddressController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email address';
                        }
                        return null;
                      },
                      decoration:
                          const InputDecoration(labelText: 'Email address'),
                    ),
                  ),
                  RaisedButton(
                    child: Text('Add'),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        setState(() {
                          _attendees.add(Attendee(
                              emailAddress: _emailAddressController.text));
                          _emailAddressController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _attendees.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${_attendees[index].emailAddress}'),
                  trailing: RaisedButton(
                    onPressed: () {
                      setState(() {
                        _attendees.removeWhere((a) =>
                            a.emailAddress == _attendees[index].emailAddress);
                      });
                    },
                    child: Text('Delete'),
                  ),
                );
              },
            ),
          ),
          RaisedButton(
            onPressed: () {
              Navigator.pop(context, _attendees);
            },
            child: Text('Done'),
          )
        ],
      ),
    );
  }
}

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

class EventItem extends StatelessWidget {
  final Calendar _calendar;
  final Event _calendarEvent;
  final DeviceCalendarPlugin _deviceCalendarPlugin;

  final Function _onLoadingStarted;
  final Function(bool) _onDeleteFinished;

  EventItem(this._calendar, this._calendarEvent, this._deviceCalendarPlugin,
      this._onLoadingStarted, this._onDeleteFinished);

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Column(
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: new FlutterLogo(),
          ),
          new ListTile(
            title: new Text(_calendarEvent.title),
          ),
          new ButtonTheme.bar(
              child: new ButtonBar(
            children: <Widget>[
              new IconButton(
                onPressed: () {},
                icon: new Icon(Icons.edit),
              ),
              new IconButton(
                onPressed: () async {
                  await showDialog<Null>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return new AlertDialog(
                          title: new Text(
                              'Are you sure you want to delete this event?'),
                          actions: <Widget>[
                            new FlatButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: new Text('Cancel'),
                            ),
                            new FlatButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                _onLoadingStarted();
                                final deleteSucceeded =
                                    await _deviceCalendarPlugin.deleteEvent(
                                        _calendar, _calendarEvent);
                                _onDeleteFinished(deleteSucceeded);
                              },
                              child: new Text('Ok'),
                            ),
                          ],
                        );
                      });
                },
                icon: new Icon(Icons.delete),
              ),
            ],
          ))
        ],
      ),
    );
  }
}

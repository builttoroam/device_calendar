import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventItem extends StatelessWidget {
  final Calendar _calendar;
  final Event _calendarEvent;
  final DeviceCalendarPlugin _deviceCalendarPlugin;

  final Function(Event) _onTapped;
  final VoidCallback _onLoadingStarted;
  final Function(bool) _onDeleteFinished;

  EventItem(this._calendar, this._calendarEvent, this._deviceCalendarPlugin,
      this._onLoadingStarted, this._onDeleteFinished, this._onTapped);

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        _onTapped(_calendarEvent);
      },
      child: new Card(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: new FlutterLogo(),
            ),
            new ListTile(
                title: new Text(_calendarEvent.title),
                subtitle: new Text(_calendarEvent.description)),
            new Container(
              padding: new EdgeInsets.symmetric(horizontal: 16.0),
              child: new Column(
                children: <Widget>[
                  new Align(
                    alignment: Alignment.topLeft,
                    child: new Row(
                      children: <Widget>[
                        new Container(
                          width: 50.0,
                          child: new Text('Starts'),
                        ),
                        new Text(new DateFormat.yMd()
                            .add_jm()
                            .format(_calendarEvent.start)),
                      ],
                    ),
                  ),
                  new Padding(
                    padding: new EdgeInsets.symmetric(vertical: 5.0),
                  ),
                  new Align(
                    alignment: Alignment.topLeft,
                    child: new Row(
                      children: <Widget>[
                        new Container(
                          width: 50.0,
                          child: new Text('Ends'),
                        ),
                        new Text(new DateFormat.yMd()
                            .add_jm()
                            .format(_calendarEvent.end)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            new ButtonTheme.bar(
                child: new ButtonBar(
              children: <Widget>[
                new IconButton(
                  onPressed: () {
                    _onTapped(_calendarEvent);
                  },
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
      ),
    );
  }
}

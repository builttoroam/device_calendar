# Device Calendar Plugin

[![pub package](https://img.shields.io/pub/v/device_calendar.svg)](https://pub.dartlang.org/packages/device_calendar) [![Build Status](https://travis-ci.org/builttoroam/FlutterDeviceCalendar.svg?branch=develop)](https://travis-ci.org/builttoroam/FlutterDeviceCalendar)

A cross platform plugin for modifying calendars on the user's device. 

## Features
* Ability to request permissions to modify calendars on the user's device
* Ability to check if permissions to modify the calendars on the user's device have been granted
* Retrieve calendars on the user's device
* Retrieve events associated with a calendar
* Ability to add, update or delete events from a calendar

## Android Integration

The following will need to be added to the manifest file for your application to indicate permissions to modify calendars a needed

```xml
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

## iOS Integration

For iOS 10 support, you'll need to modify the Info.plist to add the following key/value pair

```xml
<key>NSCalendarsUsageDescription</key>
<string>INSERT_REASON_HERE</string>
```

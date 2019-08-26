# Device Calendar Plugin

[![pub package](https://img.shields.io/pub/v/device_calendar.svg)](https://pub.dartlang.org/packages/device_calendar) [![Build Status](https://travis-ci.org/builttoroam/flutter_plugins.svg)](https://travis-ci.org/builttoroam/flutter_plugins)

A cross platform plugin for modifying calendars on the user's device. 

## Features
* Ability to request permissions to modify calendars on the user's device
* Ability to check if permissions to modify the calendars on the user's device have been granted
* Retrieve calendars on the user's device
* Retrieve events associated with a calendar
* Ability to add, update or delete events from a calendar
* Ability to set up recurring events (NOTE: deleting a recurring event will currently delete all instances of it)
* Ability to modify attendees for an event (NOTE: certain information is read-only like attendance status. Please refer to API docs)

**NOTE**: there is a known issue where it looks as though specifying `weeksOfTheYear` and `setPositions` for recurrence rules doesn't appear to have an effect. Also note that the example app only provides entering simple scenarios e.g. it may be possible to specify multiple months that a yearly event should occur on but the example app will only allow specifying a single month.

## Android Integration

The following will need to be added to the manifest file for your application to indicate permissions to modify calendars a needed

```xml
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

If you have Proguard enabled, you may need to add the following to your configuration (thanks to [Britannio Jarrett](https://github.com/britannio) who posted about it [here](https://github.com/builttoroam/flutter_plugins/issues/99))

```
-keep class com.builttoroam.devicecalendar.** { *; }
```

**IMPORTANT**: Since version 0.1.0, this version has migrated to use AndroidX instead of the deprecated Android support libraries. When using version 0.10.0 and onwards for this plugin, please ensure your application has been migrated following the guide [here](https://developer.android.com/jetpack/androidx/migrate)

## iOS Integration

For iOS 10 support, you'll need to modify the Info.plist to add the following key/value pair

```xml
<key>NSCalendarsUsageDescription</key>
<string>INSERT_REASON_HERE</string>
```

Note that on iOS, this is a Swift plugin. There is a known issue being tracked [here](https://github.com/flutter/flutter/issues/16049) by the Flutter team, where adding a plugin developed in Swift to an Objective-C project causes problems. If you run into such issues, please look at the suggested workarounds there.

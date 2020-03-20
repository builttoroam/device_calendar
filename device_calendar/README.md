# Device Calendar Plugin

[![pub package](https://img.shields.io/pub/v/device_calendar.svg)](https://pub.dartlang.org/packages/device_calendar) [![Build Status](https://dev.azure.com/builttoroam/Flutter%20Plugins/_apis/build/status/Device%20Calendar)](https://dev.azure.com/builttoroam/Flutter%20Plugins/_build/latest?definitionId=106)

A cross platform plugin for modifying calendars on the user's device.

## Features

* Ability to request permissions to modify calendars on the user's device
* Ability to check if permissions to modify the calendars on the user's device have been granted
* Ability to add or retrieve calendars on the user's device
* Retrieve events associated with a calendar
* Ability to add, update or delete events from a calendar
* Ability to set up, edit or delete recurring events
  * **NOTE**: Editing a recurring event will currently edit all instances of it
  * **NOTE**: Deleting multiple instances in **Android** takes time to update, you'll see the changes after a few seconds
* Ability to add, modify or remove attendees and receive if an attendee is an organiser for an event
* Ability to setup reminders for an event
* Ability to specify a time zone for event start and end date
  * **NOTE**: For the time zone list, please refer to the `TZ database name` column on [Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
  * **NOTE**: If the time zone values are null or invalid, it will be defaulted to the device's current time zone.

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

If you want to enable Proguard, please refer to the guide at [Android Developer](https://developer.android.com/studio/build/shrink-code) page

**IMPORTANT**: Since version 0.1.0, this version has migrated to use AndroidX instead of the deprecated Android support libraries. When using version 0.10.0 and onwards for this plugin, please ensure your application has been migrated following the guide [here](https://developer.android.com/jetpack/androidx/migrate)

## iOS Integration

For iOS 10 support, you'll need to modify the Info.plist to add the following key/value pair

```xml
<key>NSCalendarsUsageDescription</key>
<string>INSERT_REASON_HERE</string>
```

Note that on iOS, this is a Swift plugin. There is a known issue being tracked [here](https://github.com/flutter/flutter/issues/16049) by the Flutter team, where adding a plugin developed in Swift to an Objective-C project causes problems. If you run into such issues, please look at the suggested workarounds there.

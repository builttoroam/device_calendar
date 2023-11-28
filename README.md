# Device Calendar Plugin

[![pub package](https://img.shields.io/pub/v/device_calendar.svg)](https://pub.dartlang.org/packages/device_calendar) ![Pub Version (including pre-releases)](https://img.shields.io/pub/v/device_calendar?include_prereleases&label=Prerelease) [![build](https://github.com/builttoroam/device_calendar/actions/workflows/dart.yml/badge.svg?branch=develop)](https://github.com/builttoroam/device_calendar/actions/workflows/dart.yml)

A cross platform plugin for modifying calendars on the user's device.

## Breaking changes at v4

* **If you're upgrading from previous versions, your code will need to be modified (slightly), otherwise it will not run after update. See [Timezone support](https://github.com/builttoroam/device_calendar#timezone-support-with-tzdatetime) for more details.**
* **There are some changes to event JSON formats at v4. Pay extra care if you handle event JSONs. Directly calling to and from device calendars should be unaffected.**

## Features

* Request permissions to modify calendars on the user's device
* Check if permissions to modify the calendars on the user's device have been granted
* Add or retrieve calendars on the user's device
* Retrieve events associated with a calendar
* Add, update or delete events from a calendar
* Set up, edit or delete recurring events
  * **NOTE**: Editing a recurring event will currently edit all instances of it
  * **NOTE**: Deleting multiple instances in **Android** takes time to update, you'll see the changes after a few seconds
* Add, modify or remove attendees and receive if an attendee is an organiser for an event
* Setup reminders for an event
* Specify a time zone for event start and end date
  * **NOTE**: Due to a limitation of iOS API, single time zone property is used for iOS (`event.startTimeZone`)
  * **NOTE**: For the time zone list, please refer to the `TZ database name` column on [Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

## Timezone support with TZDateTime

Due to feedback we received, starting from `4.0.0` we will be using the `timezone` package to better handle all timezone data.

This is already included in this package. However, you need to add this line whenever the package is needed.

```dart
import 'package:timezone/timezone.dart';
```

If you don't need any timezone specific features in your app, you may use `flutter_native_timezone` to get your devices' current timezone, then convert your previous `DateTime` with it.

```dart
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

initializeTimeZones();

// As an example, our default timezone is UTC.
Location _currentLocation = getLocation('Etc/UTC');

Future setCurentLocation() async {
  String timezone = 'Etc/UTC';
  try {
    timezone = await FlutterNativeTimezone.getLocalTimezone();
  } catch (e) {
    print('Could not get the local timezone');
  }
  _currentLocation = getLocation(timezone);
  setLocalLocation(_currentLocation);
}

...

event.start = TZDateTime.from(oldDateTime, _currentLocation);
```

For other use cases, feedback or future developments on the feature, feel free to open a discussion on GitHub.

## Null-safety migration

From `v3.9.0`, device_calendar is null-safe. However, not all workflows have been checked and bugs from older versions still persist.

You are strongly advised to test your workflow with the new package before shipping.
Better yet, please leave a note for what works and what doesn't, or contribute some bug fixes!

## Android Integration

The following will need to be added to the `AndroidManifest.xml` file for your application to indicate permissions to modify calendars are needed

```xml
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

### Proguard / R8 exceptions
> NOTE: From v4.3.2 developers no longer need to add proguard rule in their app.


By default, all android apps go through R8 for file shrinking when building a release version. Currently, it interferes with some functions such as `retrieveCalendars()`.

You may add the following setting to the ProGuard rules file `proguard-rules.pro` (thanks to [Britannio Jarrett](https://github.com/britannio)). Read more about the issue [here](https://github.com/builttoroam/device_calendar/issues/99)

```
-keep class com.builttoroam.devicecalendar.** { *; }
```

See [here](https://github.com/builttoroam/device_calendar/issues/99#issuecomment-612449677) for an example setup.

For more information, refer to the guide at [Android Developer](https://developer.android.com/studio/build/shrink-code#keep-code)

### AndroidX migration

Since `v.1.0`, this version has migrated to use AndroidX instead of the deprecated Android support libraries. When using `0.10.0` and onwards for this plugin, please ensure your application has been migrated following the guide [here](https://developer.android.com/jetpack/androidx/migrate)

## iOS Integration

For iOS 10+ support, you'll need to modify the `Info.plist` to add the following key/value pair

```xml
<key>NSCalendarsUsageDescription</key>
<string>Access most functions for calendar viewing and editing.</string>

<key>NSContactsUsageDescription</key>
<string>Access contacts for event attendee editing.</string>
```

For iOS 17+ support, add the following key/value pair as well.

```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>Access most functions for calendar viewing and editing.</string>
```

Note that on iOS, this is a Swift plugin. There is a known issue being tracked [here](https://github.com/flutter/flutter/issues/16049) by the Flutter team, where adding a plugin developed in Swift to an Objective-C project causes problems. If you run into such issues, please look at the suggested workarounds there.
